# Android SDK Setup Script for Flutter
Write-Host "Setting up Android SDK for Flutter APK building..." -ForegroundColor Green

# Set environment variables
$env:ANDROID_HOME = "$env:USERPROFILE\Android\Sdk"
$env:ANDROID_SDK_ROOT = "$env:USERPROFILE\Android\Sdk"

Write-Host "Android SDK path: $env:ANDROID_HOME" -ForegroundColor Yellow

# Create necessary directories
$platformsDir = "$env:ANDROID_HOME\platforms"
$buildToolsDir = "$env:ANDROID_HOME\build-tools"
$cmdlineToolsDir = "$env:ANDROID_HOME\cmdline-tools\latest"

New-Item -ItemType Directory -Force -Path $platformsDir | Out-Null
New-Item -ItemType Directory -Force -Path $buildToolsDir | Out-Null
New-Item -ItemType Directory -Force -Path $cmdlineToolsDir | Out-Null

Write-Host "Created SDK directories" -ForegroundColor Green

# Download Android SDK command line tools
Write-Host "Downloading Android SDK command line tools..." -ForegroundColor Yellow

$cmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$downloadPath = "$env:TEMP\commandlinetools-win.zip"

try {
    Invoke-WebRequest -Uri $cmdlineToolsUrl -OutFile $downloadPath
    Write-Host "Downloaded command line tools" -ForegroundColor Green
    
    # Extract to cmdline-tools directory
    Expand-Archive -Path $downloadPath -DestinationPath "$env:ANDROID_HOME\cmdline-tools" -Force
    
    # Move to latest directory
    $extractedDir = Get-ChildItem "$env:ANDROID_HOME\cmdline-tools" -Directory | Where-Object { $_.Name -like "cmdline-tools*" } | Select-Object -First 1
    if ($extractedDir) {
        Move-Item "$($extractedDir.FullName)\*" "$env:ANDROID_HOME\cmdline-tools\latest\" -Force
        Remove-Item $extractedDir.FullName -Force
    }
    
    Write-Host "Extracted command line tools" -ForegroundColor Green
    
} catch {
    Write-Host "Failed to download command line tools: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please download manually from: https://developer.android.com/studio#command-tools" -ForegroundColor Yellow
}

# Set PATH
$env:PATH += ";$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools"

Write-Host "Environment variables set:" -ForegroundColor Green
Write-Host "   ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Cyan
Write-Host "   ANDROID_SDK_ROOT: $env:ANDROID_SDK_ROOT" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Run: flutter doctor" -ForegroundColor White
Write-Host "2. Run: flutter build apk --debug" -ForegroundColor White
Write-Host "3. The APK will be created in: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor White

Write-Host "`nSetup complete!" -ForegroundColor Green 