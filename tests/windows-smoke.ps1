$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ('alpine-smoke-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $source = @'
using System;
using System.IO;
public static class DockerStub {
    public static int Main(string[] args) {
        if (args.Length > 0 && args[0] == "build")
            return int.Parse(Environment.GetEnvironmentVariable("SMOKE_BUILD_EXIT"));
        if (args.Length != 8 || args[0] != "run" || args[1] != "-it" ||
            args[2] != "--rm" || args[3] != "-v" || args[5] != "-v" ||
            args[7] != "alpine-sandbox:1.0" || !args[4].EndsWith(":/logs") ||
            !args[6].EndsWith(":/work")) return 91;
        string log = args[4].Substring(0, args[4].Length - 6);
        string work = args[6].Substring(0, args[6].Length - 6);
        if (!Directory.Exists(log) || !Directory.Exists(work) ||
            Path.GetDirectoryName(log) != Path.GetDirectoryName(work)) return 92;
        File.WriteAllText(Path.Combine(log, "smoke.txt"), "run");
        return 0;
    }
}
'@
    Add-Type -TypeDefinition $source -OutputAssembly (Join-Path $temp 'docker.exe') -OutputType ConsoleApplication
    foreach ($name in @('checkout with spaces', 'checkout & metacharacter')) {
        $checkout = Join-Path $temp $name
        New-Item -ItemType Directory -Path $checkout | Out-Null
        Copy-Item (Join-Path $root 'alpine-sandbox.bat') $checkout
        Copy-Item (Join-Path $temp 'docker.exe') $checkout
        $oldPath = $env:PATH
        $env:PATH = "$checkout;$oldPath"
        $env:SMOKE_BUILD_EXIT = '0'
        Push-Location $checkout
        try {
            1..2 | ForEach-Object {
                & cmd.exe /d /c 'alpine-sandbox.bat'
                if ($LASTEXITCODE -ne 0) { throw "Sequential launch failed: $LASTEXITCODE" }
            }
            $processes = 1..4 | ForEach-Object {
                Start-Process cmd.exe -ArgumentList '/d', '/c', 'alpine-sandbox.bat' -WorkingDirectory $checkout -PassThru
            }
            $processes | ForEach-Object {
                $_.WaitForExit()
                if ($_.ExitCode -ne 0) { throw "Concurrent launch failed: $($_.ExitCode)" }
            }
            $runs = @(Get-ChildItem (Join-Path $checkout 'data') -Directory)
            if ($runs.Count -ne 6) { throw "Expected six distinct sessions, got $($runs.Count)" }
            foreach ($run in $runs) {
                if (-not (Test-Path (Join-Path $run.FullName 'logs\smoke.txt'))) { throw "Missing run: $run" }
            }
            $env:SMOKE_BUILD_EXIT = '37'
            & cmd.exe /d /c 'alpine-sandbox.bat'
            if ($LASTEXITCODE -ne 37) { throw "Build failure returned $LASTEXITCODE instead of 37" }
            if (@(Get-ChildItem (Join-Path $checkout 'data') -Recurse -Filter smoke.txt).Count -ne 6) {
                throw 'Docker run was invoked after a failed build'
            }
        } finally {
            Pop-Location
            $env:PATH = $oldPath
        }
    }
    Write-Host 'Windows smoke tests passed.'
} finally {
    Remove-Item -Recurse -Force $temp
    Remove-Item Env:SMOKE_BUILD_EXIT -ErrorAction SilentlyContinue
}
