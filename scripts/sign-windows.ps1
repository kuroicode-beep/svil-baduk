# Authenticode sign for Tauri Windows artifacts.
# Skips when no certificate is available (unless SVIL_CODESIGN_REQUIRED=1).
#
# Certificate resolution order:
#   1) SVIL_CODESIGN_THUMBPRINT env
#   2) Cert:\CurrentUser\My subject containing "SVIL Baduk Code Signing"
#   3) Cert:\CurrentUser\My subject containing "SVIL Baduk"
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Path
)

$ErrorActionPreference = "Stop"

function Find-SignTool {
  $envTool = $env:SIGNTOOL_PATH
  if ($envTool -and (Test-Path $envTool)) { return $envTool }
  $kits = @(
    "${env:ProgramFiles(x86)}\Windows Kits\10\bin",
    "${env:ProgramFiles}\Windows Kits\10\bin"
  )
  foreach ($root in $kits) {
    if (-not (Test-Path $root)) { continue }
    $hit = Get-ChildItem -Path $root -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } |
      Sort-Object FullName -Descending |
      Select-Object -First 1
    if ($hit) { return $hit.FullName }
  }
  return $null
}

function Resolve-Thumbprint {
  if ($env:SVIL_CODESIGN_THUMBPRINT) {
    return ($env:SVIL_CODESIGN_THUMBPRINT -replace '\s', '').ToUpperInvariant()
  }
  $store = "Cert:\CurrentUser\My"
  $preferred = Get-ChildItem $store -ErrorAction SilentlyContinue |
    Where-Object { $_.HasPrivateKey -and $_.Subject -match 'SVIL Baduk Code Signing' } |
    Select-Object -First 1
  if ($preferred) { return $preferred.Thumbprint.ToUpperInvariant() }
  $fallback = Get-ChildItem $store -ErrorAction SilentlyContinue |
    Where-Object { $_.HasPrivateKey -and $_.Subject -match 'SVIL Baduk' } |
    Select-Object -First 1
  if ($fallback) { return $fallback.Thumbprint.ToUpperInvariant() }
  return $null
}

if (-not (Test-Path -LiteralPath $Path)) {
  throw "File to sign not found: $Path"
}

$thumb = Resolve-Thumbprint
$required = $env:SVIL_CODESIGN_REQUIRED -eq "1"

if (-not $thumb) {
  if ($required) {
    throw "No code signing certificate. Run scripts/setup-codesign.ps1 or set SVIL_CODESIGN_THUMBPRINT."
  }
  Write-Host "sign-windows: skip (no certificate) — $Path"
  exit 0
}

$signtool = Find-SignTool
if (-not $signtool) {
  if ($required) { throw "signtool.exe not found. Install Windows SDK." }
  Write-Host "sign-windows: skip (signtool missing) — $Path"
  exit 0
}

$timestamp = if ($env:SVIL_CODESIGN_TIMESTAMP) { $env:SVIL_CODESIGN_TIMESTAMP } else { "http://timestamp.digicert.com" }

Write-Host "sign-windows: signing $Path (thumb=$thumb)"
& $signtool sign /fd SHA256 /td SHA256 /tr $timestamp /sha1 $thumb $Path
if ($LASTEXITCODE -ne 0) {
  throw "signtool failed with exit $LASTEXITCODE for $Path"
}
Write-Host "sign-windows: ok - $Path"
