import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';  // Temporarily disabled
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data'; // Added for Uint8List

class ThermalPrintService {
  static bool isConnected = false;
  static String? connectedDeviceName;
  // static BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;  // Temporarily disabled
  // static BluetoothDevice? connectedDevice;  // Temporarily disabled

  static Future<bool> isConnectedToPrinter() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    // Temporarily return false since thermal printer is not available
    return false;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    try {
      // Request Bluetooth permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      return allGranted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getAvailableDevices() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return [];
    }

    // Temporarily return empty list since thermal printer is not available
    return [];
  }

  static Future<bool> connectToPrinter([dynamic device]) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    // Temporarily return false since thermal printer is not available
    return false;
  }

  static Future<bool> printReceipt(Map<String, dynamic> data) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      print('Thermal printing is not supported on this platform');
      return false;
    }

    // Temporarily return false since thermal printer is not available
    print(
        'Thermal printer functionality is temporarily disabled for APK build');
    return false;
  }

  static Future<void> showPrintDialog(
      BuildContext context, Map<String, dynamic> data) async {
    try {
      // Request permissions first
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Permissions Required'),
                ],
              ),
              content: const Text(
                'Bluetooth permissions are required to connect to thermal printers. Please grant the necessary permissions in your device settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Connecting to thermal printer...'),
            ],
          ),
        ),
      );

      // Try to print the receipt
      final success = await printReceipt(data);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show result dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(success ? 'Print Successful' : 'Print Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  success
                      ? 'The receipt has been sent to the thermal printer successfully. Please check the printer output.'
                      : 'Failed to print to thermal printer. Please check the printer connection and try again.',
                  style: const TextStyle(fontSize: 16),
                ),
                if (success) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connected Device:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Name: ${connectedDeviceName ?? 'Unknown'}'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Note: Make sure your thermal printer is turned on and connected via Bluetooth.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Print Error'),
              ],
            ),
            content: Text('An error occurred while printing: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  static String _createThermalReceiptContent({
    required String patientName,
    required String patientId,
    required String surveyDate,
    required String receiptNumber,
    required String totalScore,
    required List<dynamic> questions,
  }) {
    final buffer = StringBuffer();

    // ESC/POS commands for formatting
    const String ESC = '\x1B';
    const String GS = '\x1D';
    const String INIT = '$ESC@';
    const String ALIGN_CENTER = '${ESC}a1';
    const String ALIGN_LEFT = '${ESC}a0';
    const String BOLD_ON = '${ESC}E1';
    const String BOLD_OFF = '${ESC}E0';
    const String DOUBLE_HEIGHT = '${ESC}!16';
    const String NORMAL_SIZE = '${ESC}!0';
    const String FEED_LINE = '\n';
    const String CUT_PAPER = '${GS}V0';

    // Initialize printer
    buffer.write(INIT);

    // Header
    buffer.write(ALIGN_CENTER);
    buffer.write(BOLD_ON);
    buffer.write(DOUBLE_HEIGHT);
    buffer.write('DENTAL SURVEY RECEIPT$FEED_LINE');
    buffer.write(NORMAL_SIZE);
    buffer.write(BOLD_OFF);
    buffer.write('================================$FEED_LINE');
    buffer.write(FEED_LINE);

    // Left alignment for content
    buffer.write(ALIGN_LEFT);

    // Receipt details
    buffer.write(BOLD_ON);
    buffer.write('Receipt #: $receiptNumber$FEED_LINE');
    buffer.write('Date: $surveyDate$FEED_LINE');
    buffer.write(BOLD_OFF);
    buffer.write(FEED_LINE);

    // Patient information
    buffer.write(BOLD_ON);
    buffer.write('PATIENT INFORMATION$FEED_LINE');
    buffer.write(BOLD_OFF);
    buffer.write('--------------------$FEED_LINE');
    buffer.write('Name: $patientName$FEED_LINE');
    buffer.write('ID: $patientId$FEED_LINE');
    buffer.write(FEED_LINE);

    // Survey results
    buffer.write(BOLD_ON);
    buffer.write('SURVEY RESULTS$FEED_LINE');
    buffer.write(BOLD_OFF);
    buffer.write('---------------$FEED_LINE');
    buffer.write('Total Score: $totalScore$FEED_LINE');
    buffer.write(FEED_LINE);

    // Questions and answers
    if (questions.isNotEmpty) {
      buffer.write(BOLD_ON);
      buffer.write('QUESTIONS & ANSWERS$FEED_LINE');
      buffer.write(BOLD_OFF);
      buffer.write('--------------------$FEED_LINE');

      for (int i = 0; i < questions.length && i < 5; i++) {
        // Limit to 5 questions for thermal paper
        final question = questions[i];
        final questionText = question['question'] ?? 'Unknown Question';
        final answer = question['answer'] ?? 'No Answer';

        // Truncate long text to fit thermal paper width
        final truncatedQuestion = questionText.length > 30
            ? '${questionText.substring(0, 27)}...'
            : questionText;
        final truncatedAnswer =
            answer.length > 30 ? '${answer.substring(0, 27)}...' : answer;

        buffer.write('${i + 1}. $truncatedQuestion$FEED_LINE');
        buffer.write('   Answer: $truncatedAnswer$FEED_LINE');
        buffer.write(FEED_LINE);
      }
    }

    // Footer
    buffer.write(ALIGN_CENTER);
    buffer.write(BOLD_ON);
    buffer.write('================================$FEED_LINE');
    buffer.write('Thank you for your feedback!$FEED_LINE');
    buffer.write('================================$FEED_LINE');
    buffer.write(BOLD_OFF);

    // Feed paper and cut
    buffer.write('$FEED_LINE$FEED_LINE$FEED_LINE');
    buffer.write(CUT_PAPER);

    return buffer.toString();
  }

  // Method to disconnect from printer
  static Future<void> disconnect() async {
    // This method is no longer relevant as thermal printer is not available
    print('Disconnecting from thermal printer (no-op)');
  }

  // Method to check if Bluetooth is enabled
  static Future<bool> isBluetoothEnabled() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    // This method is no longer relevant as thermal printer is not available
    return false;
  }
}
