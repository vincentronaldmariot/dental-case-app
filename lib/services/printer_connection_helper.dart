import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrinterConnectionHelper {
  static final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  static BluetoothDevice? connectedDevice;

  /// Get list of paired Bluetooth devices
  static Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await bluetooth.getBondedDevices();
    } catch (e) {
      print('Error getting paired devices: $e');
      return [];
    }
  }

  /// Connect to a specific Bluetooth device
  static Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await bluetooth.connect(device);
      connectedDevice = device;
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }

  /// Disconnect from current device
  static Future<void> disconnect() async {
    try {
      await bluetooth.disconnect();
      connectedDevice = null;
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Check if currently connected to a device
  static bool get isConnected => connectedDevice != null;

  /// Show device selection dialog
  static Future<BluetoothDevice?> showDeviceSelectionDialog(
      BuildContext context) async {
    final devices = await getPairedDevices();

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No paired Bluetooth devices found. Please pair your thermal printer first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return null;
    }

    return showDialog<BluetoothDevice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Thermal Printer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: const Icon(Icons.print),
                title: Text(device.name ?? 'Unknown Device'),
                subtitle: Text(device.address ?? 'Unknown Address'),
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
  }

  /// Connect to first available device or show selection dialog
  static Future<bool> connectToFirstAvailableOrShowDialog(
      BuildContext context) async {
    final devices = await getPairedDevices();

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No paired Bluetooth devices found. Please pair your thermal printer first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return false;
    }

    if (devices.length == 1) {
      // Auto-connect to the only available device
      return await connectToDevice(devices.first);
    } else {
      // Show selection dialog for multiple devices
      final selectedDevice = await showDeviceSelectionDialog(context);
      if (selectedDevice != null) {
        return await connectToDevice(selectedDevice);
      }
      return false;
    }
  }
}
