Write-Host "Starting Dental Case Application..." -ForegroundColor Green
Write-Host ""

Write-Host "[1/3] Starting Backend Server..." -ForegroundColor Yellow
Set-Location backend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "node server.js" -WindowStyle Normal
Set-Location ..

Write-Host "[2/3] Waiting for backend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "[3/3] Starting Flutter App..." -ForegroundColor Yellow
flutter run

Write-Host ""
Write-Host "Application started successfully!" -ForegroundColor Green
Write-Host "Backend: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Flutter App: Running on device/emulator" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 