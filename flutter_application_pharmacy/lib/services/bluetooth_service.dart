// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_pharmacy/models/user_model.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:provider/provider.dart';

// class BluetoothManager {
//   BluetoothDevice? _device;
//   bool _isConnecting = false;
//   bool _hasShownInitialMessage = false;

//   Future<void> connectToBluetooth({
//     required BuildContext context,
//     required String docId,
//     required Function(String) onHeartRateUpdate,
//     required Function(String) onMessage,
//     required Function(bool) onFetchingStateChange,
//     required bool isRefresh,
//   }) async {
//     if (_isConnecting) {
//       print("Already attempting Bluetooth connection, skipping...");
//       return;
//     }

//     final userModel = Provider.of<UserModel>(context, listen: false);
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       print("No authenticated user found.");
//       onMessage("Please sign in to connect to Bluetooth");
//       return;
//     }

//     if (userModel.role!.isEmpty) {
//       try {
//         final userDoc =
//             await FirebaseFirestore.instance
//                 .collection('users')
//                 .where('email', isEqualTo: user.email)
//                 .limit(1)
//                 .get();
//         if (userDoc.docs.isNotEmpty) {
//           userModel.setRole(userDoc.docs.first.data()['role'] ?? '');
//         }
//       } catch (e) {
//         print("Error fetching user role: $e");
//         onMessage("Failed to verify user role");
//         return;
//       }
//     }

//     if (userModel.role != 'Patient') {
//       print("User is not a patient: ${userModel.role}");
//       onMessage("Bluetooth connection available only for patients");
//       return;
//     }

//     print("User is a patient, attempting BLE connection...");
//     _isConnecting = true;
//     onFetchingStateChange(true);

//     try {
//       if (!(await FlutterBluePlus.isSupported)) {
//         onMessage("Bluetooth not supported on this device");
//         return;
//       }

//       if (!(await FlutterBluePlus.isOn)) {
//         if (!_hasShownInitialMessage && !isRefresh) {
//           onMessage("Please turn on Bluetooth");
//           _hasShownInitialMessage = true;
//         } else if (isRefresh) {
//           onMessage("Please turn on Bluetooth");
//         }
//         return;
//       }

//       // Disconnect any existing connection to ensure fresh scan
//       if (_device != null) {
//         await _device!.disconnect();
//         _device = null;
//       }

//       // Scan for NanoHRM
//       print("Scanning for NanoHRM...");
//       await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

//       bool deviceFound = false;
//       await for (var scanResult in FlutterBluePlus.scanResults) {
//         for (var result in scanResult) {
//           print("Scan found: ${result.device.name} (${result.device.id})");
//           if (result.device.name == "NanoHRM") {
//             _device = result.device;
//             deviceFound = true;
//             await FlutterBluePlus.stopScan();
//             print("NanoHRM found: ${_device!.id}");
//             break;
//           }
//         }
//         if (deviceFound) break;
//       }

//       if (_device == null) {
//         print("NanoHRM not found during scan");
//         onMessage(
//           isRefresh
//               ? "Please ensure NanoHRM is powered on"
//               : "NanoHRM not found",
//         );
//         return;
//       }

//       // Connect to NanoHRM
//       print("Connecting to: ${_device!.name} (${_device!.id})");
//       BluetoothConnectionState connectionState =
//           await _device!.connectionState.first;
//       if (connectionState != BluetoothConnectionState.connected) {
//         print("Device not connected, connecting...");
//         await _device!.connect(timeout: const Duration(seconds: 15));
//       } else {
//         print("Device already connected: ${_device!.name}");
//       }

//       await _discoverHeartRateService(docId, onHeartRateUpdate, onMessage);
//     } catch (e) {
//       print("BLE connection error: $e");
//       onMessage("Failed to connect to NanoHRM: $e");
//     } finally {
//       _isConnecting = false;
//       onFetchingStateChange(false);
//     }
//   }

//   Future<void> _discoverHeartRateService(
//     String docId,
//     Function(String) onHeartRateUpdate,
//     Function(String) onMessage,
//   ) async {
//     if (_device == null) {
//       print("No device available for service discovery");
//       onMessage("No BLE device connected");
//       return;
//     }

