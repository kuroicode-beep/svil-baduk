# Point desktop shortcut at Tauri (+ hidden bridge) when present; else preview launcher.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

$tauriExe = @(
  (Join-Path $Root "src-tauri\target\release\svil-baduk.exe"),
  (Join-Path $Root "src-tauri\target\release\SVIL Baduk.exe")
) | Where-Object { Test-Path $_ } | Select-Object -First 1

$desktop = [Environment]::GetFolderPath("Desktop")
$lnkPath = Join-Path $desktop "SVIL Baduk.lnk"
$wsh = New-Object -ComObject WScript.Shell
$lnk = $wsh.CreateShortcut($lnkPath)

# Hidden PowerShell host so no console flashes for bridge/preview launchers
$ps = (Get-Command powershell.exe).Source

if ($tauriExe) {
  $launcher = Join-Path $PSScriptRoot "start-tauri.ps1"
  $lnk.TargetPath = $ps
  $lnk.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcher`""
  $lnk.WorkingDirectory = $Root
  $lnk.Description = "SVIL Baduk — Tauri + KataGo (background)"
  $ico = Join-Path $Root "src-tauri\icons\icon.ico"
  if (Test-Path $ico) { $lnk.IconLocation = $ico }
  Write-Host "mode=tauri+bridge-hidden exe=$tauriExe"
} else {
  $launcher = Join-Path $PSScriptRoot "start-app.ps1"
  $lnk.TargetPath = $ps
  $lnk.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcher`""
  $lnk.WorkingDirectory = $Root
  $lnk.Description = "SVIL Baduk — preview + KataGo (background)"
  Write-Host "mode=preview-hidden"
}

$lnk.WindowStyle = 7
$lnk.Save()
Write-Host "shortcut=$lnkPath"
