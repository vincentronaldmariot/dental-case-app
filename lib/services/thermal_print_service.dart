import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ThermalPrintService {
  static bool isConnected = false;
  static String? connectedDeviceName;

  static Future<bool> isConnectedToPrinter() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }
    return isConnected;
  }

  static Future<bool> connectToPrinter() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    // For now, we'll simulate a connection
    // In a real implementation, this would connect to a Bluetooth thermal printer
    await Future.delayed(const Duration(seconds: 2));
    isConnected = true;
    connectedDeviceName = 'Thermal Printer (Simulated)';
    return true;
  }

  static Future<bool> printReceipt(Map<String, dynamic> data) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      print('Thermal printing is not supported on this platform');
      return false;
    }

    try {
      if (!await isConnectedToPrinter()) {
        final connected = await connectToPrinter();
        if (!connected) {
          return false;
        }
      }

      // Extract data from the map
      final patientName = data['patient_name'] ?? 'Unknown Patient';
      final patientId = data['patient_id'] ?? 'N/A';
      final surveyDate = data['survey_date'] ?? 'N/A';
      final receiptNumber = data['receipt_number'] ?? 'N/A';
      final totalScore = data['total_score']?.toString() ?? 'N/A';
      final questions = data['questions'] as List<dynamic>? ?? [];

      // Create thermal receipt content
      final receiptContent = _createThermalReceiptContent(
        patientName: patientName,
        patientId: patientId,
        surveyDate: surveyDate,
        receiptNumber: receiptNumber,
        totalScore: totalScore,
        questions: questions,
      );

      // For now, we'll simulate sending to a thermal printer
      // In a real implementation, this would send the bytes to a Bluetooth thermal printer
      print('=== THERMAL RECEIPT CONTENT ===');
      print(receiptContent);
      print('=== END THERMAL RECEIPT ===');

      // Simulate printing delay
      await Future.delayed(const Duration(seconds: 3));

      return true;
    } catch (e) {
      print('Error printing thermal receipt: $e');
      return false;
    }
  }

  static Future<void> showPrintDialog(
      BuildContext context, Map<String, dynamic> data) async {
    // Check platform support first
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Platform Not Supported'),
          content: const Text(
            'Bluetooth thermal printing is only available on Android and iOS devices. '
            'Please use a mobile device to test this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Connecting to printer...'),
            ],
          ),
        ),
      );

      final success = await printReceipt(data);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Print Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The receipt has been sent to the thermal printer successfully. '
                  'Please check the printer output.',
                ),
                if (connectedDeviceName != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connected Device:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Name: $connectedDeviceName'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'This is currently a simulated thermal printer. '
                        'The receipt content is formatted for thermal printing and logged to console. '
                        'To connect to a real thermal printer, you would need to pair a Bluetooth thermal printer with your device.',
                      ),
                    ],
                  ),
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
      } else {
        // Show error dialog with troubleshooting
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Print Failed'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Failed to print to thermal printer.'),
                SizedBox(height: 16),
                Text(
                  'Troubleshooting:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Ensure the printer is turned on'),
                Text('• Check that Bluetooth is enabled'),
                Text('• Verify the printer is paired with this device'),
                Text('• Make sure the printer has paper'),
                Text('• Try refreshing the device list'),
                Text('• Check if the printer supports ESC/POS commands'),
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

      // Show generic error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('An unexpected error occurred: $e'),
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

  static String _createThermalReceiptContent({
    required String patientName,
    required String patientId,
    required String surveyDate,
    required String receiptNumber,
    required String totalScore,
    required List<dynamic> questions,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('================================');
    buffer.writeln('    DENTAL SURVEY RECEIPT');
    buffer.writeln('================================');
    buffer.writeln();

    // Receipt details
    buffer.writeln('Receipt #: $receiptNumber');
    buffer.writeln('Date: $surveyDate');
    buffer.writeln();

    // Patient information
    buffer.writeln('PATIENT INFORMATION');
    buffer.writeln('--------------------');
    buffer.writeln('Name: $patientName');
    buffer.writeln('ID: $patientId');
    buffer.writeln();

    // Survey results
    buffer.writeln('SURVEY RESULTS');
    buffer.writeln('---------------');
    buffer.writeln('Total Score: $totalScore');
    buffer.writeln();

    // Questions and answers
    if (questions.isNotEmpty) {
      buffer.writeln('QUESTIONS & ANSWERS');
      buffer.writeln('--------------------');
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final questionText = question['question'] ?? 'Unknown Question';
        final answer = question['answer'] ?? 'No Answer';

        buffer.writeln('${i + 1}. $questionText');
        buffer.writeln('   Answer: $answer');
        buffer.writeln();
      }
    }

    // Footer
    buffer.writeln('================================');
    buffer.writeln('Thank you for your feedback!');
    buffer.writeln('================================');
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString();
  }

  // Method to convert the receipt to ESC/POS bytes for real thermal printers
  static List<int> _createEscPosBytes(String text) {
    final List<int> bytes = [];

    // ESC/POS commands
    const int ESC = 0x1B;
    const int GS = 0x1D;
    const int INIT = 0x40;
    const int ALIGN_CENTER = 0x01;
    const int ALIGN_LEFT = 0x00;
    const int FONT_BOLD = 0x01;
    const int FONT_NORMAL = 0x00;
    const int DOUBLE_HEIGHT = 0x01;
    const int DOUBLE_WIDTH = 0x01;
    const int NORMAL_SIZE = 0x00;
    const int CUT_PAPER = 0x00;
    const int FEED_LINE = 0x0A;

    // Initialize printer
    bytes.addAll([ESC, INIT]);

    // Add the text content
    bytes.addAll(text.codeUnits);

    // Feed paper and cut
    bytes.addAll([FEED_LINE, FEED_LINE, FEED_LINE]);
    bytes.addAll([GS, 0x56, CUT_PAPER]);

    return bytes;
  }
}
