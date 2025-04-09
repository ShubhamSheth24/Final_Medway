// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_pharmacy/models/user_model.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:provider/provider.dart';

// class BluetoothManager {
//   BluetoothDevice? _device;
//   bool _isConnecting = false;

//   Future<void> connectToBluetooth({
//     required BuildContext context,
//     required String docId,
//     required Function(String) onHeartRateUpdate,
//     required Function(String) onError,
//     required Function(bool) onFetchingStateChange,
//   }) async {
//     if (_isConnecting) {
//       print("Already attempting Bluetooth connection, skipping...");
//       return;
//     }

//     final userModel = Provider.of<UserModel>(context, listen: false);
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       print("No authenticated user found.");
//       onError("Please sign in to connect to Bluetooth");
//       return;
//     }

//     // Check and update user role if needed
//     if (userModel.role!.isEmpty) {
//       try {
//         final userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .where('email', isEqualTo: user.email)
//             .limit(1)
//             .get();
//         if (userDoc.docs.isNotEmpty) {
//           userModel.setRole(userDoc.docs.first.data()['role'] ?? '');
//         }
//       } catch (e) {
//         print("Error fetching user role: $e");
//         onError("Failed to verify user role: $e");
//         return;
//       }
//     }

//     if (userModel.role != 'Patient') {
//       print("User is not a patient: ${userModel.role}");
//       onError("Bluetooth connection available only for patients");
//       return;
//     }

//     print("User is a patient, attempting Bluetooth connection...");
//     _isConnecting = true;
//     onFetchingStateChange(true);

//     try {
//       // Check Bluetooth availability
//       if (!(await FlutterBluePlus.isSupported)) {
//         throw Exception("Bluetooth not supported on this device");
//       }

//       if (!(await FlutterBluePlus.isOn)) {
//         throw Exception("Bluetooth is turned off");
//       }

//       // Get connected devices
//       List<BluetoothDevice> connectedDevices = await FlutterBluePlus.connectedDevices;
//       if (connectedDevices.isEmpty) {
//         throw Exception("No Bluetooth devices connected");
//       }

//       _device = connectedDevices.first;
//       print("Connecting to: ${_device!.name} (${_device!.id})");

//       // Check connection state
//       BluetoothDeviceState state = (await _device!.state.first) as BluetoothDeviceState;
//       if (state != BluetoothDeviceState.connected) {
//         print("Device not connected, establishing connection...");
//         await _device!.connect(timeout: const Duration(seconds: 15));
//       } else {
//         print("Device already connected: ${_device!.name}");
//       }

//       await _discoverHeartRateService(docId, onHeartRateUpdate, onError);
//     } catch (e) {
//       print("Bluetooth connection error: $e");
//       onError("Failed to connect to Bluetooth device: $e");
//       _device = null;
//     } finally {
//       _isConnecting = false;
//       onFetchingStateChange(false);
//     }
//   }

//   Future<void> _discoverHeartRateService(
//     String docId,
//     Function(String) onHeartRateUpdate,
//     Function(String) onError,
//   ) async {
//     if (_device == null) {
//       print("No device available for service discovery");
//       onError("No Bluetooth device connected");
//       return;
//     }

//     print("Discovering services on ${_device!.name}...");
//     try {
//       List<BluetoothService> services = await _device!.discoverServices();
//       print("Found ${services.length} services");

//       bool heartRateServiceFound = false;

//       for (BluetoothService service in services) {
//         for (BluetoothCharacteristic characteristic in service.characteristics) {
//           if (characteristic.uuid.toString() == "00002a37-0000-1000-8000-00805f9b34fb" &&
//               characteristic.properties.notify) {
//             heartRateServiceFound = true;
//             print("Found heart rate characteristic: ${characteristic.uuid}");

//             await characteristic.setNotifyValue(true);
//             characteristic.value.listen(
//               (value) {
//                 if (value.isNotEmpty) {
//                   int hr = value[1]; // Heart rate in second byte
//                   String heartRate = hr.toString();
//                   onHeartRateUpdate(heartRate);
//                   print("Heart rate updated: $heartRate");

//                   FirebaseFirestore.instance
//                       .collection('users')
//                       .doc(docId)
//                       .collection('health_info')
//                       .doc('data')
//                       .set({'heartRate': heartRate}, SetOptions(merge: true))
//                       .catchError((e) => print("Error saving heart rate: $e"));
//                 }
//               },
//               onError: (e) {
//                 print("Error reading heart rate: $e");
//                 onError("Error reading heart rate: $e");
//               },
//             );
//             break;
//           }
//         }
//         if (heartRateServiceFound) break;
//       }

