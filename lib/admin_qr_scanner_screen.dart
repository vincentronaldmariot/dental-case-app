import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'survey_qr_viewer_screen.dart';

class AdminQrScannerScreen extends StatefulWidget {
  const AdminQrScannerScreen({super.key});

  @override
  State<AdminQrScannerScreen> createState() => _AdminQrScannerScreenState();
}

class _AdminQrScannerScreenState extends State<AdminQrScannerScreen> {
  MobileScannerController? controller;
  Map<String, dynamic>? scannedData;
  String? errorMessage;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanning && capture.barcodes.isNotEmpty) {
      final barcode = capture.barcodes.first;
      if (barcode.rawValue != null) {
        _processQRCode(barcode.rawValue!);
      }
    }
  }

  void _processQRCode(String qrData) {
    // Clear any previous error
    setState(() {
      errorMessage = null;
    });

    try {
      // First, try to parse as JSON
      final data = jsonDecode(qrData);

      // Check if it's a valid dental app QR code format
      if (data is Map<String, dynamic>) {
        final type = data['type'] ?? '';

        // Check if it's a dental survey QR code
        if (type == 'dental_survey_complete') {
          setState(() {
            scannedData = data;
            isScanning = false;
            errorMessage = null;
          });

          // Stop scanning after successful scan
          controller?.stop();

          // Navigate to survey viewer screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurveyQrViewerScreen(surveyData: data),
            ),
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Survey QR Code scanned successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (data.containsKey('type') ||
            data.containsKey('patientName') ||
            data.containsKey('receipt_number') ||
            data.containsKey('id') ||
            data.containsKey('service')) {
          // Handle other valid QR code formats (appointments, etc.)
          setState(() {
            scannedData = data;
            isScanning = false;
            errorMessage = null;
          });

          // Stop scanning after successful scan
          controller?.stop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code scanned successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showInvalidQRError(
              'Invalid QR code format: Missing required fields');
        }
      } else {
        _showInvalidQRError('Invalid QR code format: Expected JSON object');
      }
    } catch (e) {
      // Handle JSON parsing errors
      String errorMsg = 'Invalid QR code format';

      if (e is FormatException) {
        // Check if it's a simple text QR code (not JSON)
        if (qrData.trim().isNotEmpty && !qrData.trim().startsWith('{')) {
          errorMsg = 'This QR code contains text, not appointment/survey data';
        } else {
          errorMsg = 'Invalid JSON format in QR code';
        }
      } else {
        errorMsg = 'Error processing QR code: ${e.toString()}';
      }

      _showInvalidQRError(errorMsg);
    }
  }

  void _showInvalidQRError(String message) {
    setState(() {
      errorMessage = message;
      scannedData = null;
    });

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    // Continue scanning after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          errorMessage = null;
        });
      }
    });
  }

  void _resetScanner() {
    setState(() {
      scannedData = null;
      errorMessage = null;
      isScanning = true;
    });
    controller?.start();
  }

  Widget _buildQRDataDisplay() {
    if (scannedData == null) return const SizedBox.shrink();

    final type = scannedData!['type'] as String?;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                type == 'appointment' ? Icons.calendar_today : Icons.assignment,
                color: const Color(0xFF0029B2),
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type == 'appointment'
                      ? 'Appointment Details'
                      : 'Survey Receipt',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0029B2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...scannedData!.entries.map((entry) {
            if (entry.key == 'type') return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: isSmallScreen ? 100 : 120,
                    child: Text(
                      _formatKey(entry.key),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Text(
                    ': ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatValue(entry.key, entry.value.toString()),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _resetScanner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0029B2),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Scan Another',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(scannedData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005800),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Use Data',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    if (errorMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Invalid QR Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please scan a valid dental appointment or survey QR code from this app.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    switch (key) {
      case 'patientName':
        return 'Patient Name';
      case 'id':
        return 'Appointment ID';
      case 'service':
        return 'Service';
      case 'classification':
        return 'Classification';
      case 'date':
        return 'Date';
      case 'time':
        return 'Time';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Phone';
      case 'receipt_number':
        return 'Receipt Number';
      case 'daily_counter':
        return 'Daily Counter';
      case 'serial_number':
        return 'Serial Number';
      case 'unit_assignment':
        return 'Unit Assignment';
      case 'contact_number':
        return 'Contact Number';
      case 'timestamp':
        return 'Timestamp';
      default:
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '')
            .join(' ');
    }
  }

  String _formatValue(String key, String value) {
    switch (key) {
      case 'date':
        // Format date from yyyy-MM-dd to a more readable format
        try {
          final date = DateTime.parse(value);
          return '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          return value;
        }
      case 'time':
        // Format time to be more readable
        if (value.contains(':')) {
          return value;
        }
        return value;
      case 'classification':
        // Handle classification display
        if (value == 'N/A' || value.isEmpty) {
          return 'Not specified';
        }
        return value;
      case 'service':
        // Capitalize service name
        if (value.isNotEmpty) {
          return value[0].toUpperCase() + value.substring(1).toLowerCase();
        }
        return value;
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'QR Code Scanner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0029B2),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Camera View
          Container(
            height: 300,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: MobileScanner(
                controller: controller,
                onDetect: _onDetect,
              ),
            ),
          ),

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Instructions or Error Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (isScanning && errorMessage == null) ...[
                          const Icon(
                            Icons.qr_code_scanner,
                            size: 48,
                            color: Color(0xFF0029B2),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Point camera at QR code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0029B2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan appointment or survey QR codes from this app',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Error Display
                  if (errorMessage != null) ...[
                    _buildErrorDisplay(),
                  ],

                  // Scanned Data Display
                  if (scannedData != null) ...[
                    _buildQRDataDisplay(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
