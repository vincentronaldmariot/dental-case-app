@echo off
echo ========================================
echo    DENTAL CASE APP - ONLINE MODE SETUP
echo ========================================
echo.

echo This script will help you switch to online mode.
echo.
echo Before proceeding, make sure you have:
echo 1. Deployed your backend server to a cloud service
echo 2. Updated the server URL in lib/config/app_config.dart
echo 3. Configured your database for online access
echo.

set /p proceed="Do you want to proceed? (y/n): "
if /i "%proceed%" neq "y" (
    echo Setup cancelled.
    pause
    exit /b 0
)

echo.
echo [1/3] Updating configuration to online mode...
echo Please edit lib/config/app_config.dart and:
echo - Set isOnlineMode = true
echo - Update onlineServerUrl to your actual server URL
echo.

set /p continue="Have you updated the configuration? (y/n): "
if /i "%continue%" neq "y" (
    echo Please update the configuration first.
    pause
    exit /b 1
)

echo.
echo [2/3] Building APK for online mode...
flutter clean
flutter pub get
flutter build apk --release

if %errorlevel% neq 0 (
    echo ERROR: APK build failed!
    pause
    exit /b 1
)

echo.
echo [3/3] Online mode setup completed!
echo.
echo Your APK is ready at: build\app\outputs\flutter-apk\app-release.apk
echo.
echo To install on your phone:
echo 1. Transfer the APK to your phone
echo 2. Enable "Install from unknown sources" in settings
echo 3. Install the APK
echo.
echo The app will now connect to your online server.
echo.
pause