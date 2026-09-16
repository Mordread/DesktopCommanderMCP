param(
  [switch]$CheckOnly,
  [switch]$CheckDeployed,
  [switch]$Build
)
$ErrorActionPreference = 'Stop'
$repo = 'C:\Dev\AI\DesktopCommanderMCP'
$stampPath = Join-Path $repo 'dist\.mainrig-build.json'
$distIndex = Join-Path $repo 'dist\index.js'
if ((@($CheckOnly, $CheckDeployed, $Build) | Where-Object { $_ }).Count -gt 1) {
  throw 'Choose only one mode: -CheckOnly, -CheckDeployed, or -Build.'
}
$fixed = @(
  'package.json','package-lock.json','tsconfig.json',
  'setup-claude-server.js','uninstall-claude-server.js','track-installation.js',
  'scripts\build-ui-runtime.cjs'
)
function Get-SourceFingerprint {
  $files = @((Get-ChildItem (Join-Path $repo 'src') -Recurse -File))
  $files += @($fixed | ForEach-Object { Get-Item (Join-Path $repo $_) })
  $lines = foreach ($file in ($files | Sort-Object FullName)) {
    $relative = $file.FullName.Substring($repo.Length + 1).Replace('\','/')
    $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    "$relative`t$hash"
  }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
  } finally { $sha.Dispose() }
}$fingerprint = Get-SourceFingerprint
$stamp = $null
if (Test-Path $stampPath) {
  try { $stamp = Get-Content $stampPath -Raw | ConvertFrom-Json } catch { $stamp = $null }
}
$distHash = if (Test-Path $distIndex) {
  (Get-FileHash $distIndex -Algorithm SHA256).Hash.ToLowerInvariant()
} else { $null }
$deployedValid = [bool]($stamp -and $distHash -and $stamp.dist_index_sha256 -eq $distHash)
$sourceCurrent = [bool]($deployedValid -and $stamp.fingerprint -eq $fingerprint)
$head = (& git -C $repo rev-parse HEAD).Trim()
if ($CheckDeployed) {
  [pscustomobject]@{
    deployed_valid=$deployedValid; dist_hash=$distHash; stamped_dist_hash=$stamp.dist_index_sha256
    built_head=$stamp.head
  } | ConvertTo-Json -Compress
  if ($deployedValid) { exit 0 } else { exit 12 }
}
if ($CheckOnly -or -not $Build) {
  [pscustomobject]@{
    deployed_valid=$deployedValid; source_current=$sourceCurrent
    fingerprint=$fingerprint; built_fingerprint=$stamp.fingerprint
    head=$head; built_head=$stamp.head
  } | ConvertTo-Json -Compress
  if ($sourceCurrent) { exit 0 } else { exit 10 }
}$dirty = (& git -C $repo status --porcelain --untracked-files=normal)
if ($dirty) {
  [Console]::Error.WriteLine('Refusing explicit deploy build from a dirty working tree.')
  exit 11
}
Push-Location $repo
try {
  & npm.cmd run build
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally { Pop-Location }
if (-not (Test-Path $distIndex)) { [Console]::Error.WriteLine('Build completed without dist\index.js.'); exit 13 }
$distHash = (Get-FileHash $distIndex -Algorithm SHA256).Hash.ToLowerInvariant()
$record = [ordered]@{
  schema = 2
  fingerprint = $fingerprint
  head = $head
  built_at = (Get-Date).ToUniversalTime().ToString('o')
  node = (& node.exe --version).Trim()
  dist_index_sha256 = $distHash
}
$record | ConvertTo-Json | Set-Content -Path $stampPath -Encoding UTF8
Write-Output "Built MainRig dist for $($head.Substring(0,7)); dist=$distHash"
exit 0

