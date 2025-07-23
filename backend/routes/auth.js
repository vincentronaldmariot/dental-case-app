const express = require('express');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { generateToken } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long')
];

const registerValidation = [
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('First name must be between 2 and 100 characters'),
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Last name must be between 2 and 100 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .isLength({ min: 6, max: 128 })
    .withMessage('Password must be between 6 and 128 characters'),
  body('phone')
    .trim()
    .isLength({ min: 10, max: 20 })
    .withMessage('Please provide a valid phone number'),
  body('dateOfBirth')
    .isISO8601()
    .withMessage('Please provide a valid date of birth'),
  body('classification')
    .isIn(['Military', 'AD/HR', 'Department', 'Others', 'Other'])
    .withMessage('Please select a valid classification')
];

// POST /api/auth/register - Patient registration
router.post('/register', registerValidation, async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      firstName,
      lastName,
      email,
      password,
      phone,
      dateOfBirth,
      address,
      emergencyContact,
      emergencyPhone,
      medicalHistory,
      allergies,
      serialNumber,
      unitAssignment,
      classification,
      otherClassification
    } = req.body;

    // Check if email already exists
    const existingUser = await query(
      'SELECT id FROM patients WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        error: 'Email already registered'
      });
    }

    // Hash password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Insert new patient
    const result = await query(`
      INSERT INTO patients (
        first_name, last_name, email, password_hash, phone, date_of_birth,
        address, emergency_contact, emergency_phone, medical_history, allergies,
        serial_number, unit_assignment, classification, other_classification
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING id, first_name, last_name, email, phone, created_at
    `, [
      firstName, lastName, email, hashedPassword, phone, dateOfBirth,
      address, emergencyContact, emergencyPhone, medicalHistory, allergies,
      serialNumber, unitAssignment, classification, otherClassification
    ]);

    const patient = result.rows[0];

    // Generate JWT token
    const token = generateToken({
      id: patient.id,
      email: patient.email,
      type: 'patient'
    });

    res.status(201).json({
      message: 'Patient registered successfully',
      token,
      patient: {
        id: patient.id,
        firstName: patient.first_name,
        lastName: patient.last_name,
        email: patient.email,
        phone: patient.phone,
        createdAt: patient.created_at
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Registration failed. Please try again.'
    });
  }
});

// POST /api/auth/login - Patient login
router.post('/login', loginValidation, async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, password } = req.body;

    // Find patient by email
    const result = await query(
      `SELECT id, first_name, last_name, email, phone, password_hash, 
              classification, serial_number, unit_assignment, created_at
       FROM patients WHERE email = $1`,
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: 'Invalid email or password'
      });
    }

    const patient = result.rows[0];

    // Verify password
    const isValidPassword = await bcrypt.compare(password, patient.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Invalid email or password'
      });
    }

    // Generate JWT token
    const token = generateToken({
      id: patient.id,
      email: patient.email,
      type: 'patient'
    });

    res.json({
      message: 'Login successful',
      token,
      patient: {
        id: patient.id,
        firstName: patient.first_name,
        lastName: patient.last_name,
        email: patient.email,
        phone: patient.phone,
        classification: patient.classification,
        serialNumber: patient.serial_number,
        unitAssignment: patient.unit_assignment,
        createdAt: patient.created_at
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Login failed. Please try again.'
    });
  }
});

// POST /api/auth/admin/login - Admin login
router.post('/admin/login', [
  body('username').trim().isLength({ min: 3 }).withMessage('Username is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { username, password } = req.body;

    // Find admin by username
    const result = await query(
      `SELECT id, username, full_name, password_hash, role, is_active
       FROM admin_users WHERE username = $1 AND is_active = true`,
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: 'Invalid username or password'
      });
    }

    const admin = result.rows[0];

    // Verify password
    const isValidPassword = await bcrypt.compare(password, admin.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Invalid username or password'
      });
    }

    // Update last login
    await query(
      'UPDATE admin_users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
      [admin.id]
    );

    // Generate JWT token
    const token = generateToken({
      id: admin.id,
      username: admin.username,
      type: 'admin'
    });

    res.json({
      message: 'Admin login successful',
      token,
      admin: {
        id: admin.id,
        username: admin.username,
        fullName: admin.full_name,
        role: admin.role
      }
    });

  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({
      error: 'Login failed. Please try again.'
    });
  }
});

// Kiosk login endpoint
router.post('/kiosk/login', (req, res) => {
  const { username, password } = req.body;
  if (username === 'kiosk' && password === 'kiosk123') {
    return res.json({
      token: 'kiosk_token',
      user: { username: 'kiosk', type: 'kiosk' }
    });
  }
  return res.status(401).json({ error: 'Invalid kiosk credentials' });
});

module.exports = router; 