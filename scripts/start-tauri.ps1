# Launch Tauri exe + KataGo bridge with no console window.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "background.ps1")

$candidates = @(
  (Join-Path $Root "src-tauri\target\release\svil-baduk.exe"),
  (Join-Path $Root "src-tauri\target\release\SVIL Baduk.exe"),
  (Join-Path $Root "src-tauri\target\release\app.exe")
)
$exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) { throw "Tauri exe not found. Run: npm run tauri:build" }

[void](Ensure-KataGoBridge $Root)
Start-Process -FilePath $exe -WorkingDirectory (Split-Path -Parent $exe)
