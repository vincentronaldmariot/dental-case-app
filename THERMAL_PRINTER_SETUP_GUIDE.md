# Thermal Printer Setup Guide for Dental Kiosk

## Overview
This guide explains how to set up and use a 58mm POS Bluetooth thermal printer with your dental clinic kiosk application.

## Compatible Printers
- **58mm POS Bluetooth Thermal Printers** (like the one from [Shopee](https://shopee.ph/58MM-POS-Printer-Bluetooth-USB-Thermal-Receipt-printers-for-Supermarket-Convenience-store-Milk-tea-shop-Takeaway-order-i.1020))
- **Any ESC/POS compatible thermal printer**
- **Bluetooth-enabled thermal printers**

## Setup Instructions

### 1. Printer Setup
1. **Power on your thermal printer**
2. **Insert thermal paper** (58mm width)
3. **Turn on Bluetooth** on the printer (if applicable)
4. **Note the printer name** for pairing

### 2. Device Pairing
1. **Enable Bluetooth** on your Android device/tablet
2. **Go to Bluetooth settings**
3. **Scan for devices** and find your thermal printer
4. **Pair the device** (usually no password required)
5. **Note the paired device name**

### 3. App Configuration
1. **Open the dental kiosk app**
2. **Click the orange printer icon** in the top-right corner
3. **This opens the Thermal Printer Test screen**
4. **Click "Refresh Devices"** to scan for paired printers
5. **Select your thermal printer** from the list
6. **Click "Connect"** to establish connection
7. **Test the connection** by clicking "Print Test"

## Using the Thermal Printer

### In Kiosk Mode
1. **Complete the dental survey** as a patient
2. **Review the receipt** on the screen
3. **Choose print option:**
   - **"Print PDF"** - For PDF receipt
   - **"Thermal Print"** - For thermal printer
4. **Click "Thermal Print"** for your 58mm printer
5. **Check the printer output** for the receipt

### Features
- **Automatic connection** to paired thermal printers
- **Real-time status** showing connection state
- **Error handling** with helpful messages
- **Test printing** functionality
- **Proper ESC/POS formatting** for thermal paper

## Troubleshooting

### Common Issues

#### "No Bluetooth devices found"
- Ensure Bluetooth is enabled on your device
- Make sure the thermal printer is paired
- Try refreshing the device list

#### "Failed to connect to thermal printer"
- Check if the printer is turned on
- Verify the printer is in pairing mode
- Try disconnecting and reconnecting
- Restart both the app and printer

#### "Print failed"
- Check if thermal paper is loaded
- Ensure the printer is not out of paper
- Verify the connection is still active
- Try printing a test receipt first

#### "Permissions required"
- Grant Bluetooth permissions when prompted
- Go to device settings if permissions are denied
- Enable location services (required for Bluetooth scanning)

### Printer-Specific Issues

#### Paper not feeding
- Check paper alignment
- Ensure paper is properly loaded
- Clean the paper feed mechanism

#### Poor print quality
- Clean the print head
- Check paper quality
- Adjust print density if available

#### Connection drops
- Keep devices within 10 meters
- Avoid interference from other Bluetooth devices
- Check battery level on portable printers

## Technical Details

### ESC/POS Commands Used
- **Font formatting** (bold, size, alignment)
- **Paper feed** and cut commands
- **Character encoding** for proper text display
- **Receipt layout** optimized for 58mm paper

### Bluetooth Implementation
- **Automatic device discovery**
- **Connection management**
- **Error handling** and recovery
- **Permission management**

### Receipt Format
- **Header** with clinic name and receipt number
- **Patient information** section
- **Survey results** with total score
- **Questions and answers** (limited to fit paper width)
- **Footer** with thank you message
- **QR code** for digital record access

## Advanced Configuration

### Customizing Receipt Layout
The receipt format can be customized in `lib/services/thermal_print_service.dart`:
- Modify the `_createThermalReceiptContent` method
- Adjust text formatting and layout
- Add custom headers or footers
- Change paper width settings

### Adding New Printer Models
To support additional printer models:
1. **Test compatibility** with ESC/POS commands
2. **Adjust formatting** for different paper widths
3. **Update connection logic** if needed
4. **Add printer-specific settings**

## Support

### Getting Help
- **Check the troubleshooting section** above
- **Use the test screen** to diagnose issues
- **Verify printer compatibility** with ESC/POS
- **Test with different thermal paper** if needed

### Contact Information
For technical support with the thermal printer integration:
- Check the app's error messages
- Review the console logs for detailed information
- Test with the built-in test functionality

## Future Enhancements
- **Multiple printer support**
- **Print queue management**
- **Custom receipt templates**
- **Print history tracking**
- **QR code printing** on thermal receipts 