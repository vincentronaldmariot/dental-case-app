const { query } = require('./backend/config/database');

async function checkAppointmentsTable() {
  try {
    console.log('🔍 Checking appointments table structure...');
    
    // Get table structure
    const structureResult = await query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'appointments'
      ORDER BY ordinal_position
    `);
    
    console.log('📊 Appointments table columns:');
    structureResult.rows.forEach(row => {
      console.log(`  - ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
    // Check if there are any appointments
    const countResult = await query(`
      SELECT COUNT(*) as count FROM appointments
    `);
    
    console.log(`📊 Total appointments: ${countResult.rows[0].count}`);
    
    if (countResult.rows[0].count > 0) {
      // Show sample data
      const sampleResult = await query(`
        SELECT * FROM appointments LIMIT 3
      `);
      
      console.log('📊 Sample appointment data:');
      sampleResult.rows.forEach((row, index) => {
        console.log(`  Appointment ${index + 1}:`, row);
      });
    }
    
  } catch (error) {
    console.error('❌ Error checking appointments table:', error);
  }
}

checkAppointmentsTable(); 