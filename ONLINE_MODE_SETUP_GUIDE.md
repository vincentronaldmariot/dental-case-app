# Online Mode Setup Guide

## Overview

Your dental case app is currently configured to run in **local mode** (connecting to `localhost:3000`). To enable **online mode**, you need to deploy your backend server to a cloud service and update the app configuration.

## Prerequisites

1. **Backend Server**: Your Node.js backend must be deployed to a cloud service
2. **Database**: PostgreSQL database accessible from the cloud
3. **Domain/URL**: A public URL for your backend server
4. **SSL Certificate**: HTTPS is required for production apps

## Step-by-Step Setup

### 1. Deploy Backend Server

Choose one of these cloud platforms:

#### Option A: Heroku (Recommended for beginners)
```bash
# Install Heroku CLI
# Create a new Heroku app
heroku create your-dental-app-backend

# Add PostgreSQL addon
heroku addons:create heroku-postgresql:hobby-dev

# Set environment variables
heroku config:set JWT_SECRET=your_jwt_secret
heroku config:set NODE_ENV=production

# Deploy
git push heroku main
```

#### Option B: Railway
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and create project
railway login
railway init

# Deploy
railway up
```

#### Option C: DigitalOcean App Platform
1. Create a new app in DigitalOcean
2. Connect your GitHub repository
3. Configure environment variables
4. Deploy

### 2. Update App Configuration

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  // Change this to true for online mode
  static const bool isOnlineMode = true;
  
  // Update this to your actual server URL
  static const String onlineServerUrl = 'https://your-app.herokuapp.com';
  // or 'https://your-app.railway.app'
  // or 'https://your-app.ondigitalocean.app'
}
```

### 3. Build and Install Online APK

#### Option A: Use the provided script
```bash
# Run the online mode setup script
switch_to_online_mode.bat
```

#### Option B: Manual build
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release

# Install on connected device
flutter install --release
```

### 4. Test Online Connection

1. Install the new APK on your phone
2. Open the app
3. Check the console logs for connection status
4. Try logging in with admin credentials

## Configuration Details

### Environment Variables for Backend

Set these in your cloud platform:

```env
NODE_ENV=production
PORT=3000
JWT_SECRET=your_secure_jwt_secret
JWT_EXPIRES_IN=7d

# Database (if using cloud database)
DB_HOST=your-db-host
DB_PORT=5432
DB_NAME=your-db-name
DB_USER=your-db-user
DB_PASSWORD=your-db-password

# CORS settings
FRONTEND_URL=https://your-frontend-domain.com
```

### App Configuration Options

In `lib/config/app_config.dart`:

```dart
class AppConfig {
  // Server modes
  static const bool isOnlineMode = true; // false for local, true for online
  
  // Server URLs
  static const String localServerUrl = 'http://localhost:3000';
  static const String onlineServerUrl = 'https://your-server.com';
  
  // Timeouts
  static const int connectionTimeoutSeconds = 10;
  static const int requestTimeoutSeconds = 30;
  
  // Retry settings
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;
}
```

## Troubleshooting

### Common Issues

#### 1. Connection Timeout
- Check if your server URL is correct
- Verify the server is running and accessible
- Check firewall settings

#### 2. CORS Errors
- Ensure your backend has proper CORS configuration
- Check if the frontend URL is allowed

#### 3. Database Connection Issues
- Verify database credentials
- Check if database is accessible from cloud server
- Ensure SSL connections are configured

#### 4. SSL Certificate Issues
- Make sure your server has a valid SSL certificate
- Check if the certificate is trusted by mobile devices

### Debug Steps

1. **Check Server Status**
   ```bash
   curl https://your-server.com/health
   ```

2. **Test API Endpoints**
   ```bash
   curl -X POST https://your-server.com/api/auth/admin/login \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"admin123"}'
   ```

3. **Check App Logs**
   - Connect phone to computer
   - Run `flutter logs` to see app logs
   - Look for connection errors

## Security Considerations

### For Production

1. **Use HTTPS**: Always use HTTPS in production
2. **Secure JWT Secret**: Use a strong, random JWT secret
3. **Database Security**: Use connection pooling and SSL
4. **Rate Limiting**: Implement API rate limiting
5. **Input Validation**: Validate all user inputs
6. **Environment Variables**: Never commit secrets to code

### Recommended Security Headers

Add these to your backend:

```javascript
app.use(helmet()); // Security headers
app.use(cors({
  origin: process.env.FRONTEND_URL,
  credentials: true
}));
```

## Monitoring and Maintenance

### Health Checks
- Set up automated health checks for your server
- Monitor database connections
- Set up alerts for downtime

### Logging
- Implement proper logging in your backend
- Monitor error rates and performance
- Set up log aggregation

### Backups
- Regular database backups
- Code version control
- Environment configuration backups

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review server logs for errors
3. Test API endpoints manually
4. Verify network connectivity
5. Check cloud platform status pages

## Next Steps

After setting up online mode:

1. **Test All Features**: Ensure all app functionality works online
2. **Performance Testing**: Test app performance with real network conditions
3. **User Testing**: Have others test the app on different devices
4. **Monitoring**: Set up monitoring and alerting
5. **Backup Strategy**: Implement regular backups
6. **Documentation**: Update documentation for your deployment