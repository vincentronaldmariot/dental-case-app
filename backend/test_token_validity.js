const jwt = require('jsonwebtoken');

function testTokenValidity() {
  try {
    console.log('🔍 Testing token validity...');
    
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjQ1Zjc4NGE0LWVjZDQtNDlkMS1hOGQwLTkwOWIyNWQyYjAzZSIsImVtYWlsIjoidmluY2VudEBnbWFpbC5jb20iLCJ0eXBlIjoicGF0aWVudCIsImlhdCI6MTc1MzA0Mzc2MSwiZXhwIjoxNzUzNjQ4NTYxfQ.gZ0dbtkj13RHB7d-2KsTPP0BTAbMTamtIuorv-VxWsI';
    
    // Decode the token without verification first
    const decoded = jwt.decode(token);
    console.log('Token payload:', JSON.stringify(decoded, null, 2));
    
    // Check if token is expired
    const now = Math.floor(Date.now() / 1000);
    const exp = decoded.exp;
    const iat = decoded.iat;
    
    console.log('Current time:', now);
    console.log('Token issued at:', iat);
    console.log('Token expires at:', exp);
    console.log('Token is expired:', now > exp);
    console.log('Token age (hours):', (now - iat) / 3600);
    console.log('Time until expiry (hours):', (exp - now) / 3600);
    
    // Try to verify the token
    try {
      const verified = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
      console.log('✅ Token is valid');
      console.log('Verified payload:', JSON.stringify(verified, null, 2));
    } catch (verifyError) {
      console.log('❌ Token verification failed:', verifyError.message);
    }
    
  } catch (error) {
    console.error('❌ Error testing token:', error);
  }
}

testTokenValidity(); 