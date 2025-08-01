import 'package:flutter/material.dart';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';  // Temporarily disabled
import 'services/thermal_print_service.dart';

class ThermalPrinterTestScreen extends StatefulWidget {
  const ThermalPrinterTestScreen({super.key});

  @override
  State<ThermalPrinterTestScreen> createState() =>
      _ThermalPrinterTestScreenState();
}

class _ThermalPrinterTestScreenState extends State<ThermalPrinterTestScreen> {
  List<dynamic> _devices = [];
  dynamic _selectedDevice;
  bool _isLoading = false;
  bool _isConnected = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadDevices();
  }

  Future<void> _checkConnection() async {
    final connected = await ThermalPrintService.isConnectedToPrinter();
    setState(() {
      _isConnected = connected;
      _statusMessage =
          connected ? 'Connected to thermal printer' : 'Not connected';
    });
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final devices = await ThermalPrintService.getAvailableDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading devices: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToDevice(dynamic device) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to ${device.name}...';
    });

    try {
      final success = await ThermalPrintService.connectToPrinter(device);
      setState(() {
        _isConnected = success;
        _selectedDevice = success ? device : null;
        _statusMessage = success
            ? 'Connected to ${device.name}'
            : 'Failed to connect to ${device.name}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error connecting: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _printTestReceipt() async {
    if (!_isConnected) {
      setState(() {
        _statusMessage = 'Please connect to a printer first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Printing test receipt...';
    });

    try {
      final testData = {
        'patient_name': 'Test Patient',
        'patient_id': 'TEST-001',
        'survey_date': DateTime.now().toString(),
        'receipt_number': 'TEST-001',
        'total_score': '85',
        'questions': [
          {
            'question': 'How satisfied are you with our service?',
            'answer': 'Very Satisfied'
          },
          {'question': 'Would you recommend us?', 'answer': 'Yes'},
        ],
      };

      final success = await ThermalPrintService.printReceipt(testData);
      setState(() {
        _statusMessage = success
            ? 'Test receipt printed successfully!'
            : 'Failed to print test receipt';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error printing: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnect() async {
    await ThermalPrintService.disconnect();
    setState(() {
      _isConnected = false;
      _selectedDevice = null;
      _statusMessage = 'Disconnected from printer';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer Test'),
        backgroundColor: const Color(0xFF0029B2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${_isConnected ? "Connected" : "Disconnected"}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    if (_isConnected &&
                        ThermalPrintService.connectedDeviceName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                          'Device: ${ThermalPrintService.connectedDeviceName}'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Available Devices
            const Text(
              'Available Bluetooth Devices:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_devices.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'No Bluetooth devices found. Make sure Bluetooth is enabled and devices are paired.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isSelected =
                        _selectedDevice?.address == device.address;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: ListTile(
                        leading: Icon(
                          (device.name?.toLowerCase().contains('thermal') ??
                                      false) ||
                                  (device.name
                                          ?.toLowerCase()
                                          .contains('printer') ??
                                      false) ||
                                  (device.name?.toLowerCase().contains('pos') ??
                                      false)
                              ? Icons.print
                              : Icons.bluetooth,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        title: Text(device.name ?? 'Unknown Device'),
                        subtitle: Text(device.address ?? 'Unknown Address'),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _connectToDevice(device),
                                child: const Text('Connect'),
                              ),
                        onTap:
                            _isLoading ? null : () => _connectToDevice(device),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadDevices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Devices'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isLoading || !_isConnected ? null : _printTestReceipt,
                    icon: const Icon(Icons.print),
                    label: const Text('Print Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_isConnected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _disconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
