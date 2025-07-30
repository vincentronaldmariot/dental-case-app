# Bluetooth Thermal Printer Setup Guide

## Overview
The dental kiosk app now supports **Bluetooth thermal printing** for 58mm thermal printers. The orange "Thermal Print" button on the receipt screen will connect to your paired thermal printer and print receipts automatically.

## Supported Printers
- **58mm POS Bluetooth Thermal Printers**
- Compatible with most thermal printers that support Bluetooth connectivity
- Recommended: POS-58 thermal printers commonly available online

## Setup Instructions

### 1. Hardware Setup
1. **Power on your thermal printer**
2. **Insert thermal paper** (58mm width)
3. **Turn on Bluetooth** on the printer (if applicable)
4. **Ensure printer is in pairing mode**

### 2. Device Pairing
1. **Enable Bluetooth** on your device (phone/tablet/computer)
2. **Go to Bluetooth settings**
3. **Scan for devices** and find your thermal printer
4. **Pair with the printer** (usually no password required)
5. **Note the printer name** for future reference

### 3. App Configuration
The app will automatically:
- **Connect to the printer** automatically if only one is available
- **Show a selection dialog** if multiple printers are paired

## Using the Thermal Printer

### In Kiosk Mode
1. **Complete the dental survey** for a patient
2. **On the receipt screen**, you'll see two print buttons:
   - **"Print PDF"** (Blue button) - For standard printing
   - **"Thermal Print"** (Orange button) - For thermal printer
3. **Click "Thermal Print"** for your 58mm printer
4. **The app will automatically connect** to your paired printer
5. **Receipt will print automatically** with patient information

### Receipt Content
The thermal receipt includes:
- Dental clinic header
- Receipt number and daily counter
- Patient information (name, serial number, unit, classification, contact)
- Timestamp
- Instructions for the patient
- Thank you message

## Troubleshooting

### "No paired Bluetooth devices found"
- Ensure your printer is turned on
- Re-pair the printer in Bluetooth settings
- Restart both the printer and your device

### "Failed to connect to thermal printer"
- Check if the printer is within range (usually 10 meters)
- Ensure the printer is not connected to another device
- Try disconnecting and reconnecting the printer
- Restart the printer

### "Print failed" or "No paper"
- Check if the printer has enough paper
- Try printing a test page from printer settings
- Ensure the printer is not jammed

### "Printer not responding"
- Check if the printer is overheating
- Restart the printer
- Ensure the printer is not in sleep mode

## Printer Maintenance

### Regular Maintenance
1. **Clean the print head** regularly with a soft cloth
2. **Keep the printer in a cool, dry place**
3. **Replace thermal paper** when running low
4. **Check for paper jams** periodically

### Paper Requirements
- **Width**: 58mm (2.28 inches)
- **Type**: Thermal paper (no ink required)
- **Length**: Standard roll (typically 30-50 meters)

## Testing the Printer

### Test File
Run the test file to verify printer functionality:
```bash
flutter run test_thermal_print.dart
```

### Test Features
- **Check paired devices**
- **Test connection status**
- **Print sample receipt**
- **Verify printer communication**

## Technical Details

### Bluetooth Requirements
- **Bluetooth 2.0 or higher**
- **Classic Bluetooth** (not BLE)
- **SPP (Serial Port Profile)** support

### Supported Platforms
- **Android**: Full support
- **iOS**: Limited support (may require additional permissions)
- **Windows**: Full support
- **macOS**: Full support

### Error Handling
The app includes comprehensive error handling:
- **Connection failures** show helpful error messages
- **Print failures** provide troubleshooting steps
- **Fallback to PDF printing** if thermal printing fails

## Security Considerations

### Bluetooth Security
- **Pairing is required** before printing
- **No automatic connections** to unknown devices
- **Device selection dialog** for multiple printers

### Data Privacy
- **Receipt data** is only sent to paired printers
- **No data storage** on the printer
- **Secure Bluetooth communication**

## Support

### Common Issues
1. **Printer not found**: Check pairing and Bluetooth settings
2. **Connection drops**: Ensure printer stays in range
3. **Print quality**: Clean print head and check paper
4. **Paper feed issues**: Check for jams and paper alignment

### Getting Help
- Check this guide for troubleshooting steps
- Test with the provided test file
- Ensure printer compatibility
- Contact support if issues persist

## Updates and Improvements

### Recent Updates
- ✅ **Bluetooth thermal printer support added**
- ✅ **Automatic device detection**
- ✅ **Comprehensive error handling**
- ✅ **User-friendly interface**
- ✅ **Test functionality included**

### Future Enhancements
- **Multiple printer support**
- **Print queue management**
- **Custom receipt templates**
- **Advanced printer settings**

---

**🎉 Your dental kiosk now has fully functional Bluetooth thermal printing!**

The orange "Thermal Print" button will connect to your 58mm thermal printer and print professional receipts automatically. This provides a fast, efficient printing solution for your dental clinic kiosk. 