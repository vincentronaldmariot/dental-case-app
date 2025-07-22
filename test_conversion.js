// Test the conversion logic from new format to old format
const testConversion = () => {
  // Sample new format data (from the debug output)
  const newFormatData = {
    tooth_pain: false,
    patient_info: {
      name: "VINCENT RONALD UNAY MARIOT",
      email: "vincent@gmail.com",
      last_visit: "june 29",
      serial_number: "",
      classification: "Others",
      contact_number: "09567765902",
      emergency_phone: "09123456789",
      unit_assignment: "",
      emergency_contact: "VERONICA MARIOT",
      other_classification: "family member"
    },
    submitted_at: "2025-07-20T18:19:49.810Z",
    tartar_level: "NONE",
    need_dentures: false,
    tooth_sensitive: true,
    damaged_fillings: {
      broken_pasta: true,
      broken_tooth: false
    },
    tooth_conditions: {
      decayed_tooth: false,
      impacted_tooth: true,
      worn_down_tooth: false
    },
    has_missing_teeth: false,
    missing_tooth_conditions: {
      missing_broken_pasta: null,
      missing_broken_tooth: null
    }
  };

  console.log('🔄 Testing conversion from new format to old format...\n');
  console.log('📊 New format data:');
  console.log(JSON.stringify(newFormatData, null, 2));
  console.log('\n');

  // Simulate the conversion logic
  const convertNewToOldFormat = (newFormatData) => {
    const oldFormat = {};
    
    // Question 1: Do you have any of the ones shown in the pictures?
    const toothConditions = newFormatData.tooth_conditions || {};
    const hasToothConditions = (toothConditions.decayed_tooth === true || 
                               toothConditions.impacted_tooth === true || 
                               toothConditions.worn_down_tooth === true);
    oldFormat.question1 = hasToothConditions ? 'Yes' : 'No';
    
    // Question 2: Do you have tartar/calculus deposits or rough feeling teeth like in the images?
    const tartarLevel = (newFormatData.tartar_level || 'NONE').toUpperCase();
    oldFormat.question2 = (tartarLevel === 'LIGHT' || tartarLevel === 'MODERATE' || tartarLevel === 'HEAVY') ? 'Yes' : 'No';
    
    // Question 3: Do your teeth feel sensitive to hot, cold, or sweet foods?
    oldFormat.question3 = (newFormatData.tooth_sensitive === true) ? 'Yes' : 'No';
    
    // Question 4: Do you experience tooth pain?
    oldFormat.question4 = (newFormatData.tooth_pain === true) ? 'Yes' : 'No';
    
    // Question 5: Do you have damaged or broken fillings like those shown in the pictures?
    const damagedFillings = newFormatData.damaged_fillings || {};
    const hasDamagedFillings = (damagedFillings.broken_pasta === true || 
                               damagedFillings.broken_tooth === true);
    oldFormat.question5 = hasDamagedFillings ? 'Yes' : 'No';
    
    // Question 6: Do you need to get dentures (false teeth)?
    oldFormat.question6 = (newFormatData.need_dentures === true) ? 'Yes' : 'No';
    
    // Question 7: Do you have missing or extracted teeth?
    oldFormat.question7 = (newFormatData.has_missing_teeth === true) ? 'Yes' : 'No';
    
    // Question 8: When was your last dental visit at a Dental Treatment Facility?
    const patientInfo = newFormatData.patient_info || {};
    const lastVisit = patientInfo.last_visit || 'Unknown';
    oldFormat.question8 = lastVisit;
    
    return oldFormat;
  };

  const oldFormat = convertNewToOldFormat(newFormatData);
  
  console.log('✅ Converted old format data:');
  console.log(JSON.stringify(oldFormat, null, 2));
  console.log('\n');
  
  console.log('📋 Question mapping summary:');
  console.log(`Question 1 (Tooth problems): ${oldFormat.question1} (from tooth_conditions: ${JSON.stringify(newFormatData.tooth_conditions)})`);
  console.log(`Question 2 (Tartar): ${oldFormat.question2} (from tartar_level: ${newFormatData.tartar_level})`);
  console.log(`Question 3 (Sensitivity): ${oldFormat.question3} (from tooth_sensitive: ${newFormatData.tooth_sensitive})`);
  console.log(`Question 4 (Pain): ${oldFormat.question4} (from tooth_pain: ${newFormatData.tooth_pain})`);
  console.log(`Question 5 (Damaged fillings): ${oldFormat.question5} (from damaged_fillings: ${JSON.stringify(newFormatData.damaged_fillings)})`);
  console.log(`Question 6 (Dentures): ${oldFormat.question6} (from need_dentures: ${newFormatData.need_dentures})`);
  console.log(`Question 7 (Missing teeth): ${oldFormat.question7} (from has_missing_teeth: ${newFormatData.has_missing_teeth})`);
  console.log(`Question 8 (Last visit): ${oldFormat.question8} (from patient_info.last_visit: ${newFormatData.patient_info.last_visit})`);
};

testConversion(); 