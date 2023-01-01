# alpine-sandbox

Docker (Windows) で Alpine のサンドボックス環境を 1 コマンドで立てられるようにするやつ。  
コンテナ内で実行したコマンドやその結果は script コマンドか [asciinema](https://asciinema.org/) で記録する。

Dockerfile を作る前に検証するときとかに使えるかも。

## Installation

```powershell
git clone https://github.com/book000/alpine-sandbox
Set-Location alpine-sandbox
$oldPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$oldPath += ";" + $(Get-Location)
[System.Environment]::SetEnvironmentVariable("Path", $oldPath, "Machine")

# Command: alpine-sandbox
```
