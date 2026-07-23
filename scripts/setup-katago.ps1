# KataGo 바이너리 + 대국용 모델 배치
# NVIDIA RTX (5060 Ti 등): CUDA Toolkit 있으면 CUDA 빌드, 없으면 OpenCL (GPU Device 사용)
# 사용: powershell -ExecutionPolicy Bypass -File scripts/setup-katago.ps1
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Kg = Join-Path $Root 'katago'
$Bin = Join-Path $Kg 'bin'
$Models = Join-Path $Kg 'models'
$Tmp = Join-Path $Kg '_tmp'

New-Item -ItemType Directory -Force -Path $Bin, $Models, $Tmp | Out-Null

$ver = 'v1.16.5'
$hasCuda = Test-Path 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA'
$asset = if ($hasCuda) {
  'katago-v1.16.5-cuda12.8-cudnn9.8.0-windows-x64.zip'
} else {
  'katago-v1.16.5-opencl-windows-x64.zip'
}

Write-Host "Downloading KataGo $ver ($asset)..." -ForegroundColor Cyan
if (-not $hasCuda) {
  Write-Host 'CUDA Toolkit not found — using OpenCL (RTX 5060 Ti still runs on GPU via OpenCL).' -ForegroundColor Yellow
  Write-Host 'Optional: install CUDA 12.8 + download CUDA KataGo build for more speed.' -ForegroundColor Yellow
}

gh release download $ver --repo lightvector/KataGo `
  --pattern $asset `
  --dir $Tmp --clobber

$zip = Get-ChildItem (Join-Path $Tmp $asset) | Select-Object -First 1
$extract = Join-Path $Tmp 'extract'
if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
Expand-Archive -Path $zip.FullName -DestinationPath $extract -Force
Copy-Item (Join-Path $extract '*') $Bin -Force
Copy-Item (Join-Path $Bin 'default_gtp.cfg') (Join-Path $Kg 'default_gtp.cfg') -Force

Write-Host 'Downloading g170e b20 network (~87MB)...' -ForegroundColor Cyan
gh release download v1.4.5 --repo lightvector/KataGo `
  --pattern 'g170e-b20c256x2-s5303129600-d1228401921.bin.gz' `
  --dir $Models --clobber

# 대국용 설정 — RTX 5060 Ti 16GB OpenCL/CUDA
$cfg = Get-Content (Join-Path $Kg 'default_gtp.cfg') -Raw
$cfg = $cfg.Replace('maxVisits = 500', "maxVisits = 64`nmaxTime = 3.0")
$cfg = $cfg.Replace('numSearchThreads = 6', 'numSearchThreads = 12')
if ($cfg -notmatch 'openclDeviceToUse\s*=') {
  $cfg = $cfg.Replace(
    '# openclDeviceToUse = 0',
    "openclDeviceToUse = 0"
  )
}
$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText((Join-Path $Kg 'gtp_play.cfg'), $cfg, $utf8)

Write-Host ''
Write-Host 'Verifying backend...' -ForegroundColor Cyan
& (Join-Path $Bin 'katago.exe') version

Write-Host ''
Write-Host 'Done. Next:' -ForegroundColor Green
Write-Host '  npm run katago:bridge'
Write-Host '  Bridge log should show: Using OpenCL Device 0: NVIDIA GeForce RTX 5060 Ti'
Write-Host '  (or CUDA backend if CUDA build installed)'
Write-Host 'Optional tune:  katago\bin\katago.exe benchmark -model <model> -config katago\gtp_play.cfg'