//     print("Discovering services on ${_device!.name}...");
//     try {
//       List<BluetoothService> services = await _device!.discoverServices();
//       print("Found ${services.length} services");

//       bool heartRateServiceFound = false;

//       for (BluetoothService service in services) {
//         if (service.uuid.toString().toLowerCase() ==
//             "0000180d-0000-1000-8000-00805f9b34fb") {
//           for (BluetoothCharacteristic characteristic
//               in service.characteristics) {
//             if (characteristic.uuid.toString().toLowerCase() ==
//                     "00002a37-0000-1000-8000-00805f9b34fb" &&
//                 characteristic.properties.notify) {
//               heartRateServiceFound = true;
//               print("Heart rate characteristic found: ${characteristic.uuid}");

//               await characteristic.setNotifyValue(true);
//               characteristic.value.listen(
//                 (value) {
//                   if (value.length > 1) {
//                     int hr = value[1];
//                     String heartRate = hr.toString();
//                     print("Heart rate received: $heartRate");
//                     onHeartRateUpdate(heartRate);

//                     FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(docId)
//                         .collection('health_info')
//                         .doc('data')
//                         .set({'heartRate': heartRate}, SetOptions(merge: true))
//                         .catchError(
//                           (e) => print("Error saving heart rate: $e"),
//                         );
//                   }
//                 },
//                 onError: (e) {
//                   print("Error reading heart rate: $e");
//                   onMessage("Error reading heart rate");
//                 },
//               );
//               break;
//             }
//           }
//         }
//         if (heartRateServiceFound) break;
//       }

//       if (!heartRateServiceFound) {
//         print("Heart rate service not found");
//         onMessage("Heart rate service not found on NanoHRM");
//       }
//     } catch (e) {
//       print("Service discovery error: $e");
//       onMessage("Failed to discover heart rate service");
//     }
//   }

