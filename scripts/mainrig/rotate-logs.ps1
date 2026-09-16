param(
  [int64]$MaxBytes = 2097152,
  [int]$Keep = 3
)
$ErrorActionPreference = 'Stop'
$state = Join-Path $env:LOCALAPPDATA 'DesktopCommanderMCP-MainRig'
if (-not (Test-Path $state)) { exit 0 }
$names = @('remote-error.log','launcher.log')
foreach ($name in $names) {
  $path = Join-Path $state $name
  if (-not (Test-Path $path)) { continue }
  if ((Get-Item $path).Length -lt $MaxBytes) { continue }
  for ($i = $Keep - 1; $i -ge 1; $i--) {
    $src = "$path.$i"
    $dst = "$path.$($i + 1)"
    if (Test-Path $src) { Move-Item $src $dst -Force }
  }
  Move-Item $path "$path.1" -Force
}
exit 0