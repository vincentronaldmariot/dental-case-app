const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

console.log('Starting Dental Case API server...');

const { testConnection } = require('./config/database');

// Import routes
console.log('Importing route files...');
const authRoutes = require('./routes/auth');
const patientRoutes = require('./routes/patients');
const surveyRoutes = require('./routes/surveys');
const appointmentRoutes = require('./routes/appointments');
const emergencyRoutes = require('./routes/emergency');
const emergencyAdminRoutes = require('./routes/emergency_admin');
const adminRoutes = require('./routes/admin');
console.log('Route files imported.');

const app = express();
const PORT = process.env.PORT || 3000;

// Rate limiting
console.log('Setting up rate limiting...');

// General rate limiter for all routes
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'development' ? 400 : 200, // Higher limit in development
  message: {
    error: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// More permissive rate limiter for admin routes
const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'development' ? 1000 : 500, // Higher limit in development
  message: {
    error: 'Too many admin requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

console.log('Rate limiting set up.');

// Middleware
console.log('Setting up middleware...');
app.use(helmet());
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Allow localhost origins
    if (origin.startsWith('http://localhost:') || origin.startsWith('https://localhost:')) {
      return callback(null, true);
    }
    
    // Allow specific frontend URL if set
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
console.log('Middleware set up.');

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'Dental Case Backend API'
  });
});
console.log('Health check endpoint set up.');

// API Routes
console.log('Registering API routes...');

// Apply general rate limiting to most routes
app.use('/api/auth', generalLimiter, authRoutes);
app.use('/api/patients', generalLimiter, patientRoutes);
app.use('/api/surveys', generalLimiter, surveyRoutes);
app.use('/api/appointments', generalLimiter, appointmentRoutes);
app.use('/api/emergency', generalLimiter, emergencyRoutes);

// Apply more permissive rate limiting to admin routes
app.use('/api/admin', adminLimiter, adminRoutes);
app.use('/api/emergency-admin', adminLimiter, emergencyAdminRoutes);

console.log('API routes registered.');

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl
  });
});
console.log('404 handler set up.');

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  // Don't leak error details in production
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  res.status(err.status || 500).json({
    error: isDevelopment ? err.message : 'Internal server error',
    ...(isDevelopment && { stack: err.stack })
  });
});
console.log('Error handling middleware set up.');

// Start server
async function startServer() {
  try {
    console.log('Starting Express server...');
    app.listen(PORT, () => {
      console.log(`🚀 Dental Case API server running on port ${PORT}`);
      console.log(`📱 Health check: http://localhost:${PORT}/health`);
      console.log(`🔧 Environment: ${process.env.NODE_ENV || 'development'}`);
    });
    
    // Try to connect to database with retries
    console.log('Testing database connection...');
    let dbConnected = false;
    let retries = 0;
    const maxRetries = 5;
    
    while (!dbConnected && retries < maxRetries) {
      try {
        await testConnection();
        console.log('✅ Database connection verified');
        dbConnected = true;
        
        // Auto-create tables if they don't exist
        console.log('Setting up database tables...');
        let setupSuccess = false;
        try {
          const { setupDatabase } = require('./setup_railway_db');
          await setupDatabase();
          console.log('✅ Database tables created/verified');
          setupSuccess = true;
        } catch (setupError) {
          console.log('⚠️ Database setup warning:', setupError.message);
          // Continue anyway - tables might already exist
        }
        
        // If we're using in-memory database and setup failed, create admin user
        if (process.env.NODE_ENV === 'production' && !setupSuccess) {
          console.log('🗄️ Creating admin user in in-memory database...');
          try {
            const { query } = require('./config/database');
            const bcrypt = require('bcrypt');
            const passwordHash = await bcrypt.hash('admin123', 12);
            
            await query(`
              INSERT INTO admin_users (id, username, password_hash, full_name, role, is_active)
              VALUES ($1, $2, $3, $4, $5, $6)
              ON CONFLICT (username) DO NOTHING
            `, ['1', 'admin', passwordHash, 'System Administrator', 'admin', true]);
            
            console.log('✅ Admin user created in in-memory database');
          } catch (adminError) {
            console.log('⚠️ Admin user creation warning:', adminError.message);
          }
        }
        
      } catch (error) {
        retries++;
        console.log(`❌ Database connection failed (attempt ${retries}/${maxRetries}):`, error.message);
        if (retries < maxRetries) {
          console.log(`🔄 Retrying in 5 seconds...`);
          await new Promise(resolve => setTimeout(resolve, 5000));
        } else {
          console.log('⚠️ Database connection failed after all retries. Server will continue without database.');
        }
      }
    }
    
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

startServer(); 