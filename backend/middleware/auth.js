const jwt = require('jsonwebtoken');
const { query } = require('../config/database');

// Verify JWT token middleware
const verifyToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Access denied. No token provided.'
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    
    // Verify the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Add user info to request
    req.user = decoded;
    
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token expired. Please login again.'
      });
    }
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Invalid token.'
      });
    }
    
    console.error('Auth middleware error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
};

// Verify patient token and get patient data
const verifyPatient = async (req, res, next) => {
  try {
    await verifyToken(req, res, () => {});
    
    if (req.user.type !== 'patient') {
      return res.status(403).json({
        error: 'Access denied. Patient access required.'
      });
    }
    
    // Get patient data from database
    const result = await query(
      'SELECT id, first_name, last_name, email, phone FROM patients WHERE id = $1',
      [req.user.id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Patient not found'
      });
    }
    
    req.patient = result.rows[0];
    next();
  } catch (error) {
    console.error('Patient verification error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
};

// Verify admin token
const verifyAdmin = async (req, res, next) => {
  try {
    await verifyToken(req, res, () => {});
    
    if (req.user.type !== 'admin') {
      return res.status(403).json({
        error: 'Access denied. Admin access required.'
      });
    }
    
    // Get admin data from database
    const result = await query(
      'SELECT id, username, full_name, role FROM admin_users WHERE id = $1 AND is_active = true',
      [req.user.id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Admin not found or inactive'
      });
    }
    
    req.admin = result.rows[0];
    next();
  } catch (error) {
    console.error('Admin verification error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
};

// Generate JWT token
function generateToken(payload) {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
}

module.exports = {
  verifyToken,
  verifyPatient,
  verifyAdmin,
  generateToken
}; 