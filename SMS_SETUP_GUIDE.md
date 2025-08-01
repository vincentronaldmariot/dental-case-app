# 📱 SMS Setup Guide for Dental Case App

This guide will help you set up SMS notifications for patients using Twilio.

## 🚀 Prerequisites

1. **Twilio Account**: Sign up at [twilio.com](https://www.twilio.com)
2. **Verified Phone Number**: A Twilio phone number for sending SMS
3. **Environment Variables**: Access to set environment variables on Railway

## 📋 Step-by-Step Setup

### 1. Create Twilio Account

1. Go to [twilio.com](https://www.twilio.com) and sign up
2. Verify your email and phone number
3. Complete the account setup process

### 2. Get Twilio Credentials

1. **Account SID**: Found in your Twilio Console dashboard
   - Go to [Console](https://console.twilio.com/)
   - Copy your Account SID

2. **Auth Token**: Found in your Twilio Console dashboard
   - Go to [Console](https://console.twilio.com/)
   - Click "Show" next to your Auth Token
   - Copy the Auth Token

3. **Phone Number**: Purchase a Twilio phone number
   - Go to [Phone Numbers](https://console.twilio.com/us1/develop/phone-numbers/manage/active)
   - Click "Get a phone number"
   - Choose a number that supports SMS
   - Copy the phone number (format: +1234567890)

### 3. Configure Environment Variables

Add these environment variables to your Railway project:

```bash
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+1234567890
```

**Railway Setup:**
1. Go to your Railway project dashboard
2. Click on your service
3. Go to "Variables" tab
4. Add each environment variable:
   - `TWILIO_ACCOUNT_SID`: Your Twilio Account SID
   - `TWILIO_AUTH_TOKEN`: Your Twilio Auth Token
   - `TWILIO_PHONE_NUMBER`: Your Twilio phone number

### 4. Deploy the Changes

1. Install Twilio dependency:
   ```bash
   npm install twilio
   ```

2. Run the SMS migration:
   ```bash
   node backend/scripts/run_sms_migration.js
   ```

3. Deploy to Railway:
   ```bash
   git add .
   git commit -m "Add SMS functionality with Twilio"
   git push origin main
   ```

### 5. Test SMS Functionality

Run the SMS test script:
```bash
node test_sms_functionality.js
```

## 📱 SMS Features

### Supported SMS Types

1. **Appointment Reminders**
   - Sent 24 hours before appointment
   - Includes date, time, and arrival instructions

2. **Appointment Confirmations**
   - Sent when appointment is confirmed
   - Includes confirmation details

3. **Appointment Cancellations**
   - Sent when appointment is cancelled
   - Includes rescheduling instructions

4. **Emergency Notifications**
   - Sent when emergency status changes
   - Includes emergency type and status

5. **Treatment Updates**
   - Sent for treatment progress updates
   - Customizable messages

6. **Health Tips**
   - Periodic dental health tips
   - Educational content

### SMS Message Format

All SMS messages include:
- Personalized greeting with patient's first name
- Relevant information about the notification
- "Reply STOP to unsubscribe" footer
- Professional tone and clear instructions

### Phone Number Formatting

The system automatically formats phone numbers:
- **Philippines**: Converts `09123456789` to `+639123456789`
- **International**: Ensures proper `+` prefix
- **Validation**: Checks for valid phone number format

## 🔧 Configuration Options

### SMS Service Status

Check SMS service status via API:
```bash
GET /api/admin/sms-status
```

Response:
```json
{
  "smsStatus": {
    "configured": true,
    "accountSid": "Set",
    "authToken": "Set",
    "phoneNumber": "+1234567890"
  }
}
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `TWILIO_ACCOUNT_SID` | Twilio Account SID | Yes |
| `TWILIO_AUTH_TOKEN` | Twilio Auth Token | Yes |
| `TWILIO_PHONE_NUMBER` | Twilio phone number | Yes |

## 🛠️ Troubleshooting

### Common Issues

1. **SMS Not Sending**
   - Check environment variables are set correctly
   - Verify Twilio account has sufficient credits
   - Check phone number format

2. **Invalid Phone Number**
   - Ensure patient phone numbers are in correct format
   - Check for missing country codes

3. **Authentication Errors**
   - Verify Account SID and Auth Token
   - Check Twilio account status

4. **Rate Limiting**
   - Twilio has rate limits for SMS
   - Check Twilio console for limits

### Debug Commands

1. **Check SMS Status**:
   ```bash
   node test_sms_functionality.js
   ```

2. **Run Migration**:
   ```bash
   node backend/scripts/run_sms_migration.js
   ```

3. **Check Environment Variables**:
   ```bash
   echo $TWILIO_ACCOUNT_SID
   echo $TWILIO_AUTH_TOKEN
   echo $TWILIO_PHONE_NUMBER
   ```

## 💰 Cost Considerations

### Twilio Pricing (as of 2024)

- **SMS Cost**: ~$0.0079 per message (US)
- **Phone Number**: ~$1.00/month
- **Free Trial**: $15-20 credit for new accounts

### Cost Optimization

1. **Batch Notifications**: Group multiple updates
2. **Opt-out Management**: Respect STOP requests
3. **Message Length**: Keep messages concise
4. **Scheduling**: Send during business hours

## 🔒 Security & Privacy

### Data Protection

- Phone numbers are encrypted in database
- SMS content is logged for debugging only
- Patient consent required for SMS

### Compliance

- Follow local SMS regulations
- Include opt-out instructions
- Respect patient preferences
- Log all SMS activities

## 📞 Support

For SMS-related issues:

1. **Twilio Support**: [support.twilio.com](https://support.twilio.com)
2. **App Documentation**: Check this guide
3. **Logs**: Check Railway logs for errors
4. **Testing**: Use provided test scripts

## ✅ Verification Checklist

- [ ] Twilio account created
- [ ] Account SID obtained
- [ ] Auth Token obtained
- [ ] Phone number purchased
- [ ] Environment variables set
- [ ] Dependencies installed
- [ ] Migration run successfully
- [ ] SMS test passed
- [ ] Emergency notifications working
- [ ] Appointment notifications working

---

**Note**: SMS functionality requires a valid Twilio account and proper configuration. Without these, notifications will still work in-app but SMS will be disabled. 