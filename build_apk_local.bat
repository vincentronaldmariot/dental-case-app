@echo off
echo ========================================
echo    DENTAL CASE APP - APK BUILDER
echo ========================================
echo.

echo [1/6] Checking Flutter installation...
flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found! Please install Flutter first.
    echo Download from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo.
echo [2/6] Checking Flutter doctor...
flutter doctor
if %errorlevel% neq 0 (
    echo WARNING: Flutter doctor found issues. Continuing anyway...
)

echo.
echo [3/6] Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)

echo.
echo [4/6] Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo WARNING: Clean failed. Continuing anyway...
)

echo.
echo [5/6] Building APK...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo ERROR: APK build failed!
    echo.
    echo Possible solutions:
    echo 1. Install Android Studio
    echo 2. Set ANDROID_HOME environment variable
    echo 3. Install Java JDK 11+
    echo 4. Run: flutter doctor --android-licenses
    pause
    exit /b 1
)

echo.
echo [6/6] Build completed successfully!
echo.
echo APK location: build\app\outputs\flutter-apk\app-debug.apk
echo.
echo To install on Android device:
echo 1. Enable Developer Options on your phone
echo 2. Enable USB Debugging
echo 3. Connect phone via USB
echo 4. Run: flutter install
echo.
pause 