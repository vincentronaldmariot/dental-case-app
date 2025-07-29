const bcrypt = require('bcrypt');

// In-memory database for testing
const memoryDB = {
  admin_users: [
    {
      id: '1',
      username: 'admin',
      password_hash: '$2a$12$BVFpl6gpwYa2WSqxsPBkcenuCv0/2rudS/iTwFc/JByWsTm9TK/SW', // admin123
      full_name: 'System Administrator',
      role: 'admin',
      is_active: true,
      last_login: null,
      created_at: new Date(),
      updated_at: new Date()
    }
  ],
  patients: [
    {
      id: '1',
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@test.com',
      phone: '123-456-7890',
      password_hash: '$2a$12$t.6BNcyeGG7bfRpu9eEqH.DlX9YL71KpQFdwy.ezdQeaHDLKmvyD6', // patient123
      date_of_birth: '1990-01-15',
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '2',
      first_name: 'Jane',
      last_name: 'Smith',
      email: 'jane.smith@test.com',
      phone: '234-567-8901',
      password_hash: '$2a$12$t.6BNcyeGG7bfRpu9eEqH.DlX9YL71KpQFdwy.ezdQeaHDLKmvyD6', // patient123
      date_of_birth: '1985-05-20',
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '3',
      first_name: 'VIP',
      last_name: 'Person',
      email: 'vip.person@test.com',
      phone: '345-678-9012',
      password_hash: '$2a$12$k1dum.4ZlQhY1CxoecG/KeOMG6uZLB0Be7X2YTf/J8JBBqnHHFQ9a', // vip123
      date_of_birth: '1980-12-10',
      created_at: new Date(),
      updated_at: new Date()
    }
  ],
  appointments: [],
  dental_surveys: []
};

// Test connection
async function testConnection() {
  console.log('📊 Connected to in-memory database successfully');
  console.log('🕒 Database time:', new Date().toISOString());
  return true;
}

// Execute a query with error handling
async function query(text, params) {
  const start = Date.now();
  try {
    let result;
    
    // Ensure params is always an array
    const queryParams = params || [];
    
    // Debug: Log the query to see what we're dealing with
    console.log('🔍 Debug - Query text:', text.substring(0, 100) + (text.length > 100 ? '...' : ''));
    console.log('🔍 Debug - Query includes appointments:', text.includes('appointments'));
    console.log('🔍 Debug - Query includes JOIN:', text.includes('JOIN'));
    console.log('🔍 Debug - Query includes pending:', text.includes('pending'));
    console.log('🔍 Debug - Query params:', queryParams);
    
    // Parse the query to determine what to do
    if (text.includes('SELECT') && text.includes('admin_users') && text.includes('username')) {
      // Admin login query
      const username = queryParams[0];
      const admin = memoryDB.admin_users.find(u => u.username === username && u.is_active);
      result = { rows: admin ? [admin] : [], rowCount: admin ? 1 : 0 };
    } else if (text.includes('SELECT') && text.includes('patients') && text.includes('email')) {
      // Patient login query
      const email = queryParams[0];
      const patient = memoryDB.patients.find(p => p.email === email);
      result = { rows: patient ? [patient] : [], rowCount: patient ? 1 : 0 };
    } else if (text.includes('UPDATE') && text.includes('admin_users') && text.includes('last_login')) {
      // Update last login
      const adminId = queryParams[0];
      const admin = memoryDB.admin_users.find(u => u.id === adminId);
      if (admin) {
        admin.last_login = new Date();
      }
      result = { rows: [], rowCount: 1 };
    } else if (text.includes('INSERT') && text.includes('admin_users')) {
      // Insert admin user
      const newAdmin = {
        id: Date.now().toString(),
        username: queryParams[0],
        password_hash: queryParams[1],
        full_name: queryParams[2],
        role: queryParams[3],
        is_active: true,
        last_login: null,
        created_at: new Date(),
        updated_at: new Date()
      };
      memoryDB.admin_users.push(newAdmin);
      result = { rows: [newAdmin], rowCount: 1 };
    } else if (text.includes('INSERT') && text.includes('patients')) {
      // Insert patient
      const newPatient = {
        id: Date.now().toString(),
        first_name: queryParams[0],
        last_name: queryParams[1],
        email: queryParams[2],
        phone: queryParams[3],
        password_hash: queryParams[4],
        date_of_birth: queryParams[5],
        created_at: new Date(),
        updated_at: new Date()
      };
      memoryDB.patients.push(newPatient);
      result = { rows: [newPatient], rowCount: 1 };
    } else if (text.includes('appointments') && text.includes('JOIN') && text.includes('patients') && text.includes('pending')) {
      // Pending appointments query with JOIN
      console.log('🔍 Debug - Matched pending appointments query');
      const pendingAppointments = memoryDB.appointments
        .filter(apt => apt.status === 'pending')
        .map(apt => {
          const patient = memoryDB.patients.find(p => p.id === apt.patient_id);
          const survey = memoryDB.dental_surveys.find(s => s.patient_id === apt.patient_id);
          
          return {
            appointment_id: apt.id,
            service: apt.service,
            booking_date: apt.appointment_date,
            time_slot: apt.time_slot,
            status: apt.status,
            first_name: patient?.first_name || 'Unknown',
            last_name: patient?.last_name || 'Patient',
            email: patient?.email || '',
            phone: patient?.phone || '',
            classification: patient?.classification || '',
            unit_assignment: patient?.unit_assignment || '',
            serial_number: patient?.serial_number || '',
            survey_data: survey?.survey_data || null
          };
        });
      result = { rows: pendingAppointments, rowCount: pendingAppointments.length };
    } else {
      // Default empty result
      console.log('🔍 Debug - No pattern matched, using default empty result');
      result = { rows: [], rowCount: 0 };
    }
    
    const duration = Date.now() - start;
    console.log('📊 Query executed:', {
      text: text.substring(0, 50) + (text.length > 50 ? '...' : ''),
      duration,
      rows: result.rowCount
    });
    return result;
  } catch (error) {
    console.error('❌ Query error:', {
      text: text.substring(0, 50) + (text.length > 50 ? '...' : ''),
      error: error.message
    });
    throw error;
  }
}

// Close the pool (no-op for in-memory)
async function closePool() {
  console.log('🔌 In-memory database pool closed');
}

module.exports = {
  query,
  testConnection,
  closePool
};