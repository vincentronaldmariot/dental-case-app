import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class PrinterConnectionHelper {
  static bool isConnected = false;
  static String? connectedDeviceName;

  static Future<List<Map<String, String>>> getPairedDevices() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return [];
    }

    // Simulate device discovery
    await Future.delayed(const Duration(seconds: 1));

    // Return simulated devices for testing
    return [
      {'name': 'Thermal Printer 001', 'address': '00:11:22:33:44:55'},
      {'name': 'Receipt Printer', 'address': 'AA:BB:CC:DD:EE:FF'},
    ];
  }

  static Future<bool> connectToDevice(Map<String, String> device) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    try {
      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 2));
      connectedDeviceName = device['name'];
      isConnected = true;
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      isConnected = false;
      return false;
    }
  }

  static Future<Map<String, String>?> showDeviceSelectionDialog(
      BuildContext context) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return null;
    }

    try {
      final devices = await getPairedDevices();
      if (devices.isEmpty) {
        return null;
      }

      return await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(device['name'] ?? 'Unknown Device'),
                  subtitle: Text(device['address'] ?? 'Unknown Address'),
                  onTap: () => Navigator.of(context).pop(device),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing device selection dialog: $e');
      return null;
    }
  }

  static Future<bool> connectToFirstAvailableOrShowDialog(
      BuildContext? context) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    try {
      final devices = await getPairedDevices();

      if (devices.isEmpty) {
        if (context != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Printers Found'),
              content: const Text(
                'No paired Bluetooth thermal printers found. '
                'Please pair a thermal printer with this device first.',
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
        return false;
      }

      if (devices.length == 1) {
        // Auto-connect to the only available device
        return await connectToDevice(devices.first);
      }

      if (context != null) {
        // Show selection dialog for multiple devices
        final selectedDevice = await showDeviceSelectionDialog(context);
        if (selectedDevice != null) {
          return await connectToDevice(selectedDevice);
        }
      }

      return false;
    } catch (e) {
      print('Error connecting to first available device: $e');
      return false;
    }
  }
}