//       if (!heartRateServiceFound) {
//         throw Exception("Heart rate service not found on this device");
//       }
//     } catch (e) {
//       print("Service discovery failed: $e");
//       onError("Failed to discover heart rate service: $e");
//     }
//   }

//   void disconnect() {
//     _device?.disconnect();
//     _device = null;
//     _isConnecting = false;
//   }

//   bool get isConnecting => _isConnecting;
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_pharmacy/models/user_model.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

class BluetoothManager {
  BluetoothDevice? _device;
  bool _isConnecting = false;

  Future<void> connectToBluetooth({
    required BuildContext context,
    required String docId,
    required Function(String) onHeartRateUpdate,
    required Function(String) onError,
    required Function(bool) onFetchingStateChange,
  }) async {
    if (_isConnecting) {
      print("Already attempting Bluetooth connection, skipping...");
      return;
    }

    final userModel = Provider.of<UserModel>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No authenticated user found.");
      onError("Please sign in to connect to Bluetooth");
      return;
    }

    // Check and update user role if needed
    if (userModel.role!.isEmpty) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: user.email)
                .limit(1)
                .get();
        if (userDoc.docs.isNotEmpty) {
          userModel.setRole(userDoc.docs.first.data()['role'] ?? '');
        }
      } catch (e) {
        print("Error fetching user role: $e");
        onError("Failed to verify user role: $e");
        return;
      }
    }

    if (userModel.role != 'Patient') {
      print("User is not a patient: ${userModel.role}");
      onError("Bluetooth connection available only for patients");
      return;
    }

    print("User is a patient, attempting Bluetooth connection...");
    _isConnecting = true;
    onFetchingStateChange(true);

    try {
      if (!(await FlutterBluePlus.isSupported)) {
        throw Exception("Bluetooth not supported on this device");
      }

      if (!(await FlutterBluePlus.isOn)) {
        throw Exception("Bluetooth is turned off");
      }

      List<BluetoothDevice> connectedDevices =
          await FlutterBluePlus.connectedDevices;

      if (connectedDevices.isEmpty) {
        // Optional: Start scan here if no devices connected
        onError("No Bluetooth devices currently connected");
        throw Exception("No connected BLE devices found");
      }

      _device = connectedDevices.first;
      print("Connecting to: ${_device!.name} (${_device!.id})");

      BluetoothConnectionState connectionState =
          await _device!.connectionState.first;
      if (connectionState != BluetoothConnectionState.connected) {
        print("Device not connected, connecting...");
        await _device!.connect(timeout: const Duration(seconds: 15));
      } else {
        print("Device already connected: ${_device!.name}");
      }

      await _discoverHeartRateService(docId, onHeartRateUpdate, onError);
    } catch (e) {
      print("Bluetooth connection error: $e");
      onError("Failed to connect to Bluetooth device: $e");
      _device = null;
    } finally {
      _isConnecting = false;
      onFetchingStateChange(false);
    }
  }

  Future<void> _discoverHeartRateService(
    String docId,
    Function(String) onHeartRateUpdate,
    Function(String) onError,
  ) async {
    if (_device == null) {
      print("No device available for service discovery");
      onError("No Bluetooth device connected");
      return;
    }

    print("Discovering services on ${_device!.name}...");

    try {
      List<BluetoothService> services = await _device!.discoverServices();
      print("Found ${services.length} services");

      bool heartRateServiceFound = false;

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
                  "00002a37-0000-1000-8000-00805f9b34fb" &&
              characteristic.properties.notify) {
            heartRateServiceFound = true;
            print("Heart rate characteristic found: ${characteristic.uuid}");

            await characteristic.setNotifyValue(true);
            characteristic.value.listen(
              (value) {
                if (value.length > 1) {
                  int hr = value[1];
                  String heartRate = hr.toString();
                  onHeartRateUpdate(heartRate);
                  print("Heart rate updated: $heartRate");

                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(docId)
                      .collection('health_info')
                      .doc('data')
                      .set({'heartRate': heartRate}, SetOptions(merge: true))
                      .catchError((e) => print("Error saving heart rate: $e"));
                }
              },
              onError: (e) {
                print("Error reading heart rate: $e");
                onError("Error reading heart rate: $e");
              },
            );
            break;
          }
        }
        if (heartRateServiceFound) break;
      }

      if (!heartRateServiceFound) {
        throw Exception("Heart rate service not found on this device");
      }
    } catch (e) {
      print("Service discovery failed: $e");
      onError("Failed to discover heart rate service: $e");
    }
  }

  Future<void> disconnect() async {
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (e) {
        print("Error during disconnect: $e");
      }
    }
    _device = null;
    _isConnecting = false;
  }

  bool get isConnecting => _isConnecting;
}
