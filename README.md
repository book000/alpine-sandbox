# alpine-sandbox

Spin up a disposable Alpine Linux sandbox in Docker on Windows with a single command.
Everything you run in the container is recorded with [asciinema](https://asciinema.org/) (default) or the `script` command, so the session can be replayed or reviewed later.

Handy for trying out commands before you write them into a Dockerfile.

## Requirements

- Windows with Docker (`docker` on the `PATH`)

## Installation

Run in an elevated PowerShell (the machine-wide `PATH` is modified):

```powershell
git clone https://github.com/book000/alpine-sandbox
Set-Location alpine-sandbox
$oldPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$oldPath += ";" + $(Get-Location)
[System.Environment]::SetEnvironmentVariable("Path", $oldPath, "Machine")
```

Open a new terminal afterwards so the updated `PATH` is picked up.

## Usage

```powershell
alpine-sandbox
```

Run it from the repository directory: the launcher builds with `docker build .`, which uses the current directory as the build context, so it fails with a missing `Dockerfile` when started from elsewhere (only the `data` directory is anchored to the script location).

The launcher does the following:

1. Creates a unique `data\<session>\work\` and `data\<session>\logs\` next to `alpine-sandbox.bat`.
2. Builds the image from `Dockerfile` as `alpine-sandbox:1.0`.
3. Runs it interactively with `--rm`, mounting `work` at `/work` (the working directory) and `logs` at `/logs`.

The recording is written to `logs\record.cast` and can be played with `asciinema play`.
The container is removed on exit; files kept under `/work` and the recording stay in the `data` directory on the host.

## Recording with the `script` command

`Dockerfile.script-cmd-ver` is an alternative image that records with the `script` command instead of asciinema.
It is not used by `alpine-sandbox.bat`, so build and run it manually:

```powershell
docker build --tag alpine-sandbox:script -f Dockerfile.script-cmd-ver .
docker run -it --rm -v <logdir>:/logs -v <workdir>:/work alpine-sandbox:script
```

It is meant to write the terminal log to `commands.log` and the timing data to `timing.log` in the logs directory.

Known issue: with the current `ENTRYPOINT`/`CMD`, this variant exits immediately with `script: unexpected number of arguments` (verified by building and running it), so it does not produce a recording yet.

## Windows smoke test

Run `powershell -ExecutionPolicy Bypass -File tests\windows-smoke.ps1` to check paths with spaces and `&`, sequential and concurrent launches, and build failure handling using a Docker stub.
