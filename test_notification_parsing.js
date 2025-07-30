// Test the notification message parsing logic
function testNotificationParsing() {
  console.log('🔍 Testing notification message parsing...');
  
  const testMessages = [
    "Your appointment for Teeth Whitening on 8/1/2025 at 08:00 AM has been approved! Please arrive 10 minutes before your scheduled time.",
    "Your appointment for Teeth Cleaning on 7/31/2025 at 08:00 AM has been approved! Please arrive 10 minutes before your scheduled time.",
    "Your appointment for Root Canal on 7/31/2025 at 08:00 AM has been approved! Please arrive 10 minutes before your scheduled time.",
    "Your appointment for Teeth Cleaning on 7/31/2025 at 12:00 has been approved! Please arrive 10 minutes before your scheduled time."
  ];
  
  testMessages.forEach((message, index) => {
    console.log(`\n📋 Test message ${index + 1}: "${message}"`);
    
    // Parse using the same logic as Dart
    const serviceRegex = /for (.+?) on/;
    const dateRegex = /on (\d{1,2}\/\d{1,2}\/\d{4})/;
    const timeRegex = /at (\d{1,2}:\d{2} [AP]M)/;
    
    const serviceMatch = message.match(serviceRegex);
    const dateMatch = message.match(dateRegex);
    const timeMatch = message.match(timeRegex);
    
    if (serviceMatch && dateMatch) {
      const service = serviceMatch[1];
      const dateStr = dateMatch[1];
      const timeSlot = timeMatch ? timeMatch[1] : '';
      
      console.log(`✅ Parsed: Service="${service}", Date="${dateStr}", Time="${timeSlot}"`);
    } else {
      console.log('❌ Failed to parse message');
    }
  });
}

testNotificationParsing(); 