# Reads pubspec.yaml version line; prints x.y.z-build with + replaced by - (for safe filenames)
param(
    [Parameter(Mandatory = $true)]
    [string] $PubspecPath
)
$c = Get-Content -LiteralPath $PubspecPath -Raw -Encoding UTF8
if ($c -match '(?m)^version:\s*(.+)$') {
    Write-Output ($Matches[1].Trim() -replace '\+', '-')
} else {
    Write-Output '0.0.0-0'
}
