const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

console.log('🚀 Starting Dental Case API server with DEBUG mode...');

const { testConnection } = require('./config/database');

// Import routes with detailed logging
console.log('📁 Importing route files with detailed logging...');

const routeFiles = [
  { name: 'Auth Routes', path: './routes/auth' },
  { name: 'Patient Routes', path: './routes/patients' },
  { name: 'Survey Routes', path: './routes/surveys' },
  { name: 'Appointment Routes', path: './routes/appointments' },
  { name: 'Emergency Routes', path: './routes/emergency' },
  { name: 'Emergency Admin Routes', path: './routes/emergency_admin' },
  { name: 'Admin Routes', path: './routes/admin' },
  { name: 'Notification Routes', path: './routes/notifications' },
  { name: 'Email Routes', path: './routes/email' }
];

const importedRoutes = {};

for (const route of routeFiles) {
  try {
    console.log(`📥 Attempting to import ${route.name}...`);
    const routeModule = require(route.path);
    importedRoutes[route.name] = routeModule;
    console.log(`✅ ${route.name} imported successfully`);
  } catch (error) {
    console.log(`❌ ${route.name} import failed:`, error.message);
    console.log(`   Stack trace:`, error.stack);
    importedRoutes[route.name] = null;
  }
}

console.log('📋 Import Summary:');
Object.keys(importedRoutes).forEach(routeName => {
  const status = importedRoutes[routeName] ? '✅ Success' : '❌ Failed';
  console.log(`   ${routeName}: ${status}`);
});

const app = express();
const PORT = process.env.PORT || 3000;

// Trust Railway proxy (fixes rate limiter X-Forwarded-For error)
app.set('trust proxy', 1);
console.log('🔧 Trust proxy set to 1');

// Rate limiting
console.log('⚡ Setting up rate limiting...');

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'development' ? 400 : 200,
  message: {
    error: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'development' ? 1000 : 500,
  message: {
    error: 'Too many admin requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

console.log('✅ Rate limiting set up.');

// Middleware
console.log('🔧 Setting up middleware...');
app.use(helmet());
app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    if (origin.startsWith('http://localhost:') || origin.startsWith('https://localhost:')) {
      return callback(null, true);
    }
    if (process.env.FRONTEND_URL && origin === process.env.FRONTEND_URL) {
      return callback(null, true);
    }
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
console.log('✅ Middleware set up.');

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'Dental Case Backend API (DEBUG MODE)',
    routeStatus: Object.keys(importedRoutes).map(routeName => ({
      route: routeName,
      imported: !!importedRoutes[routeName]
    }))
  });
});
console.log('✅ Health check endpoint set up.');

// API Routes with detailed logging
console.log('🔗 Registering API routes with detailed logging...');

const routeRegistrations = [
  { path: '/api/auth', name: 'Auth Routes', limiter: generalLimiter },
  { path: '/api/patients', name: 'Patient Routes', limiter: generalLimiter },
  { path: '/api/surveys', name: 'Survey Routes', limiter: generalLimiter },
  { path: '/api/appointments', name: 'Appointment Routes', limiter: generalLimiter },
  { path: '/api/emergency', name: 'Emergency Routes', limiter: generalLimiter },
  { path: '/api/notifications', name: 'Notification Routes', limiter: generalLimiter },
  { path: '/api/email', name: 'Email Routes', limiter: generalLimiter },
  { path: '/api/admin', name: 'Admin Routes', limiter: adminLimiter },
  { path: '/api/emergency-admin', name: 'Emergency Admin Routes', limiter: adminLimiter }
];

for (const route of routeRegistrations) {
  if (importedRoutes[route.name]) {
    try {
      app.use(route.path, route.limiter, importedRoutes[route.name]);
      console.log(`✅ ${route.name} registered at ${route.path}`);
    } catch (error) {
      console.log(`❌ Failed to register ${route.name}:`, error.message);
    }
  } else {
    console.log(`⚠️ Skipping ${route.name} - not imported`);
  }
}

console.log('✅ API routes registered.');

// 404 handler
app.use('*', (req, res) => {
  console.log(`🔍 404 - Route not found: ${req.originalUrl}`);
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl,
    availableRoutes: routeRegistrations.filter(r => importedRoutes[r.name]).map(r => r.path)
  });
});
console.log('✅ 404 handler set up.');

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Error:', err);
  
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  res.status(err.status || 500).json({
    error: isDevelopment ? err.message : 'Internal server error',
    ...(isDevelopment && { stack: err.stack })
  });
});
console.log('✅ Error handling middleware set up.');

// Start server
async function startServer() {
  try {
    console.log('🚀 Starting Express server...');
    app.listen(PORT, () => {
      console.log(`🎉 Dental Case API server running on port ${PORT} (DEBUG MODE)`);
      console.log(`📱 Health check: http://localhost:${PORT}/health`);
      console.log(`🔧 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`📊 Route Status:`);
      Object.keys(importedRoutes).forEach(routeName => {
        const status = importedRoutes[routeName] ? '✅' : '❌';
        console.log(`   ${status} ${routeName}`);
      });
    });
    
    // Test database connection
    console.log('🗄️ Testing database connection...');
    await testConnection();
    console.log('✅ Database connection verified');
    
  } catch (error) {
    console.error('❌ Error starting server:', error);
    process.exit(1);
  }
}

startServer(); 