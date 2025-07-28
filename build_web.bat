@echo off
echo ========================================
echo    DENTAL CASE APP - WEB BUILDER
echo ========================================
echo.

echo [1/4] Checking Flutter installation...
flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found! Please install Flutter first.
    pause
    exit /b 1
)

echo.
echo [2/4] Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)

echo.
echo [3/4] Building for web...
flutter build web
if %errorlevel% neq 0 (
    echo ERROR: Web build failed!
    pause
    exit /b 1
)

echo.
echo [4/4] Web build completed successfully!
echo.
echo Web files location: build\web\
echo.
echo To serve locally:
echo 1. Navigate to build\web\
echo 2. Run: python -m http.server 8000
echo 3. Open: http://localhost:8000
echo.
echo To deploy online:
echo 1. Upload build\web\ folder to any web hosting service
echo 2. Examples: GitHub Pages, Netlify, Vercel, Firebase Hosting
echo.
pause 