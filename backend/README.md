# Dental Case App - Node.js Backend

A complete RESTful API backend for the Flutter dental case management application, built with Node.js, Express, and PostgreSQL.

## 🚀 Features

- **Patient Authentication**: JWT-based login and registration
- **Dental Surveys**: Submit and retrieve patient dental assessments
- **Appointment Management**: Book, view, and manage dental appointments
- **Emergency Records**: Handle dental emergency cases
- **Admin Dashboard**: Administrative oversight and management
- **Secure API**: Rate limiting, input validation, and CORS protection

## 📋 Prerequisites

Before setting up the backend, ensure you have:

- **Node.js** (v18 or higher)
- **PostgreSQL** (v12 or higher)
- **npm** or **yarn** package manager

## 🛠️ Installation & Setup

### 1. Clone and Install Dependencies

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install
```

### 2. Database Setup

#### Install PostgreSQL
- **Windows**: Download from [postgresql.org](https://www.postgresql.org/downloads/windows/)
- **macOS**: `brew install postgresql`
- **Linux**: `sudo apt-get install postgresql postgresql-contrib`

#### Create Database and User

```sql
-- Connect to PostgreSQL as superuser
psql -U postgres

-- Create database and user
CREATE DATABASE dental_case_db;
CREATE USER dental_user WITH PASSWORD 'dental_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE dental_case_db TO dental_user;
ALTER USER dental_user CREATEDB;

-- Exit
\q
```

### 3. Environment Configuration

Create a `.env` file in the backend directory:

```env
# Server Configuration
NODE_ENV=development
PORT=3000

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dental_case_db
DB_USER=dental_user
DB_PASSWORD=dental_password
DATABASE_URL=postgresql://dental_user:dental_password@localhost:5432/dental_case_db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d

# Frontend Configuration
FRONTEND_URL=http://localhost:8080

# Security
BCRYPT_ROUNDS=12

# File Upload
MAX_FILE_SIZE=10485760

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=info
```

### 4. Database Migration

Run the migration script to create all tables:

```bash
npm run migrate
```

This will create the following tables:
- `patients` - Patient information and authentication
- `dental_surveys` - Dental assessment data
- `appointments` - Appointment bookings
- `treatment_records` - Treatment history
- `emergency_records` - Emergency cases
- `admin_users` - Administrative users

### 5. Seed Data (Optional)

Create sample admin user:

```bash
npm run seed
```

Or manually create an admin user:

```sql
-- Connect to the database
psql -U dental_user -d dental_case_db

-- Insert admin user (password: admin123)
INSERT INTO admin_users (username, password_hash, full_name, role)
VALUES ('admin', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8.2sE9j/BN7Z4iO8qSu', 'System Administrator', 'admin');
```

## 🏃‍♂️ Running the Server

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

The server will start on `http://localhost:3000`

### Health Check
Visit `http://localhost:3000/health` to verify the server is running.

## 📚 API Documentation

### Authentication Endpoints

#### POST `/api/auth/register` - Patient Registration
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@email.com",
  "password": "password123",
  "phone": "+1234567890",
  "dateOfBirth": "1990-01-01",
  "address": "123 Main St",
  "emergencyContact": "Jane Doe",
  "emergencyPhone": "+1234567891",
  "medicalHistory": "None",
  "allergies": "None",
  "serialNumber": "SN001",
  "unitAssignment": "Unit A",
  "classification": "Military",
  "otherClassification": ""
}
```

#### POST `/api/auth/login` - Patient Login
```json
{
  "email": "john.doe@email.com",
  "password": "password123"
}
```

#### POST `/api/auth/admin/login` - Admin Login
```json
{
  "username": "admin",
  "password": "admin123"
}
```

### Patient Endpoints

#### GET `/api/patients/profile` - Get Patient Profile
Requires: Bearer token

#### PUT `/api/patients/profile` - Update Patient Profile
Requires: Bearer token

### Survey Endpoints

#### POST `/api/surveys` - Submit Dental Survey
```json
{
  "surveyData": {
    "patient_info": { ... },
    "tooth_conditions": { ... },
    "tartar_level": "mild",
    "tooth_sensitive": true,
    "damaged_fillings": { ... },
    "need_dentures": false,
    "has_missing_teeth": false
  }
}
```

#### GET `/api/surveys` - Get Patient's Survey
Requires: Bearer token

#### GET `/api/surveys/status` - Check Survey Status
Requires: Bearer token

### Appointment Endpoints

#### POST `/api/appointments` - Book Appointment
```json
{
  "service": "General Checkup",
  "appointmentDate": "2024-12-25T10:00:00Z",
  "timeSlot": "10:00",
  "doctorName": "Dr. Smith",
  "notes": "Regular checkup"
}
```

#### GET `/api/appointments` - Get Patient Appointments
Requires: Bearer token

#### GET `/api/appointments/:id` - Get Specific Appointment
Requires: Bearer token

#### PUT `/api/appointments/:id` - Update Appointment
Requires: Bearer token

#### DELETE `/api/appointments/:id` - Cancel Appointment
Requires: Bearer token

#### GET `/api/appointments/available-slots/:date` - Get Available Time Slots
Requires: Bearer token

### Emergency Endpoints

#### POST `/api/emergency` - Submit Emergency Record
#### GET `/api/emergency` - Get Emergency Records

### Admin Endpoints

#### GET `/api/admin/dashboard` - Admin Dashboard Data
#### GET `/api/admin/patients` - Get All Patients
#### GET `/api/admin/appointments` - Get All Appointments
#### PUT `/api/admin/appointments/:id/status` - Update Appointment Status

## 🔧 Flutter App Configuration

Update your Flutter app to use the Node.js backend:

1. **Update `lib/services/api_service.dart`**:
   ```dart
   static const String baseUrl = 'http://your-server-ip:3000/api';
   ```

2. **For local development**, use:
   ```dart
   static const String baseUrl = 'http://localhost:3000/api';
   ```

3. **For production**, use your server's IP or domain:
   ```dart
   static const String baseUrl = 'https://your-domain.com/api';
   ```

## 🐳 Docker Setup (Optional)

### Using Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: dental_case_db
      POSTGRES_USER: dental_user
      POSTGRES_PASSWORD: dental_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://dental_user:dental_password@postgres:5432/dental_case_db
    depends_on:
      - postgres

volumes:
  postgres_data:
```

