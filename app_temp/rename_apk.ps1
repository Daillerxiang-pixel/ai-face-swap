# Rename APK with version from pubspec.yaml
$v = (Select-String -Path pubspec.yaml -Pattern '^version:' | Select-Object -First 1).Line.Split(':')[1].Trim()
$old = "build\app\outputs\flutter-apk\app-debug.apk"
$new = "build\app\outputs\flutter-apk\face_swap-v${v}.apk"
if (Test-Path $old) {
    Remove-Item $new -ErrorAction SilentlyContinue
    Move-Item $old $new -Force
    Write-Host ""
    Write-Host "=== BUILD SUCCESS ==="
    Write-Host "APK: $((Resolve-Path $new).Path)"
    Write-Host "Version: $v"
} else {
    Write-Host "ERROR: APK not found at $old"
}
