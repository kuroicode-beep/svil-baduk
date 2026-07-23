# Create a local self-signed Authenticode certificate for SVIL Baduk.
# SmartScreen will still warn until a purchased OV/EV cert is used.
# Import into CurrentUser\My and print the thumbprint for SVIL_CODESIGN_THUMBPRINT.
$ErrorActionPreference = "Stop"

$subject = "CN=SVIL Baduk Code Signing"
$existing = Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue |
  Where-Object { $_.Subject -eq $subject -and $_.HasPrivateKey } |
  Select-Object -First 1

if ($existing) {
  Write-Host "existing_thumbprint=$($existing.Thumbprint)"
  Write-Host "subject=$($existing.Subject)"
  Write-Host "Set SVIL_CODESIGN_THUMBPRINT=$($existing.Thumbprint) before npm run tauri:build"
  exit 0
}

$cert = New-SelfSignedCertificate `
  -Type CodeSigningCert `
  -Subject $subject `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -KeyExportPolicy Exportable `
  -KeySpec Signature `
  -HashAlgorithm SHA256 `
  -NotAfter (Get-Date).AddYears(3)

Write-Host "created_thumbprint=$($cert.Thumbprint)"
Write-Host "subject=$($cert.Subject)"
Write-Host ""
Write-Host "Usage:"
Write-Host "  `$env:SVIL_CODESIGN_THUMBPRINT = '$($cert.Thumbprint)'"
Write-Host "  npm run tauri:build"
Write-Host ""
Write-Host "Optional (fail build if unsigned):"
Write-Host "  `$env:SVIL_CODESIGN_REQUIRED = '1'"
