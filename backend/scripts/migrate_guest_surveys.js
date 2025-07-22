const { Pool } = require('pg');

const pool = new Pool({
  user: 'dental_user',
  host: 'localhost',
  database: 'dental_case_db',
  password: 'dental_password',
  port: 5432,
});

function isUUID(str) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);
}

async function migrateGuestSurveys() {
  try {
    // 1. Get all surveys where patient_id = 'guest' (string, not uuid)
    const guestSurveys = await pool.query(
      `SELECT id, survey_data FROM dental_surveys WHERE patient_id = 'guest'`
    );
    let migrated = 0;
    for (const row of guestSurveys.rows) {
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
      // 2. Find patient with this email
      const patientRes = await pool.query(
        'SELECT id FROM patients WHERE email = $1',
        [email]
      );
      if (patientRes.rows.length === 0) {
        console.log(`No patient found for email ${email} (survey ${row.id})`);
        continue;
      }
      const patientId = patientRes.rows[0].id;
      if (!isUUID(patientId)) {
        console.log(`Patient ID ${patientId} is not a valid UUID, skipping.`);
        continue;
      }
      // 3. Update the survey's patient_id
      await pool.query(
        'UPDATE dental_surveys SET patient_id = $1 WHERE id = $2',
        [patientId, row.id]
      );
      console.log(`Migrated survey ${row.id} to patient ${patientId}`);
      migrated++;
    }
    // 4. Delete all surveys where patient_id = 'guest' (invalid uuid)
    const deleteRes = await pool.query(
      `DELETE FROM dental_surveys WHERE patient_id = 'guest'`
    );
    console.log(`Deleted ${deleteRes.rowCount} surveys with patient_id = 'guest'.`);
    console.log(`Migration complete. Migrated ${migrated} surveys.`);
  } catch (err) {
    console.error('Migration error:', err);
  } finally {
    await pool.end();
  }
}

migrateGuestSurveys(); 