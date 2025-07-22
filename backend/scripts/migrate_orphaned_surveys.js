const { Pool } = require('pg');

const pool = new Pool({
  user: 'dental_user',
  host: 'localhost',
  database: 'dental_case_db',
  password: 'dental_password',
  port: 5432,
});

async function migrateOrphanedSurveys() {
  try {
    // 1. Get all patient UUIDs
    const patientsRes = await pool.query('SELECT id, email FROM patients');
    const patientMap = {};
    for (const row of patientsRes.rows) {
      patientMap[row.email] = row.id;
    }

    // 2. Find all surveys where patient_id does not match any real patient
    const orphanedRes = await pool.query(`
      SELECT id, patient_id, survey_data FROM dental_surveys
      WHERE patient_id NOT IN (SELECT id FROM patients)
    `);
    let migrated = 0;
    for (const row of orphanedRes.rows) {
      let email = null;
      try {
        const data = typeof row.survey_data === 'string' ? JSON.parse(row.survey_data) : row.survey_data;
        email = data?.patient_info?.email;
      } catch (e) {
        console.error('Failed to parse survey_data for survey', row.id);
        continue;
      }
      if (!email) {
        console.log(`No email found in survey_data for survey ${row.id}`);
        continue;
      }
      const patientId = patientMap[email];
      if (!patientId) {
        console.log(`No patient found for email ${email} (survey ${row.id})`);
        continue;
      }
      // 3. Update the survey's patient_id
      await pool.query(
        'UPDATE dental_surveys SET patient_id = $1 WHERE id = $2',
        [patientId, row.id]
      );
      console.log(`Migrated orphaned survey ${row.id} to patient ${patientId}`);
      migrated++;
    }
    console.log(`Migration complete. Migrated ${migrated} orphaned surveys.`);
  } catch (err) {
    console.error('Migration error:', err);
  } finally {
    await pool.end();
  }
}

migrateOrphanedSurveys(); 