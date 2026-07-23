# SVIL Baduk 실행 — 빌드 산출물 preview + KataGo 브리지
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$dist = Join-Path $Root "dist\index.html"
if (-not (Test-Path $dist)) {
  Write-Host "dist 없음 — npm run build 실행..." -ForegroundColor Yellow
  npm run build
  if ($LASTEXITCODE -ne 0) { throw "build failed" }
}

# KataGo 브리지 (이미 떠 있으면 포트 충돌로 바로 종료되어도 무시)
$bridgeRunning = $false
try {
  $h = Invoke-RestMethod -Uri "http://127.0.0.1:17419/health" -TimeoutSec 1
  $bridgeRunning = $true
} catch { $bridgeRunning = $false }

if (-not $bridgeRunning) {
  Start-Process powershell -ArgumentList @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-Command", "Set-Location '$Root'; npm run katago:bridge"
  ) -WindowStyle Minimized
  Start-Sleep -Seconds 2
}

Write-Host "SVIL Baduk preview 시작 (브라우저 자동 오픈)" -ForegroundColor Cyan
npm run preview -- --host 127.0.0.1 --open