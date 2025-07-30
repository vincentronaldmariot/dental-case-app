import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'lib/services/thermal_print_service.dart';
import 'lib/services/printer_connection_helper.dart';

void main() {
  runApp(const ThermalPrintTestApp());
}

class ThermalPrintTestApp extends StatelessWidget {
  const ThermalPrintTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thermal Printer Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ThermalPrintTestScreen(),
    );
  }
}

class ThermalPrintTestScreen extends StatefulWidget {
  const ThermalPrintTestScreen({super.key});

  @override
  State<ThermalPrintTestScreen> createState() => _ThermalPrintTestScreenState();
}

class _ThermalPrintTestScreenState extends State<ThermalPrintTestScreen> {
  bool _isConnected = false;
  List<Map<String, String>> _pairedDevices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
  }

  Future<void> _loadPairedDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we're on a supported platform
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final devices = await PrinterConnectionHelper.getPairedDevices();
        setState(() {
          _pairedDevices = devices;
          _isConnected = PrinterConnectionHelper.isConnected;
        });
      } else {
        setState(() {
          _pairedDevices = [];
          _isConnected = false;
        });
      }
    } catch (e) {
      print('Error loading paired devices: $e');
      setState(() {
        _pairedDevices = [];
        _isConnected = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testThermalPrint() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final sampleData = {
        'patient_name': 'John Doe',
        'patient_id': 'P12345',
        'survey_date': '2024-01-15',
        'receipt_number': 'R789012',
        'total_score': 85,
        'questions': [
          {
            'question': 'How satisfied are you with our service?',
            'answer': 'Very Satisfied'
          },
          {'question': 'Would you recommend us?', 'answer': 'Yes'},
        ],
      };

      await ThermalPrintService.showPrintDialog(context, sampleData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Thermal printing is only available on mobile devices (Android/iOS)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Thermal Printer Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bluetooth Thermal Printer Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${_isConnected ? 'Connected' : 'Disconnected'}',
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}'),
                    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                      const Text('✓ Bluetooth thermal printing supported')
                    else
                      const Text(
                          '✗ Bluetooth thermal printing not supported on this platform'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Note: This is a simulated thermal printer for testing',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _loadPairedDevices,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Devices'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testThermalPrint,
                            icon: const Icon(Icons.print),
                            label: const Text('Test Print'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paired Devices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_pairedDevices.isEmpty)
                      const Text('No paired devices found')
                    else
                      ..._pairedDevices
                          .map((device) => ListTile(
                                leading: const Icon(Icons.bluetooth),
                                title: Text(device['name'] ?? 'Unknown Device'),
                                subtitle: Text(
                                    device['address'] ?? 'Unknown Address'),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      final success =
                                          await PrinterConnectionHelper
                                              .connectToDevice(device);
                                      if (success) {
                                        setState(() {
                                          _isConnected = true;
                                        });
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Successfully connected to printer!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Failed to connect to printer'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Connect'),
                                ),
                              ))
                          .toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Make sure your Bluetooth thermal printer is turned on and paired with your device\n'
                      '2. Tap "Refresh Devices" to see available printers\n'
                      '3. Tap "Connect" next to your printer to establish a connection\n'
                      '4. Tap "Test Print" to send a sample receipt to the printer\n'
                      '5. Check the printer output to verify the thermal printing works correctly',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
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
                            '• This test requires a physical Bluetooth thermal printer\n'
                            '• The printer must be paired with your device before testing\n'
                            '• Thermal printing is only supported on Android and iOS devices\n'
                            '• This is currently a simulated thermal printer for testing the UI flow\n'
                            '• The receipt content is formatted for thermal printing and logged to console',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
