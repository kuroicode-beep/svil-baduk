# 바탕화면 바로가기 설치 (콘솔 숨김)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$launcher = Join-Path $PSScriptRoot "start-app.ps1"
if (-not (Test-Path $launcher)) { throw "Launcher missing: $launcher" }

$desktop = [Environment]::GetFolderPath("Desktop")
$lnkPath = Join-Path $desktop "SVIL Baduk.lnk"
$wsh = New-Object -ComObject WScript.Shell
$lnk = $wsh.CreateShortcut($lnkPath)
$ps = (Get-Command powershell.exe).Source
$lnk.TargetPath = $ps
$lnk.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcher`""
$lnk.WorkingDirectory = $Root
$lnk.WindowStyle = 7
$lnk.Description = "SVIL Baduk — 고대비 바둑 (AI 대국, 백그라운드 서버)"
$lnk.Save()

if (-not (Test-Path $lnkPath)) { throw "Shortcut was not created: $lnkPath" }
Write-Host "shortcut=$lnkPath"
