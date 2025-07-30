const { query } = require('./backend/config/database');

async function checkTableConstraints() {
  try {
    console.log('🔍 Checking dental_surveys table constraints...');
    
    // Check foreign key constraints
    const constraints = await query(`
      SELECT 
        tc.constraint_name,
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'dental_surveys';
    `);
    
    console.log('📋 Foreign key constraints:');
    constraints.rows.forEach(row => {
      console.log(`   ${row.constraint_name}: ${row.table_name}.${row.column_name} -> ${row.foreign_table_name}.${row.foreign_column_name}`);
    });
    
    // Check if kiosk patient exists
    const kioskPatient = await query(`
      SELECT id, first_name, last_name FROM patients 
      WHERE id = '00000000-0000-0000-0000-000000000000'
    `);
    
    if (kioskPatient.rows.length > 0) {
      console.log('✅ Kiosk patient exists:', kioskPatient.rows[0]);
    } else {
      console.log('❌ Kiosk patient does not exist');
      console.log('🔧 Creating kiosk patient...');
      
      await query(`
        INSERT INTO patients (
          id, first_name, last_name, email, phone, password_hash, 
          date_of_birth, address, emergency_contact, emergency_phone
        ) VALUES (
          '00000000-0000-0000-0000-000000000000',
          'Kiosk',
          'User',
          'kiosk@dental.app',
          '00000000000',
          'kiosk_hash',
          '2000-01-01',
          'Kiosk Location',
          'Kiosk Emergency',
          '00000000000'
        )
      `);
      
      console.log('✅ Kiosk patient created');
    }
    
  } catch (error) {
    console.error('❌ Error checking constraints:', error);
  }
}

checkTableConstraints()
  .then(() => {
    console.log('\n✅ Constraint check completed');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Constraint check failed:', error);
    process.exit(1);
  }); 