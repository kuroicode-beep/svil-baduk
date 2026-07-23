# SVIL Baduk launcher — preview build + KataGo bridge
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$dist = Join-Path $Root "dist\index.html"
if (-not (Test-Path $dist)) {
  Write-Host "dist missing — running npm run build..." -ForegroundColor Yellow
  npm run build
  if ($LASTEXITCODE -ne 0) { throw "build failed" }
}

$bridgeRunning = $false
try {
  $null = Invoke-RestMethod -Uri "http://127.0.0.1:17419/health" -TimeoutSec 1
  $bridgeRunning = $true
} catch { $bridgeRunning = $false }

if (-not $bridgeRunning) {
  Start-Process powershell -ArgumentList @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-Command", "Set-Location '$Root'; npm run katago:bridge"
  ) -WindowStyle Minimized
  Start-Sleep -Seconds 2
}

# If preview already up, just open browser
try {
  $null = Invoke-WebRequest -Uri "http://127.0.0.1:4173" -UseBasicParsing -TimeoutSec 1
  Start-Process "http://127.0.0.1:4173/"
  Write-Host "Opened existing preview http://127.0.0.1:4173/"
  exit 0
} catch { }

Write-Host "Starting SVIL Baduk preview..." -ForegroundColor Cyan
npm run preview -- --host 127.0.0.1 --port 4173 --open