Run with:
```bash
docker-compose up -d
```

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcrypt with configurable rounds
- **Rate Limiting**: Prevents API abuse
- **Input Validation**: Comprehensive request validation
- **CORS Protection**: Configurable cross-origin policies
- **SQL Injection Prevention**: Parameterized queries
- **Environment Variables**: Sensitive data protection

## 📊 Database Schema

### Patients Table
- Personal information and authentication data
- Medical history and emergency contacts
- Military/civilian classification

### Dental Surveys Table
- Comprehensive dental assessment data
- JSON storage for flexible survey structure
- Timestamp tracking

### Appointments Table
- Booking information and scheduling
- Status tracking (pending, scheduled, completed, cancelled)
- Doctor assignment and notes

### Treatment Records Table
- Historical treatment data
- Procedures and prescriptions
- Doctor notes and follow-ups

### Emergency Records Table
- Emergency case documentation
- Priority levels and symptoms
- Response tracking

## 🔄 Data Migration

From Firebase to Node.js/PostgreSQL:

1. **Export Firebase data** using Admin SDK
2. **Transform data** to match PostgreSQL schema
3. **Import data** using provided migration scripts
4. **Update Flutter app** to use new API endpoints

## 🚨 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL is running: `sudo service postgresql status`
   - Verify credentials in `.env` file
   - Ensure database exists: `psql -U dental_user -d dental_case_db`

2. **Port Already in Use**
   - Change PORT in `.env` file
   - Kill existing process: `lsof -ti:3000 | xargs kill -9`

3. **JWT Token Issues**
   - Check JWT_SECRET is set in `.env`
   - Verify token format in Flutter app
   - Check token expiration settings

4. **CORS Errors**
   - Update FRONTEND_URL in `.env`
   - Check cors configuration in `server.js`

### Logs

Check server logs for detailed error information:
```bash
# Development
npm run dev

# Production logs
pm2 logs dental-api
```

## 📈 Performance Optimization

- **Database Indexing**: Optimized queries for common operations
- **Connection Pooling**: Efficient database connection management
- **Request Compression**: Gzip compression for API responses
- **Caching**: Redis caching for frequently accessed data (optional)

## 🚀 Deployment

### PM2 (Recommended)

```bash
# Install PM2
npm install -g pm2

# Start application
pm2 start server.js --name "dental-api"

# Save PM2 configuration
pm2 save
pm2 startup
```

### Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 📞 Support

For issues and questions:
- Check the troubleshooting section
- Review server logs
- Verify database connectivity
- Test API endpoints with Postman

## 🔄 Updates and Maintenance

- Regular security updates: `npm audit fix`
- Database backups: `pg_dump dental_case_db > backup.sql`
- Monitor server performance
- Update dependencies regularly

---

**Your dental case management app is now powered by a robust Node.js backend!** 🦷✨ 