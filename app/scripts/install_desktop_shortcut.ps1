# app/scripts/install_desktop_shortcut.ps1 — SVIL Baduk 바탕화면 바로가기
#
# 릴리스 빌드 산출물을 가리키는 .lnk 를 바탕화면에 만든다.
# 바탕화면 경로는 OneDrive 로 리다이렉트돼 있을 수 있어
# $env:USERPROFILE\Desktop 이 아니라 GetFolderPath 를 쓴다.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # 저장소 루트
$exe  = Join-Path $root 'app\build\windows\x64\runner\Release\svil_baduk.exe'

if (-not (Test-Path $exe)) {
    throw "빌드 산출물이 없습니다: $exe`n먼저 'cd app; flutter build windows --release' 를 실행하세요."
}

$version = (Get-Content (Join-Path $root 'VERSION') -Raw).Trim()

$desktop = [Environment]::GetFolderPath('Desktop')
$lnkPath = Join-Path $desktop 'SVIL Baduk.lnk'

$wsh = New-Object -ComObject WScript.Shell
$lnk = $wsh.CreateShortcut($lnkPath)
$lnk.TargetPath       = $exe
$lnk.WorkingDirectory = Split-Path $exe -Parent
$lnk.Description      = "SVIL Baduk v$version - 저시력자를 위한 고대비 바둑"
$lnk.Save()

if (-not (Test-Path $lnkPath)) { throw "바로가기 생성에 실패했습니다: $lnkPath" }

Write-Host "바로가기 생성: $lnkPath"
Write-Host "  대상: $exe"
Write-Host "  버전: $version"
