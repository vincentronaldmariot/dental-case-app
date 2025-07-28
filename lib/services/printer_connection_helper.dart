import 'package:flutter/material.dart';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';  // Temporarily commented out

class PrinterConnectionHelper {
  // static final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;  // Temporarily commented out
  // static BluetoothDevice? connectedDevice;  // Temporarily commented out
  static bool isConnected = false;

  /// Gets list of paired Bluetooth devices
  // static Future<List<BluetoothDevice>> getPairedDevices() async {
  //   try {
  //     return await bluetooth.getBondedDevices();
  //   } catch (e) {
  //     print('Error getting paired devices: $e');
  //     return [];
  //   }
  // }

  /// Connects to a specific Bluetooth device
  // static Future<bool> connectToDevice(BluetoothDevice device) async {
  //   try {
  //     await bluetooth.connect(device);
  //     connectedDevice = device;
  //     isConnected = true;
  //     return true;
  //   } catch (e) {
  //     print('Error connecting to device: $e');
  //     return false;
  //   }
  // }

  /// Shows a dialog to select a Bluetooth device
  // static Future<BluetoothDevice?> showDeviceSelectionDialog(
  //     BuildContext context) async {
  //   final devices = await getPairedDevices();
  //   if (devices.isEmpty) {
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: const Text('No Devices Found'),
  //         content: const Text(
  //             'No paired Bluetooth devices found. Please pair your thermal printer first.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text('OK'),
  //           ),
  //         ],
  //       ),
  //     );
  //     return null;
  //   }

  //   return showDialog<BluetoothDevice>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Select Printer'),
  //       content: SizedBox(
  //         width: double.maxFinite,
  //         child: ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: devices.length,
  //           itemBuilder: (context, index) {
  //             final device = devices[index];
  //             return ListTile(
  //               title: Text(device.name ?? 'Unknown Device'),
  //               subtitle: Text(device.address),
  //               onTap: () => Navigator.of(context).pop(device),
  //             );
  //           },
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Cancel'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Connects to the first available device or shows device selection dialog
  static Future<bool> connectToFirstAvailableOrShowDialog(
      BuildContext context) async {
    // Placeholder implementation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer Connection'),
        content: const Text(
            'Thermal printer connection is temporarily unavailable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }
}
