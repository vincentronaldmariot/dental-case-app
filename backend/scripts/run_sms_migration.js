const { query } = require('../config/database');
const fs = require('fs');
const path = require('path');

async function runSMSMigration() {
  try {
    console.log('🔧 Running SMS migration for notifications table...');

    // Read the migration SQL file
    const migrationPath = path.join(__dirname, '../migrations/add_sms_columns_to_notifications.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    // Split the SQL into individual statements
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0);

    // Execute each statement
    for (const statement of statements) {
      if (statement.trim()) {
        console.log(`📝 Executing: ${statement.substring(0, 50)}...`);
        await query(statement);
      }
    }

    console.log('✅ SMS migration completed successfully');

    // Verify the migration
    console.log('🔍 Verifying migration...');
    const result = await query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'notifications'
      AND column_name IN ('sms_sent', 'sms_message_id', 'updated_at')
      ORDER BY column_name
    `);

    console.log('📊 Migration verification results:');
    result.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });

    // Check indexes
    const indexResult = await query(`
      SELECT indexname, indexdef
      FROM pg_indexes
      WHERE tablename = 'notifications'
      AND indexname LIKE 'idx_notifications_%'
    `);

    console.log('📊 Created indexes:');
    indexResult.rows.forEach(row => {
      console.log(`   - ${row.indexname}`);
    });

  } catch (error) {
    console.error('❌ SMS migration failed:', error);
    process.exit(1);
  }
}

// Run the migration
runSMSMigration(); 