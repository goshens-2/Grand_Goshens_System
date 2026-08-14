# Reliable local web launch for Windows profiles with spaces in the user path.
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$userProfilePath = $env:USERPROFILE

if ($userProfilePath -match " ") {
    subst G: $userProfilePath 2>$null
    $env:USERPROFILE = "G:\"
    $env:LOCALAPPDATA = "G:\AppData\Local"
    $env:APPDATA = "G:\AppData\Roaming"
    $flutter = "G:\develop\flutter\bin\flutter.bat"
} else {
    $flutter = "flutter"
}

Set-Location $projectRoot

Write-Host "Building Goshens Dental Care for web..."
& $flutter build web --release --no-web-resources-cdn --no-wasm-dry-run --pwa-strategy=none
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Serving release build at http://localhost:8080"
Write-Host "Open that URL in Chrome or Edge. Press Ctrl+C to stop."
Write-Host ""

Set-Location "$projectRoot\build\web"
py -m http.server 8080
