# scripts/build-installer.ps1 — Flutter 릴리스 빌드 → Inno Setup → 코드서명
#
# Tauri 의 bundle.windows.signCommand 훅에 해당하는 것을 손으로 엮는다.
# Flutter 에는 번들러도 서명 훅도 없다.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# 1) 버전은 src/version.ts 가 단일 진실
$versionTs = Get-Content (Join-Path $root 'src/version.ts') -Raw
if ($versionTs -notmatch "APP_VERSION\s*=\s*'([^']+)'") {
  throw 'src/version.ts 에서 APP_VERSION 을 찾지 못했습니다'
}
$version = $Matches[1]
Write-Host "빌드 버전: $version"

# 2) 모든 버전 파일을 맞춘다 (pubspec·version.dart 포함)
& node (Join-Path $root 'scripts/sync-version.mjs')
if ($LASTEXITCODE -ne 0) { throw '버전 동기화 실패' }

# 3) Flutter 릴리스 빌드
Push-Location (Join-Path $root 'app')
try {
  & flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw 'flutter build 실패' }
} finally {
  Pop-Location
}

# 4) 실행 파일 서명 (인증서가 있을 때만 — 없으면 조용히 건너뛴다)
$exe = Join-Path $root 'app/build/windows/x64/runner/Release/svil_baduk.exe'
& (Join-Path $root 'scripts/sign-windows.ps1') $exe

# 5) 설치본 생성
$iscc = Get-Command 'iscc.exe' -ErrorAction SilentlyContinue
if (-not $iscc) {
  $candidate = 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
  if (Test-Path $candidate) { $iscc = $candidate } else {
    throw 'Inno Setup(ISCC.exe)을 찾지 못했습니다. https://jrsoftware.org/isdl.php'
  }
}
& $iscc "/DAppVersion=$version" (Join-Path $root 'scripts/installer.iss')
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup 실패' }

# 6) 설치본도 서명한다
$setup = Join-Path $root "dist-installer/SVIL-Baduk-$version-setup.exe"
& (Join-Path $root 'scripts/sign-windows.ps1') $setup

# 7) 체크리스트 B2·B3 실측치를 찍어준다
$payload = (Get-ChildItem (Join-Path $root 'app/build/windows/x64/runner/Release') -Recurse |
  Measure-Object -Property Length -Sum).Sum / 1MB
$installer = (Get-Item $setup).Length / 1MB
Write-Host ''
Write-Host ('설치 용량 : {0:N1} MB  (기준 <= 60 MB)' -f $payload)
Write-Host ('설치 파일 : {0:N1} MB  (기준 <= 25 MB)' -f $installer)
Write-Host $setup
