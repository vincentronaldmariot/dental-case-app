# Thermal Printer Setup Guide for Dental Kiosk

## Overview
This guide explains how to set up and use a 58mm POS Bluetooth thermal printer with your dental clinic kiosk application.

## Supported Printers
- **58mm POS Bluetooth Thermal Printers** (like the one from [Shopee](https://shopee.ph/58MM-POS-Printer-Bluetooth-USB-Thermal-Receipt-printers-for-Supermarket-Convenience-store-Milk-tea-shop-Takeaway-order-i.1020397340.28707868904))
- Compatible with ESC/POS commands
- Bluetooth connectivity

## Setup Instructions

### 1. Hardware Setup
1. **Power on your thermal printer**
2. **Insert thermal paper** (58mm width)
3. **Turn on Bluetooth** on the printer (if applicable)

### 2. Bluetooth Pairing
1. **Enable Bluetooth** on your device (Android tablet/phone/PC)
2. **Go to Bluetooth settings**
3. **Scan for devices** and find your thermal printer
4. **Pair with the printer** (usually no password required)
5. **Note the printer name** for future reference

### 3. App Configuration
The app will automatically:
- **Detect paired devices** when you try to print
- **Connect to the printer** automatically if only one is available
- **Show a selection dialog** if multiple printers are paired

## Using the Thermal Printer

### Print Options Available
Your kiosk now has **two printing options**:

1. **PDF Print** (Blue button)
   - Creates professional PDF receipts
   - Can be printed on any standard printer
   - Can be saved as PDF files
   - Includes full formatting and colors

2. **Thermal Print** (Orange button)
   - Prints directly to your 58mm thermal printer
   - Simple text format optimized for thermal paper
   - Fast printing for immediate receipt delivery

### How to Print
1. **Complete the dental survey** in kiosk mode
2. **On the receipt screen**, you'll see two print buttons:
   - **"Print PDF"** - For standard printing
   - **"Thermal Print"** - For thermal printer
3. **Click "Thermal Print"** for your 58mm printer
4. **The app will automatically connect** to your paired printer
5. **Receipt will print immediately** on thermal paper

## Troubleshooting

### Common Issues

#### "No paired Bluetooth devices found"
**Solution:**
- Ensure your printer is turned on
- Check that Bluetooth is enabled on your device
- Re-pair the printer in Bluetooth settings
- Restart both the printer and your device

#### "Failed to connect to thermal printer"
**Solution:**
- Check if the printer is within range (usually 10 meters)
- Ensure the printer is not connected to another device
- Try disconnecting and reconnecting the printer
- Restart the printer

#### "Print failed" error
**Solution:**
- Check if thermal paper is loaded correctly
- Ensure the paper is not stuck or jammed
- Check if the printer has enough paper
- Try printing a test page from printer settings

#### Poor print quality
**Solution:**
- Clean the print head with a soft cloth
- Check if the thermal paper is fresh and not exposed to heat
- Ensure the printer is not overheating
- Replace thermal paper if it's old or damaged

### Printer Maintenance
1. **Clean the print head** regularly with a soft, dry cloth
2. **Keep the printer in a cool, dry place**
3. **Use high-quality thermal paper**
4. **Avoid exposing the printer to direct sunlight**
5. **Store thermal paper in a cool, dark place**

## Technical Details

### Receipt Format
The thermal receipt includes:
- **Clinic header** with dental clinic branding
- **Receipt number** and daily counter
- **Patient information** (name, serial number, unit, classification, contact)
- **Timestamp** of completion
- **Thank you message**

### Print Specifications
- **Paper width**: 58mm
- **Characters per line**: ~32-42 (depending on font size)
- **Print speed**: Fast thermal printing
- **Paper type**: Thermal paper (no ink required)

### Supported Platforms
- **Android**: Full support with automatic device detection
- **Windows**: Limited support (may require additional setup)
- **iOS**: Limited support due to Bluetooth restrictions
- **Web**: Not supported (Bluetooth not available in browsers)

## Advanced Configuration

### Customizing Receipt Content
You can modify the receipt content by editing:
- `lib/services/thermal_print_service.dart` - Main print logic
- `lib/services/printer_connection_helper.dart` - Connection management

### Adding More Print Options
To add additional print formats:
1. Create new print service methods
2. Add new buttons to the receipt screen
3. Update the UI to accommodate more options

### Printer Selection
If you have multiple printers:
- The app will show a selection dialog
- You can choose which printer to use
- The selection is remembered for the session

## Security Considerations
- **Bluetooth pairing** is required for security
- **No sensitive data** is stored on the printer
- **Receipts contain only** patient information and survey data
- **No network connectivity** required for thermal printing

## Support
If you encounter issues:
1. **Check this troubleshooting guide** first
2. **Restart the app** and try again
3. **Check printer manufacturer** documentation
4. **Contact technical support** if problems persist

## Future Enhancements
Potential improvements for thermal printing:
- **QR code printing** on thermal receipts
- **Custom receipt templates**
- **Multiple language support**
- **Print preview** before printing
- **Batch printing** capabilities
- **Print history** tracking 