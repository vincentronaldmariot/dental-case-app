const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'dental_case_db',
  password: process.env.DB_PASSWORD || 'your_password',
  port: process.env.DB_PORT || 5432,
});

async function insertSampleEmergencyRecords() {
  try {
    console.log('🔧 Inserting sample emergency records...');

    // First, get some existing patient IDs
    const patientsResult = await pool.query(`
      SELECT id FROM patients 
      ORDER BY created_at DESC 
      LIMIT 3
    `);

    if (patientsResult.rows.length === 0) {
      console.log('❌ No patients found in database. Please create some patients first.');
      return;
    }

    const patientIds = patientsResult.rows.map(row => row.id);
    console.log(`📋 Found ${patientIds.length} patients: ${patientIds.join(', ')}`);

    // Sample emergency records
    const sampleRecords = [
      {
        patient_id: patientIds[0],
        emergency_type: 'severe_toothache',
        priority: 'urgent',
        status: 'resolved',
        description: 'Severe pain in upper right molar during night duty',
        pain_level: 8,
        symptoms: ['Severe pain', 'Sensitivity to cold', 'Throbbing'],
        location: 'Base Command Center',
        duty_related: true,
        unit_command: '1st Infantry Division',
        handled_by: 'Maj. Roberto Cruz, DDS',
        first_aid_provided: 'Ibuprofen 400mg, cold compress applied',
        resolved_at: new Date(Date.now() - 24 * 60 * 60 * 1000), // 1 day ago
        resolution: 'Root canal therapy completed. Temporary crown placed.',
        follow_up_required: 'Permanent crown placement in 2 weeks',
        emergency_contact: '(02) 8234-5678',
        notes: 'Patient responded well to treatment'
      },
      {
        patient_id: patientIds[1] || patientIds[0],
        emergency_type: 'dental_trauma',
        priority: 'immediate',
        status: 'in_progress',
        description: 'Dental trauma from training accident - fractured central incisor',
        pain_level: 7,
        symptoms: ['Fractured tooth', 'Bleeding', 'Lip laceration'],
        location: 'Training Ground Alpha',
        duty_related: true,
        unit_command: 'Special Forces Group',
        handled_by: 'Col. Maria Santos, DDS',
        first_aid_provided: 'Bleeding controlled, ice pack applied, tooth fragment saved',
        emergency_contact: '(02) 8123-4567',
        notes: 'Patient conscious and stable. X-rays show no root fracture.'
      },
      {
        patient_id: patientIds[2] || patientIds[0],
        emergency_type: 'lost_crown',
        priority: 'standard',
        status: 'resolved',
        description: 'Crown came off while eating during mess hall dinner',
        pain_level: 3,
        symptoms: ['Exposed tooth', 'Mild sensitivity'],
        location: 'Base Mess Hall',
        duty_related: false,
        handled_by: 'Capt. Ana Rodriguez, DDS',
        first_aid_provided: 'Temporary cement applied to crown',
        resolved_at: new Date(Date.now() - 12 * 60 * 60 * 1000), // 12 hours ago
        resolution: 'Crown re-cemented successfully',
        emergency_contact: '(02) 8456-7890',
        notes: 'Patient should avoid sticky foods for 24 hours'
      }
    ];

    for (const record of sampleRecords) {
      const insertQuery = `
        INSERT INTO emergency_records (
          patient_id, emergency_type, priority, status, description,
          pain_level, symptoms, location, duty_related, unit_command,
          handled_by, first_aid_provided, resolved_at, resolution,
          follow_up_required, emergency_contact, notes, reported_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
        RETURNING id, patient_id, emergency_type, status
      `;

      const values = [
        record.patient_id,
        record.emergency_type,
        record.priority,
        record.status,
        record.description,
        record.pain_level,
        record.symptoms,
        record.location,
        record.duty_related,
        record.unit_command,
        record.handled_by,
        record.first_aid_provided,
        record.resolved_at,
        record.resolution,
        record.follow_up_required,
        record.emergency_contact,
        record.notes,
        record.resolved_at ? new Date(record.resolved_at.getTime() - 6 * 60 * 60 * 1000) : new Date() // reported 6 hours before resolved
      ];

      const result = await pool.query(insertQuery, values);
      console.log(`✅ Inserted emergency record: ${result.rows[0].id} for patient ${result.rows[0].patient_id}`);
    }

    // Check total emergency records
    const countResult = await pool.query('SELECT COUNT(*) as count FROM emergency_records');
    console.log(`📊 Total emergency records in database: ${countResult.rows[0].count}`);

    // Show all emergency records
    const allRecords = await pool.query(`
      SELECT er.id, er.emergency_type, er.status, er.priority, 
             p.first_name, p.last_name
      FROM emergency_records er
      LEFT JOIN patients p ON er.patient_id = p.id
      ORDER BY er.reported_at DESC
    `);

    console.log('📋 All emergency records:');
    allRecords.rows.forEach((record, index) => {
      console.log(`${index + 1}. ID: ${record.id} | Type: ${record.emergency_type} | Status: ${record.status} | Priority: ${record.priority} | Patient: ${record.first_name} ${record.last_name}`);
    });

  } catch (error) {
    console.error('❌ Error inserting sample emergency records:', error);
  } finally {
    await pool.end();
  }
}

insertSampleEmergencyRecords(); 