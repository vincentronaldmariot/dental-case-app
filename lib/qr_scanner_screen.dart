import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';  // Temporarily commented out
import 'dart:convert';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  // QRViewController? controller;  // Temporarily commented out
  bool isScanning = true;
  String? scannedData;

  @override
  void reassemble() {
    super.reassemble();
    // if (controller != null) {
    //   // Need to pause camera on hot reload
    //   controller!.pauseCamera();
    // }
  }

  @override
  Widget build(BuildContext context) {
    // Check if platform supports QR scanning
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _buildUnsupportedPlatformView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: const Color(0xFF0029B2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildPlaceholderView(),
    );
  }

  Widget _buildPlaceholderView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Color(0xFF0029B2),
          ),
          const SizedBox(height: 20),
          const Text(
            'QR Scanner Temporarily Unavailable',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'QR scanning functionality is being updated.\nPlease use manual entry for now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0029B2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedPlatformView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: const Color(0xFF0029B2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Color(0xFF0029B2),
            ),
            const SizedBox(height: 20),
            const Text(
              'QR Scanner Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'QR scanning is not supported on this platform.\nPlease use manual entry.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0029B2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // void _onQRViewCreated(QRViewController controller) {
  //   this.controller = controller;
  //   controller.scannedDataStream.listen((scanData) {
  //     if (scanData.code != null && isScanning) {
  //       setState(() {
  //         scannedData = scanData.code;
  //         isScanning = false;
  //       });
  //       _processScannedData(scanData.code!);
  //     }
  //   });
  // }

  void _processScannedData(String data) {
    try {
      final Map<String, dynamic> jsonData = json.decode(data);
      // Process the scanned data
      print('Scanned data: $jsonData');
    } catch (e) {
      print('Error processing scanned data: $e');
    }
  }

  @override
  void dispose() {
    // controller?.dispose();
    super.dispose();
  }
}
