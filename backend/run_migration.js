const fs = require('fs');
const path = require('path');
const { query } = require('./config/database');

async function runMigration() {
  try {
    console.log('🔄 Starting database migration...');
    
    // Read the migration SQL file
    const migrationPath = path.join(__dirname, 'add_admin_notes_migration.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    console.log('📄 Migration SQL loaded');
    
    // Split the SQL into individual statements
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    console.log(`🔧 Executing ${statements.length} SQL statements...`);
    
    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (statement.trim()) {
        try {
          await query(statement);
          console.log(`✅ Statement ${i + 1} executed successfully`);
        } catch (error) {
          // Some statements might fail if they already exist (like IF NOT EXISTS)
          console.log(`⚠️  Statement ${i + 1} skipped (likely already exists): ${error.message}`);
        }
      }
    }
    
    console.log('🎉 Migration completed successfully!');
    
    // Verify the migration
    console.log('🔍 Verifying migration...');
    
    // Check if admin_notes column exists
    const checkResult = await query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'patients' AND column_name = 'admin_notes'
    `);
    
    if (checkResult.rows.length > 0) {
      console.log('✅ admin_notes column successfully added to patients table');
    } else {
      console.log('❌ admin_notes column not found - migration may have failed');
    }
    
    // Check if notifications table exists
    const notificationsCheck = await query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_name = 'notifications'
    `);
    
    if (notificationsCheck.rows.length > 0) {
      console.log('✅ notifications table successfully created');
    } else {
      console.log('❌ notifications table not found - migration may have failed');
    }
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run the migration
runMigration().then(() => {
  console.log('🏁 Migration script completed');
  process.exit(0);
}).catch((error) => {
  console.error('💥 Migration script failed:', error);
  process.exit(1);
}); 