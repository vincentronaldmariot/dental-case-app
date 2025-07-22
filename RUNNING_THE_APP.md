# Running the Dental Case Application

## Quick Start

### Option 1: Using Scripts (Recommended)

#### Windows Batch Script
```bash
start_app.bat
```

#### PowerShell Script
```powershell
.\start_app.ps1
```

### Option 2: Manual Start

## Prerequisites

1. **Node.js** (v14 or higher)
2. **Flutter** (v3.0 or higher)
3. **PostgreSQL** database running
4. **Git** for version control

## Step-by-Step Instructions

### 1. Start Backend Server

```bash
# Navigate to backend directory
cd backend

# Install dependencies (if not already done)
npm install

# Start the server
node server.js
```

**Expected Output:**
```
Starting Dental Case API server...
Importing route files...
✅ Auth routes loaded
✅ Admin routes loaded
✅ Patient routes loaded
✅ Appointment routes loaded
✅ Survey routes loaded
✅ Emergency routes loaded
Database connected successfully
Server running on port 3000
```

### 2. Start Flutter Application

```bash
# In a new terminal, navigate to project root
cd dental_case_app

# Run Flutter app
flutter run
```

**Expected Output:**
```
Running Gradle task 'assembleDebug'...
Installing build/app/outputs/flutter-apk/app-debug.apk...
Flutter run key commands.
r Hot reload. 🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

## Accessing the Application

### Admin Login
- **URL**: Admin login screen in the Flutter app
- **Username**: `admin`
- **Password**: `admin123`

### Backend API
- **Base URL**: `http://localhost:3000`
- **Health Check**: `http://localhost:3000/api/health`
- **Admin Login**: `POST http://localhost:3000/api/auth/admin/login`

## Troubleshooting

### Backend Issues

#### Port Already in Use
```bash
# Check what's using port 3000
netstat -ano | findstr :3000

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

#### Database Connection Issues
1. Ensure PostgreSQL is running
2. Check database credentials in `backend/config/database.js`
3. Verify database exists and tables are created

#### Module Not Found Errors
```bash
cd backend
npm install
```

### Flutter Issues

#### Flutter Not Found
```bash
# Add Flutter to PATH or use full path
flutter doctor
```

#### Device Not Found
```bash
# List available devices
flutter devices

# Start an emulator if needed
flutter emulators --launch <emulator_id>
```

#### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## Development Workflow

### 1. Backend Development
```bash
cd backend
npm install
node server.js
```

### 2. Frontend Development
```bash
flutter run
```

### 3. Database Changes
```bash
cd backend
node create_admin_users_table.js
```

## File Structure

```
dental_case_app/
├── backend/                 # Node.js backend
│   ├── config/             # Database configuration
│   ├── middleware/         # Authentication middleware
│   ├── routes/             # API routes
│   ├── server.js           # Main server file
│   └── package.json        # Backend dependencies
├── lib/                    # Flutter frontend
│   ├── services/           # API services
│   ├── screens/            # UI screens
│   └── main.dart           # Flutter entry point
├── start_app.bat           # Windows batch script
├── start_app.ps1           # PowerShell script
└── RUNNING_THE_APP.md      # This file
```

## Environment Variables

### Backend (.env file in backend directory)
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dental_clinic
DB_USER=your_username
DB_PASSWORD=your_password
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d
PORT=3000
```

### Frontend (lib/services/api_service.dart)
```dart
class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  // or 'http://10.0.2.2:3000' for Android emulator
}
```

## Testing the Application

### 1. Test Backend API
```bash
# Test admin login
curl -X POST http://localhost:3000/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 2. Test Flutter App
1. Open the app on device/emulator
2. Navigate to admin login
3. Use credentials: admin/admin123
4. Test dashboard functionality

## Common Commands

### Backend
```bash
cd backend
node server.js                    # Start server
node create_admin_users_table.js  # Setup database
npm install                       # Install dependencies
```

### Frontend
```bash
flutter run                       # Run app
flutter clean                     # Clean build
flutter pub get                   # Get dependencies
flutter doctor                    # Check setup
```

## Support

If you encounter issues:

1. Check the console output for error messages
2. Verify all prerequisites are installed
3. Ensure database is running and accessible
4. Check network connectivity
5. Review the troubleshooting section above

## Next Steps

After successfully running the application:

1. **Explore the Admin Dashboard**: Test all features and navigation
2. **Test Patient Registration**: Create test patient accounts
3. **Test Appointments**: Create and manage appointments
4. **Review API Endpoints**: Test all backend functionality
5. **Customize Configuration**: Update settings for your environment 