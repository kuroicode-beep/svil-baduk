# SVIL Baduk launcher — preview + KataGo bridge (no visible console)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
. (Join-Path $PSScriptRoot "background.ps1")

$dist = Join-Path $Root "dist\index.html"
if (-not (Test-Path $dist)) {
  Write-Host "dist missing — running npm run build..." -ForegroundColor Yellow
  npm run build
  if ($LASTEXITCODE -ne 0) { throw "build failed" }
}

$startedBridge = Ensure-KataGoBridge $Root
if ($startedBridge) { Write-Host "KataGo bridge: background" }

if (Test-HttpOk "http://127.0.0.1:4173/") {
  Start-Process "http://127.0.0.1:4173/"
  Write-Host "Opened existing preview http://127.0.0.1:4173/"
  exit 0
}

$npmCmd = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
if ($npmCmd) {
  Start-HiddenProcess -FilePath $npmCmd -ArgumentList @(
    "run", "preview", "--", "--host", "127.0.0.1", "--port", "4173"
  ) -WorkingDirectory $Root
} else {
  $cmd = (Get-Command cmd.exe -ErrorAction Stop).Source
  Start-HiddenProcess -FilePath $cmd -ArgumentList @(
    "/c", "npm run preview -- --host 127.0.0.1 --port 4173"
  ) -WorkingDirectory $Root
}

$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline) {
  if (Test-HttpOk "http://127.0.0.1:4173/") { break }
  Start-Sleep -Milliseconds 400
}
Start-Process "http://127.0.0.1:4173/"
Write-Host "SVIL Baduk preview: background → http://127.0.0.1:4173/"