//   void disconnect() {
//     if (_device != null) {
//       try {
//         _device!.disconnect();
//         print("Disconnected from ${_device!.name}");
//       } catch (e) {
//         print("Error during disconnect: $e");
//       }
//     }
//     _device = null;
//     _isConnecting = false;
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  BluetoothDevice? _device;
  StreamSubscription<ScanResult>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;
  Timer? _scanTimer;
  bool _isConnected = false;
  String? _lastMessage;

  Future<void> connectToBluetooth({
    required BuildContext context,
    required String docId,
    required Function(String) onHeartRateUpdate,
    required Function(String) onMessage,
    required Function(bool) onFetchingStateChange,
    required bool isRefresh,
  }) async {
    try {
      if (_isConnected) {
        print("Already connected to NanoHRM, skipping scan");
        return;
      }
      onFetchingStateChange(true);
      print("Starting Bluetooth scan for NanoHRM...");

      // Check Bluetooth state
      try {
        bool isBluetoothOn = await FlutterBluePlus.isOn.timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        );
        if (!isBluetoothOn) {
          print("Bluetooth is off");
          _showMessage("Please turn on Bluetooth", onMessage);
          onFetchingStateChange(false);
          return;
        }
        print("Bluetooth is on");
      } catch (e) {
        print("Error checking Bluetooth state: $e");
        _showMessage("Bluetooth unavailable", onMessage);
        onFetchingStateChange(false);
        return;
      }

      // Start scanning
      try {
        print("Initiating scan...");
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
        print("Scan started");
      } catch (e) {
        print("Scan start error: $e");
        _showMessage("Failed to start Bluetooth scan", onMessage);
        onFetchingStateChange(false);
        return;
      }

      _scanTimer?.cancel();
      _scanTimer = Timer(const Duration(seconds: 15), () {
        FlutterBluePlus.stopScan();
        print("Scan timeout, stopping...");
        _showMessage("Please ensure NanoHRM is turned on", onMessage);
        onFetchingStateChange(false);
      });

      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) async {
          for (ScanResult result in results) {
            String deviceName =
                result.device.name.isEmpty ? "Unnamed" : result.device.name;
            String serviceUuids = result.advertisementData.serviceUuids.join(
              ", ",
            );
            print(
              "Scan found: $deviceName (${result.device.id}), UUIDs: $serviceUuids",
            );
            bool isNanoHRM =
                result.advertisementData.serviceUuids.contains("180d") ||
                deviceName.toLowerCase().contains("nanohrm");
            if (isNanoHRM && !_isConnected) {
              _device = result.device;
              print("NanoHRM found: ${result.device.id}");
              await FlutterBluePlus.stopScan();
              _scanTimer?.cancel();
              _scanSubscription?.cancel();

              // Connect with retry
              for (int attempt = 1; attempt <= 3; attempt++) {
                try {
                  print("Connecting to NanoHRM, attempt $attempt...");
                  await _device!.connect(timeout: const Duration(seconds: 15));
                  print("Connected to NanoHRM: ${_device!.id}");
                  _isConnected = true;

                  // Monitor connection state
                  _connectionSubscription?.cancel();
                  _connectionSubscription = _device!.connectionState.listen((
                    state,
                  ) async {
                    print("Connection state: $state");
                    if (state == BluetoothConnectionState.disconnected) {
                      print("NanoHRM disconnected");
                      _isConnected = false;
                      await _device?.disconnect();
                      if (attempt < 3) {
                        print("Retrying connection silently...");
                        await connectToBluetooth(
                          context: context,
                          docId: docId,
                          onHeartRateUpdate: onHeartRateUpdate,
                          onMessage: onMessage,
                          onFetchingStateChange: onFetchingStateChange,
                          isRefresh: true,
                        );
                      }
                    }
                  });

                  // Discover services
                  List<BluetoothService> services =
                      await _device!.discoverServices();
                  for (BluetoothService service in services) {
                    if (service.uuid.toString().toLowerCase().startsWith(
                      "180d",
                    )) {
                      for (BluetoothCharacteristic char
                          in service.characteristics) {
                        if (char.uuid.toString().toLowerCase().startsWith(
                          "2a37",
                        )) {
                          if (char.properties.notify) {
                            await char.setNotifyValue(true);
                            print("Notifications enabled for 2A37");
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                            _characteristicSubscription?.cancel();
                            _characteristicSubscription = char.value.listen(
                              (data) {
                                print("Raw heart rate data: $data");
                                if (data.isNotEmpty) {
                                  // Parse up to 4 bytes (little-endian)
                                  int heartRate = 0;
                                  for (
                                    int i = 0;
                                    i < data.length && i < 4;
                                    i++
                                  ) {
                                    heartRate |= (data[i] << (i * 8));
                                  }
                                  if (heartRate >= 60 && heartRate <= 100) {
                                    onHeartRateUpdate(heartRate.toString());
                                    print("Heart rate: $heartRate");
                                  } else {
                                    print("Invalid heart rate: $heartRate");
                                  }
                                }
                              },
                              onError: (e) {
                                print("Characteristic error: $e");
                              },
                            );
                            _showMessage("Connected to NanoHRM", onMessage);
                            onFetchingStateChange(false);
                            return;
                          }
                        }
                      }
                    }
                  }
                  print("Heart rate service not found");
                  _isConnected = false;
                  await _device!.disconnect();
                  break;
                } catch (e) {
                  print("Connection error, attempt $attempt: $e");
                  _isConnected = false;
                  await _device?.disconnect();
                  if (attempt == 3) {
                    _showMessage(
                      "Please ensure NanoHRM is turned on",
                      onMessage,
                    );
                    onFetchingStateChange(false);
                    break;
                  }
                  await Future.delayed(const Duration(seconds: 2));
                }
              }
              return;
            }
          }
        },
        onError: (e) {
          print("Scan error: $e");
          _showMessage("Scan failed", onMessage);
          onFetchingStateChange(false);
        },
      ) as StreamSubscription<ScanResult>?;
    } catch (e) {
      print("Unexpected Bluetooth error: $e");
      _showMessage("Bluetooth error occurred", onMessage);
      onFetchingStateChange(false);
    }
  }

  void _showMessage(String message, Function(String) onMessage) {
    if (_lastMessage != message) {
      onMessage(message);
      _lastMessage = message;
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _scanTimer?.cancel();
    _device?.disconnect();
    _isConnected = false;
    _lastMessage = null;
  }
}
