# Auto-increment build number in pubspec.yaml
$filePath = Join-Path $PSScriptRoot 'pubspec.yaml'
$c = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
$m = [regex]::Match($c, 'version:\s*(\d+\.\d+\.\d+)\+(\d+)')
if ($m.Success) {
    $fullMatch = $m.Groups[0].Value
    $v = $m.Groups[1].Value
    $n = [int]$m.Groups[2].Value + 1
    $newVer = "version: $v+$n"
    $c = $c.Replace($fullMatch, $newVer)
    [System.IO.File]::WriteAllText($filePath, $c, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "Version bumped to ${v}+${n}"
}
