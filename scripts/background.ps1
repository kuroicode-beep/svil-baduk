# Shared helpers: start Node/npm servers with no visible console.
$ErrorActionPreference = "Stop"

function Test-HttpOk([string]$Uri, [int]$TimeoutSec = 1) {
  try {
    $null = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec $TimeoutSec
    return $true
  } catch {
    return $false
  }
}

function Start-HiddenProcess {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [string[]]$ArgumentList = @(),
    [string]$WorkingDirectory = (Get-Location).Path
  )
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $FilePath
  if ($ArgumentList.Count -gt 0) {
    $psi.Arguments = ($ArgumentList | ForEach-Object {
        $a = [string]$_
        if ($a -match '[\s"]') { '"' + ($a -replace '"', '\"') + '"' } else { $a }
      }) -join ' '
  }
  $psi.WorkingDirectory = $WorkingDirectory
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  # Do not redirect stdio — long-running servers can fill the pipe and stall.
  [void][System.Diagnostics.Process]::Start($psi)
}

function Ensure-KataGoBridge([string]$Root) {
  if (Test-HttpOk "http://127.0.0.1:17419/health") {
    return $false
  }
  $node = (Get-Command node -ErrorAction Stop).Source
  $bridge = Join-Path $Root "scripts\katago-bridge.mjs"
  if (-not (Test-Path $bridge)) { throw "Bridge missing: $bridge" }
  Start-HiddenProcess -FilePath $node -ArgumentList @($bridge) -WorkingDirectory $Root
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline) {
    if (Test-HttpOk "http://127.0.0.1:17419/health") { return $true }
    Start-Sleep -Milliseconds 400
  }
  Write-Warning "KataGo bridge started but /health not ready yet"
  return $true
}
