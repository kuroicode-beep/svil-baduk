# Point desktop shortcut at the built Tauri exe when present; else fall back to start-app.ps1.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

$candidates = @(
  (Join-Path $Root "src-tauri\target\release\svil-baduk.exe"),
  (Join-Path $Root "src-tauri\target\release\SVIL Baduk.exe"),
  (Join-Path $Root "src-tauri\target\release\app.exe")
)
$exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

$desktop = [Environment]::GetFolderPath("Desktop")
$lnkPath = Join-Path $desktop "SVIL Baduk.lnk"
$wsh = New-Object -ComObject WScript.Shell
$lnk = $wsh.CreateShortcut($lnkPath)

if ($exe) {
  $lnk.TargetPath = $exe
  $lnk.Arguments = ""
  $lnk.WorkingDirectory = Split-Path -Parent $exe
  $lnk.Description = "SVIL Baduk — Tauri 데스크톱"
  $ico = Join-Path $Root "src-tauri\icons\icon.ico"
  if (Test-Path $ico) { $lnk.IconLocation = $ico }
  Write-Host "mode=tauri exe=$exe"
} else {
  $launcher = Join-Path $PSScriptRoot "start-app.ps1"
  if (-not (Test-Path $launcher)) { throw "Neither Tauri exe nor launcher found." }
  $lnk.TargetPath = "powershell.exe"
  $lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$launcher`""
  $lnk.WorkingDirectory = $Root
  $lnk.Description = "SVIL Baduk — preview + KataGo bridge"
  Write-Host "mode=preview (build Tauri first: npm run tauri:build)"
}

$lnk.WindowStyle = 1
$lnk.Save()
Write-Host "shortcut=$lnkPath"
