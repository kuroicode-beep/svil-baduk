# Vite 개발 서버 + KataGo 브리지 (브리지는 콘솔 없이 백그라운드)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
. (Join-Path $PSScriptRoot "background.ps1")

Write-Host "SVIL Baduk — bridge (background) + dev server" -ForegroundColor Cyan
[void](Ensure-KataGoBridge $Root)
npm run dev
