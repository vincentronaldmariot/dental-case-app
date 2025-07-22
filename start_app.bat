@echo off
echo Starting Dental Case Application...
echo.

echo [1/3] Starting Backend Server...
cd backend
start "Backend Server" cmd /k "node server.js"
cd ..

echo [2/3] Waiting for backend to start...
timeout /t 3 /nobreak > nul

echo [3/3] Starting Flutter App...
flutter run

echo.
echo Application started successfully!
echo Backend: http://localhost:3000
echo Flutter App: Running on device/emulator
echo.
echo Press any key to exit...
pause > nul 