const express = require('express');
const { query } = require('../config/database');
const { verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/emergency-admin - Get all emergency records for admin
router.get('/', verifyAdmin, async (req, res) => {
  try {
    console.log('🔍 Admin fetching all emergency records...');
    
    const queryText = `
      SELECT 
        er.id, 
        er.patient_id, 
        er.reported_at, 
        er.emergency_type, 
        er.description,
        COALESCE(er.status, 'reported') as status,
        COALESCE(er.priority, 'standard') as priority,
        COALESCE(er.pain_level, 0) as pain_level,
        er.handled_by, 
        er.resolution, 
        er.follow_up_required, 
        er.resolved_at,
        er.emergency_contact, 
        er.notes, 
        er.created_at,
        p.first_name, 
        p.last_name, 
        p.email, 
        p.phone
      FROM emergency_records er
      LEFT JOIN patients p ON er.patient_id = p.id
      ORDER BY er.reported_at DESC
    `;

    const result = await query(queryText);
    console.log(`📊 Found ${result.rows.length} emergency records`);

    const emergencyRecords = result.rows.map(record => ({
      id: record.id,
      patientId: record.patient_id,
      patientName: `${record.first_name || ''} ${record.last_name || ''}`.trim() || 'Unknown Patient',
      patientEmail: record.email || '',
      patientPhone: record.phone || '',
      reportedAt: record.reported_at,
      emergencyType: record.emergency_type || 'unknown',
      description: record.description || '',
      painLevel: record.pain_level || 0,
      status: record.status || 'reported',
      priority: record.priority || 'standard',
      handledBy: record.handled_by || '',
      resolution: record.resolution || '',
      followUpRequired: record.follow_up_required || '',
      resolvedAt: record.resolved_at,
      emergencyContact: record.emergency_contact || '',
      notes: record.notes || '',
      resolved: record.status === 'resolved',
      createdAt: record.created_at
    }));

    console.log('✅ Emergency records processed successfully');
    res.json(emergencyRecords);

  } catch (error) {
    console.error('❌ Error fetching emergency records:', error);
    res.status(500).json({
      error: 'Failed to retrieve emergency records. Please try again.',
      details: error.message
    });
  }
});

// PUT /api/emergency-admin/:id/status - Update emergency status for admin
router.put('/:id/status', verifyAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    
    console.log(`🔄 Admin updating emergency ${id} status to ${status}`);
    
    const queryText = `
      UPDATE emergency_records 
      SET status = $1, notes = COALESCE($2, notes), updated_at = NOW()
      WHERE id = $3
      RETURNING *
    `;
    
    const result = await query(queryText, [status, notes, id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Emergency record not found' });
    }
    
    console.log('✅ Emergency status updated successfully');
    res.json({ 
      message: 'Emergency status updated successfully',
      emergency: result.rows[0]
    });
    
  } catch (error) {
    console.error('❌ Error updating emergency status:', error);
    res.status(500).json({
      error: 'Failed to update emergency status. Please try again.',
      details: error.message
    });
  }
});

module.exports = router; 