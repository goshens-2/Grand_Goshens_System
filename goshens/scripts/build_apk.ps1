# Build a release APK for all device ABIs.
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$userProfilePath = $env:USERPROFILE

if ($userProfilePath -match " ") {
    subst G: $userProfilePath 2>$null
    $env:USERPROFILE = "G:\"
    $env:LOCALAPPDATA = "G:\AppData\Local"
    $env:APPDATA = "G:\AppData\Roaming"
    $flutter = "G:\develop\flutter\bin\flutter.bat"
    $flutterSdk = "G:\develop\flutter"
} else {
    $flutter = "flutter"
    $flutterSdk = (Get-Command flutter).Source | Split-Path | Split-Path
}

if (Test-Path "C:\Android\sdk") {
    $env:ANDROID_SDK_ROOT = "C:\Android\sdk"
    $env:ANDROID_HOME = "C:\Android\sdk"
}

$localProperties = Join-Path $projectRoot "android\local.properties"
@(
    "sdk.dir=$($env:ANDROID_SDK_ROOT -replace '\\','\\')"
    "flutter.sdk=$($flutterSdk -replace '\\','\\')"
    "flutter.buildMode=release"
    "flutter.versionName=1.0.0"
    "flutter.versionCode=2"
) | Set-Content -Path $localProperties -Encoding ASCII

Set-Location $projectRoot
Write-Host "Generating launcher icons..."
& $flutter pub get
& $flutter pub run flutter_launcher_icons
Write-Host "Building release APK..."
& $flutter build apk --release --no-deferred-components
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "APK ready:"
Get-ChildItem "$projectRoot\build\app\outputs\flutter-apk\*.apk" | Select-Object FullName, Length, LastWriteTime
