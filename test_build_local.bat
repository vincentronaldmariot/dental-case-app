@echo off
echo ========================================
echo    Testing Flutter Build Locally
echo ========================================
echo.

echo Step 1: Checking Flutter version...
flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found
    pause
    exit /b 1
)

echo.
echo Step 2: Running Flutter doctor...
flutter doctor
if %errorlevel% neq 0 (
    echo WARNING: Flutter doctor found issues
)

echo.
echo Step 3: Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo Step 4: Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo WARNING: Clean failed, continuing anyway
)

echo.
echo Step 5: Testing Android build capability...
flutter build apk --debug --verbose
if %errorlevel% neq 0 (
    echo ERROR: Android build failed
    echo.
    echo This suggests the issue is with:
    echo 1. Android SDK setup
    echo 2. Java JDK installation
    echo 3. Flutter Android configuration
    echo.
    echo For GitHub Actions, this might be a platform-specific issue.
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
pause 