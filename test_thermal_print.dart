import 'package:flutter/material.dart';
import 'lib/services/thermal_print_service.dart';

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
  List<dynamic> availableDevices = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableDevices();
  }

  Future<void> _loadAvailableDevices() async {
    setState(() {
      isLoading = true;
    });

    try {
      final devices = await ThermalPrintService.getAvailableDevices();
      setState(() {
        availableDevices = devices;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableDevices,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Printer Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<bool>(
                      future: ThermalPrintService.isConnectedToPrinter(),
                      builder: (context, snapshot) {
                        final isConnected = snapshot.data ?? false;
                        return Row(
                          children: [
                            Icon(
                              isConnected ? Icons.check_circle : Icons.error,
                              color: isConnected ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isConnected ? 'Connected' : 'Not Connected',
                              style: TextStyle(
                                color: isConnected ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (ThermalPrintService.connectedDeviceName != null) ...[
                      const SizedBox(height: 4),
                      Text('Device: ${ThermalPrintService.connectedDeviceName}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Available devices section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Devices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (availableDevices.isEmpty)
                      const Text('No thermal printers found')
                    else
                      ...availableDevices.map((device) => ListTile(
                            title: Text(device.name ?? 'Unknown Device'),
                            subtitle: Text(device.address ?? 'No Address'),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                try {
                                  bool connected = await ThermalPrintService.connectToPrinter(device);
                                  if (connected) {
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Connected to ${device.name}'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to connect'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Connect'),
                            ),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test print section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Print',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Sample data for testing
                        final sampleData = {
                          'patient_name': 'John Doe',
                          'patient_id': 'P12345',
                          'survey_date': '2024-01-15',
                          'receipt_number': 'R001',
                          'total_score': '85',
                          'questions': [
                            {
                              'question': 'How satisfied are you with our service?',
                              'answer': 'Very Satisfied',
                            },
                            {
                              'question': 'Would you recommend us?',
                              'answer': 'Yes',
                            },
                          ],
                        };

                        await ThermalPrintService.showPrintDialog(context, sampleData);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print Test Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
