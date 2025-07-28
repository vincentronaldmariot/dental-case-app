import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'printer_connection_helper.dart';

class ThermalPrintService {
  static final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  /// Prints a simple dental receipt to a 58mm Bluetooth thermal printer.
  /// [surveyData] should contain 'patient_info' and other fields.
  /// [receiptNumber] is the unique receipt identifier.
  /// [context] is required for showing connection dialogs.
  static Future<void> printReceipt({
    required Map<String, dynamic> surveyData,
    required String receiptNumber,
    required BuildContext context,
  }) async {
    final patientInfo = surveyData['patient_info'] ?? {};
    final name = patientInfo['name'] ?? 'N/A';
    final serialNumber = patientInfo['serial_number'] ?? 'N/A';
    final unitAssignment = patientInfo['unit_assignment'] ?? 'N/A';
    final classification = patientInfo['classification'] ?? 'N/A';
    final contactNumber = patientInfo['contact_number'] ?? 'N/A';
    final now = DateTime.now();

    // Check if connected to a printer
    if (!PrinterConnectionHelper.isConnected) {
      // Try to connect to available devices
      final connected =
          await PrinterConnectionHelper.connectToFirstAvailableOrShowDialog(
              context);
      if (!connected) {
        throw Exception(
            'Failed to connect to thermal printer. Please ensure your printer is paired and turned on.');
      }
    }

    // Print receipt
    await bluetooth.printNewLine();
    await bluetooth.printCustom('DENTAL CLINIC', 3, 1);
    await bluetooth.printCustom('Survey Receipt', 2, 1);
    await bluetooth.printNewLine();
    await bluetooth.printCustom('Receipt: $receiptNumber', 1, 0);
    await bluetooth.printCustom(
        'Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        1,
        0);
    await bluetooth.printNewLine();
    await bluetooth.printCustom('Name: $name', 1, 0);
    await bluetooth.printCustom('Serial: $serialNumber', 1, 0);
    await bluetooth.printCustom('Unit: $unitAssignment', 1, 0);
    await bluetooth.printCustom('Class: $classification', 1, 0);
    await bluetooth.printCustom('Contact: $contactNumber', 1, 0);
    await bluetooth.printNewLine();
    await bluetooth.printCustom('Thank you!', 2, 1);
    await bluetooth.printNewLine();
    await bluetooth.paperCut();
  }
}
