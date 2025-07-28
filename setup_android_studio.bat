@echo off
echo ========================================
echo    ANDROID STUDIO SETUP GUIDE
echo ========================================
echo.

echo [1/5] Checking if Android Studio is installed...
if exist "C:\Program Files\Android\Android Studio\bin\studio64.exe" (
    echo ✅ Android Studio found!
) else if exist "C:\Program Files (x86)\Android\Android Studio\bin\studio64.exe" (
    echo ✅ Android Studio found!
) else (
    echo ❌ Android Studio not found in default location
    echo Please install Android Studio first from:
    echo https://developer.android.com/studio
    pause
    exit /b 1
)

echo.
echo [2/5] Setting up Android SDK path...
set ANDROID_HOME=C:\Users\%USERNAME%\AppData\Local\Android\Sdk
echo ANDROID_HOME set to: %ANDROID_HOME%

echo.
echo [3/5] Configuring Flutter for Android...
flutter config --android-sdk %ANDROID_HOME%
if %errorlevel% neq 0 (
    echo WARNING: Could not set Android SDK path automatically
    echo You may need to set it manually in Android Studio
)

echo.
echo [4/5] Running Flutter doctor...
flutter doctor
if %errorlevel% neq 0 (
    echo WARNING: Flutter doctor found issues
)

echo.
echo [5/5] Setup complete!
echo.
echo Next steps:
echo 1. Open Android Studio
echo 2. Go to Tools > SDK Manager
echo 3. Install Android SDK Platform 33 or higher
echo 4. Install Android SDK Build-Tools
echo 5. Accept Android licenses: flutter doctor --android-licenses
echo 6. Run: .\build_apk_local.bat
echo.
pause 