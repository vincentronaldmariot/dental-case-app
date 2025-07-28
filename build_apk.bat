@echo off
echo ========================================
echo    Dental Case App - APK Builder
echo ========================================
echo.

echo Checking Flutter installation...
flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo.
echo Checking Flutter doctor...
flutter doctor
if %errorlevel% neq 0 (
    echo WARNING: Flutter doctor found issues
    echo You may need to install Android SDK and Java JDK
)

echo.
echo Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo Building APK...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo ERROR: Failed to build APK
    echo.
    echo Possible solutions:
    echo 1. Install Java JDK 11+ from: https://adoptium.net/
    echo 2. Install Android Studio from: https://developer.android.com/studio
    echo 3. Set ANDROID_HOME environment variable
    pause
    exit /b 1
)

echo.
echo ========================================
echo    BUILD SUCCESSFUL!
echo ========================================
echo.
echo APK location: build\app\outputs\flutter-apk\app-debug.apk
echo.
echo You can now:
echo 1. Transfer the APK to an Android device
echo 2. Enable "Install from Unknown Sources" in device settings
echo 3. Install the APK
echo.
pause 