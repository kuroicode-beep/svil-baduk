# Vite 개발 서버 + KataGo 브리지를 함께 띄웁니다.
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "SVIL Baduk — starting bridge + dev server" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$Root'; npm run katago:bridge"
npm run dev
