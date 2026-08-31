# Build a release APK for all device ABIs.
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$userProfilePath = $env:USERPROFILE
$versionName = "1.0.3"
$versionCode = "6"

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

$envFile = Join-Path $projectRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "Missing $envFile. Copy .env.example and set SUPABASE_URL plus SUPABASE_ANON_KEY before building."
}

$localProperties = Join-Path $projectRoot "android\local.properties"
@(
    "sdk.dir=$($env:ANDROID_SDK_ROOT -replace '\\','\\')"
    "flutter.sdk=$($flutterSdk -replace '\\','\\')"
    "flutter.buildMode=release"
    "flutter.versionName=$versionName"
    "flutter.versionCode=$versionCode"
) | Set-Content -Path $localProperties -Encoding ASCII

Set-Location $projectRoot
Write-Host "Generating launcher icons..."
& $flutter pub get
& $flutter pub run flutter_launcher_icons
Write-Host "Building release APK $versionName+$versionCode..."
& $flutter build apk --release `
    --build-name=$versionName `
    --build-number=$versionCode `
    --dart-define-from-file=$envFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apkSource = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-release.apk"
$apkCopy = Join-Path (Split-Path -Parent $projectRoot) "GoshenDentalCare-$versionName.apk"
Copy-Item $apkSource $apkCopy -Force
Write-Host "APK ready:"
Get-Item $apkSource, $apkCopy | Select-Object FullName, Length, LastWriteTime
