// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_pharmacy/home_page.dart';
// import 'package:flutter_application_pharmacy/models/user_model.dart';
// import 'package:flutter_application_pharmacy/screens/health_info_form.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';

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
//         return;
//       }
//     }

//     if (userModel.role != 'Patient') {
//       print("User is not a patient: ${userModel.role}");
//       return;
//     }

//     print("User is a patient, attempting Bluetooth connection...");
//     _isConnecting = true;
//     onFetchingStateChange(true);

//     try {
//       if (!(await FlutterBluePlus.isSupported)) {
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

//       List<BluetoothDevice> connectedDevices =
//           await FlutterBluePlus.connectedDevices;
//       if (connectedDevices.isEmpty) {
//         if (isRefresh) {
//           onMessage("Please connect to a Bluetooth device");
//         }
//         return;
//       }

//       _device = connectedDevices.first;
//       print("Connecting to: ${_device!.name} (${_device!.id})");

//       BluetoothDeviceState state =
//           (await _device!.state.first) as BluetoothDeviceState;
//       if (state != BluetoothDeviceState.connected) {
//         print("Device not connected, establishing connection...");
//         await _device!.connect(timeout: const Duration(seconds: 15));
//       } else {
//         print("Device already connected: ${_device!.name}");
//       }

//       await _discoverHeartRateService(docId, onHeartRateUpdate, onMessage);
//     } catch (e) {
//       print("Bluetooth connection error: $e");
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
//       return;
//     }

//     print("Discovering services on ${_device!.name}...");
//     try {
//       List<BluetoothService> services = await _device!.discoverServices();
//       print("Found ${services.length} services");

//       bool heartRateServiceFound = false;

//       for (BluetoothService service in services) {
//         for (BluetoothCharacteristic characteristic
//             in service.characteristics) {
//           if (characteristic.uuid.toString() ==
//                   "00002a37-0000-1000-8000-00805f9b34fb" &&
//               characteristic.properties.notify) {
//             heartRateServiceFound = true;
//             print("Found heart rate characteristic: ${characteristic.uuid}");

//             await characteristic.setNotifyValue(true);
//             characteristic.value.listen(
//               (value) {
//                 if (value.isNotEmpty) {
//                   int hr = value[1];
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
//               },
//             );
//             break;
//           }
//         }
//         if (heartRateServiceFound) break;
//       }
//     } catch (e) {
//       print("Service discovery error: $e");
//     }
//   }

//   void disconnect() {
//     _device?.disconnect();
//     _device = null;
//     _isConnecting = false;
//   }
// }

// class ReportsPage extends StatefulWidget {
//   final String userName;
//   const ReportsPage({super.key, required this.userName});

//   @override
//   _ReportsPageState createState() => _ReportsPageState();
// }

// class _ReportsPageState extends State<ReportsPage>
//     with SingleTickerProviderStateMixin {
//   String _heartRate = "97";
//   String _weight = "103";
//   String _bloodGroup = "A+";
//   bool _isFetching = false;
//   bool _isLoading = false;
//   String? _docId;
//   late BluetoothManager _bluetoothManager;

//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     print("ReportsPage - Initializing...");
//     _bluetoothManager = BluetoothManager();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _animationController.forward();
//     _loadHealthData();
//     _autoConnectToBluetooth();
//     _checkAndDownloadWeeklyReport();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _autoConnectToBluetooth();
//   }

//   @override
//   void dispose() {
//     _bluetoothManager.disconnect();
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadHealthData() async {
//     print("ReportsPage - Loading health data...");
//     setState(() => _isLoading = true);
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       print("No user logged in.");
//       setState(
//         () => _isLoading = false,
//       ); // Fixed typo: _iplexLoading -> _isLoading
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please sign in to view reports')),
//       );
//       return;
//     }

//     try {
//       QuerySnapshot userQuery =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .where('email', isEqualTo: user.email)
//               .limit(1)
//               .get();

//       if (userQuery.docs.isNotEmpty) {
//         _docId = userQuery.docs.first.id;
//         final doc =
//             await FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(_docId)
//                 .collection('health_info')
//                 .doc('data')
//                 .get();

//         print("Firestore response - Exists: ${doc.exists}");
//         if (doc.exists) {
//           final data = doc.data();
//           setState(() {
//             _weight = data?['weight'] ?? "103";
//             _bloodGroup = data?['bloodGroup'] ?? "A+";
//             _heartRate = data?['heartRate'] ?? "97";
//             print(
//               "ReportsPage - Data loaded: Weight: $_weight, Blood Group: $_bloodGroup, Heart Rate: $_heartRate, DocId: $_docId",
//             );
//           });
//         } else {
//           print("No data found at path. Using defaults.");
//         }
//       }
//     } catch (e) {
//       print("Error loading health data: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _autoConnectToBluetooth() async {
//     await _bluetoothManager.connectToBluetooth(
//       context: context,
//       docId: _docId ?? '',
//       onHeartRateUpdate: (heartRate) {
//         setState(() {
//           _heartRate = heartRate;
//           _isFetching = false;
//         });
//       },
//       onMessage: (message) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(message)));
//       },
//       onFetchingStateChange: (isFetching) {
//         setState(() => _isFetching = isFetching);
//       },
//       isRefresh: false,
//     );
//   }

//   void _editHealthInfo() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => HealthInfoForm(userName: widget.userName),
//       ),
//     ).then((_) => _loadHealthData());
//   }

//   Future<void> _checkAndDownloadWeeklyReport() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null || _docId == null) return;

//     final now = DateTime.now();
//     final isSundayMidnight =
//         now.weekday == DateTime.sunday && now.hour == 0 && now.minute < 5;

//     if (!isSundayMidnight) return;

//     try {
//       final userDoc =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(_docId)
//               .get();
//       final linkedDocId = userDoc.data()?['linkedDocId'] as String?;

//       final timeFrame = DateTime.now().subtract(const Duration(days: 7));
//       final timestamp = Timestamp.fromDate(timeFrame);
//       final querySnapshot =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(_docId)
//               .collection('reminders')
//               .where('timestamp', isGreaterThan: timestamp)
//               .get();

//       final reminders =
//           querySnapshot.docs.map((doc) {
//             final data = doc.data();
//             return {
//               'medicine': data['medicine'] ?? 'Unknown',
//               'dosage': data['dosage'] ?? 'N/A',
//               'times': (data['times'] as List? ?? [])
//                   .map((t) => t.toString())
//                   .join(', '),
//               'isDaily': data['isDaily'] ?? true,
//               'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
//               'taken': data['taken'] ?? false,
//             };
//           }).toList();

//       String reportContent =
//           "Weekly Health Report (${DateFormat('MMM d, yyyy').format(timeFrame)} - ${DateFormat('MMM d, yyyy').format(now)})\n\n";
//       for (var reminder in reminders) {
//         reportContent += "Medicine: ${reminder['medicine']}\n";
//         reportContent += "Dosage: ${reminder['dosage']}\n";
//         reportContent += "Times: ${reminder['times']}\n";
//         reportContent +=
//             "Frequency: ${reminder['isDaily'] ? 'Daily' : 'Weekly'}\n";
//         reportContent +=
//             "Status: ${reminder['taken'] ? 'Taken' : 'Not Taken'}\n";
//         reportContent +=
//             "Added: ${reminder['timestamp'] != null ? DateFormat('MMM d, h:mm a').format(reminder['timestamp'] as DateTime) : 'N/A'}\n\n";
//       }

//       final directory = await getApplicationDocumentsDirectory();
//       final patientFile = File(
//         '${directory.path}/weekly_report_${_docId}_${now.millisecondsSinceEpoch}.txt',
//       );
//       await patientFile.writeAsString(reportContent);
//       print("Report saved for patient at: ${patientFile.path}");

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Weekly report downloaded to ${patientFile.path}'),
//           ),
//         );
//       }

//       if (linkedDocId != null && linkedDocId.isNotEmpty) {
//         final caretakerFile = File(
//           '${directory.path}/weekly_report_${linkedDocId}_${now.millisecondsSinceEpoch}.txt',
//         );
//         await caretakerFile.writeAsString(reportContent);
//         print("Report saved for caretaker at: ${caretakerFile.path}");
//       }
//     } catch (e) {
//       print("Error downloading weekly report: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error downloading report: $e')));
//       }
//     }
//   }

//   Future<bool> _onWillPop() async {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => HomePage(userName: widget.userName),
//       ),
//     );
//     return false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     print("ReportsPage - Building UI...");
//     final user = FirebaseAuth.instance.currentUser;
//     final userModel = Provider.of<UserModel>(context);
//     final isPatient = userModel.role == 'Patient';

//     if (user == null) {
//       return const Center(child: Text('Please log in to view reports.'));
//     }

//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: Colors.grey[100],
//         appBar: AppBar(
//           toolbarHeight: 56,
//           title: const Text(
//             'Health Reports',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w600,
//               color: Colors.white,
//             ),
//           ),
//           centerTitle: true,
//           backgroundColor: Colors.blueAccent,
//           elevation: 0,
//           flexibleSpace: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.blueAccent, Colors.lightBlueAccent],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//         ),
//         body:
//             _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 24),
//                       Stack(
//                         children: [
//                           InfoCard(
//                             title: "Heart Rate",
//                             value: _isFetching ? "Fetching..." : _heartRate,
//                             unit: "bpm",
//                             icon: Icons.monitor_heart,
//                             color: Colors.blue.shade100,
//                           ),
//                           if (isPatient)
//                             Positioned(
//                               right: 8,
//                               top: 8,
//                               child: IconButton(
//                                 icon: const Icon(
//                                   Icons.refresh,
//                                   color: Colors.blueAccent,
//                                 ),
//                                 onPressed: () async {
//                                   await _bluetoothManager.connectToBluetooth(
//                                     context: context,
//                                     docId: _docId ?? '',
//                                     onHeartRateUpdate: (heartRate) {
//                                       setState(() {
//                                         _heartRate = heartRate;
//                                         _isFetching = false;
//                                       });
//                                     },
//                                     onMessage: (message) {
//                                       ScaffoldMessenger.of(
//                                         context,
//                                       ).showSnackBar(
//                                         SnackBar(content: Text(message)),
//                                       );
//                                     },
//                                     onFetchingStateChange: (isFetching) {
//                                       setState(() => _isFetching = isFetching);
//                                     },
//                                     isRefresh: true,
//                                   );
//                                 },
//                               ),
//                             ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: GestureDetector(
//                               onLongPress: _editHealthInfo,
//                               child: InfoCard(
//                                 title: "Weight",
//                                 value: _weight,
//                                 unit: "lbs",
//                                 icon: Icons.scale,
//                                 color: Colors.grey.shade300,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 20),
//                           Expanded(
//                             child: GestureDetector(
//                               onLongPress: _editHealthInfo,
//                               child: InfoCard(
//                                 title: "Blood Group",
//                                 value: _bloodGroup,
//                                 unit: "",
//                                 icon: Icons.water_drop,
//                                 color: Colors.red.shade200,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 30),
//                       const Text(
//                         "Latest Reports",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.blueGrey,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Expanded(
//                         child: _LatestReportsSection(
//                           userName: widget.userName,
//                           docId: _docId,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//       ),
//     );
//   }
// }

// class InfoCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final String unit;
//   final IconData icon;
//   final Color color;

//   const InfoCard({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.unit,
//     required this.icon,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       color: color,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             Icon(icon, size: 40, color: Colors.blueAccent),
//             const SizedBox(width: 16),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   "$value $unit",
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _LatestReportsSection extends StatefulWidget {
//   final String userName;
//   final String? docId;

//   const _LatestReportsSection({required this.userName, required this.docId});

//   @override
//   __LatestReportsSectionState createState() => __LatestReportsSectionState();

//   static __LatestReportsSectionState? of(BuildContext context) {
//     return context.findAncestorStateOfType<__LatestReportsSectionState>();
//   }
// }

// class __LatestReportsSectionState extends State<_LatestReportsSection>
//     with SingleTickerProviderStateMixin {
//   String _filter = 'All';
//   bool _showDaily = true;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   List<Map<String, dynamic>> _reminders = [];
//   late ScrollController _scrollController;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _animationController.forward();
//     _scrollController = ScrollController();
//     _subscribeToReminders();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _subscribeToReminders() {
//     if (widget.docId == null) return;

//     final timeFrame =
//         _showDaily
//             ? DateTime.now().subtract(const Duration(days: 1))
//             : DateTime.now().subtract(const Duration(days: 7));
//     final timestamp = Timestamp.fromDate(timeFrame);

//     FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.docId)
//         .collection('reminders')
//         .where('timestamp', isGreaterThan: timestamp)
//         .snapshots()
//         .listen(
//           (snapshot) {
//             final reminders =
//                 snapshot.docs.map((doc) {
//                   final data = doc.data();
//                   return {
//                     'id': doc.id,
//                     'medicine': data['medicine'] ?? 'Unknown',
//                     'dosage': data['dosage'] ?? 'N/A',
//                     'times': (data['times'] as List? ?? [])
//                         .map((t) => t.toString())
//                         .join(', '),
//                     'isDaily': data['isDaily'] ?? true,
//                     'timestamp': data['timestamp'] as Timestamp?,
//                     'taken': data['taken'] ?? false,
//                   };
//                 }).toList();

//             setState(() {
//               _reminders = reminders;
//               print("Reminders updated silently: ${_reminders.length}");
//             });
//           },
//           onError: (e) {
//             print("Error subscribing to reminders: $e");
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Error fetching reminders: $e')),
//             );
//           },
//         );
//   }

//   Widget _buildFilterButton(String label) {
//     return GestureDetector(
//       onTap: () => setState(() => _filter = label),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         width: 90,
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         decoration: BoxDecoration(
//           color: _filter == label ? Colors.blueAccent : Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(10),
//           boxShadow:
//               _filter == label
//                   ? [
//                     BoxShadow(
//                       color: Colors.blueAccent.withOpacity(0.3),
//                       blurRadius: 4,
//                     ),
//                   ]
//                   : [],
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 14,
//               color: _filter == label ? Colors.white : Colors.black87,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildToggleSwitch() {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         color: Colors.grey.shade100,
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           GestureDetector(
//             onTap: () {
//               if (!_showDaily) {
//                 setState(() {
//                   _showDaily = true;
//                 });
//                 _subscribeToReminders();
//               }
//             },
//             child: Container(
//               width: 90,
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               decoration: BoxDecoration(
//                 color: _showDaily ? Colors.blueAccent : Colors.grey.shade100,
//                 borderRadius: const BorderRadius.horizontal(
//                   left: Radius.circular(10),
//                 ),
//               ),
//               child: Center(
//                 child: Text(
//                   'Daily',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: _showDaily ? Colors.white : Colors.black87,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           GestureDetector(
//             onTap: () {
//               if (_showDaily) {
//                 setState(() {
//                   _showDaily = false;
//                 });
//                 _subscribeToReminders();
//               }
//             },
//             child: Container(
//               width: 90,
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               decoration: BoxDecoration(
//                 color: !_showDaily ? Colors.blueAccent : Colors.grey.shade100,
//                 borderRadius: const BorderRadius.horizontal(
//                   right: Radius.circular(10),
//                 ),
//               ),
//               child: Center(
//                 child: Text(
//                   'Weekly',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: !_showDaily ? Colors.white : Colors.black87,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showReminderDetails(
//     BuildContext context,
//     Map<String, dynamic> reminder,
//   ) {
//     final isTaken = reminder['taken'] as bool;
//     final timestamp = (reminder['timestamp'] as Timestamp?)?.toDate();
//     final dateString =
//         timestamp != null
//             ? DateFormat('MMM d, h:mm a').format(timestamp)
//             : 'N/A';

//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 26,
//                     backgroundColor:
//                         isTaken
//                             ? Colors.green.withOpacity(0.1)
//                             : Colors.red.withOpacity(0.1),
//                     child: Icon(
//                       isTaken ? Icons.check_circle : Icons.warning,
//                       color: isTaken ? Colors.green : Colors.red,
//                       size: 32,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       reminder['medicine'],
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Dosage: ${reminder['dosage']}',
//                 style: const TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 'Times: ${reminder['times']}',
//                 style: const TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 'Frequency: ${reminder['isDaily'] ? 'Daily' : 'Weekly'}',
//                 style: const TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 'Added: $dateString',
//                 style: const TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 'Status: ${isTaken ? 'Taken' : 'Not Taken'}',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: isTaken ? Colors.green : Colors.red,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     elevation: 2,
//                   ),
//                   child: const Text(
//                     'Close',
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredReminders =
//         _filter == 'All'
//             ? _reminders
//             : _filter == 'Taken'
//             ? _reminders.where((r) => r['taken'] as bool).toList()
//             : _reminders.where((r) => !(r['taken'] as bool)).toList();

//     final sortedReminders =
//         filteredReminders..sort(
//           (a, b) => (b['timestamp'] as Timestamp).compareTo(
//             a['timestamp'] as Timestamp,
//           ),
//         );

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Center(child: _buildToggleSwitch()),
//         const SizedBox(height: 12),
//         Center(
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildFilterButton('All'),
//               const SizedBox(width: 10),
//               _buildFilterButton('Taken'),
//               const SizedBox(width: 10),
//               _buildFilterButton('Not Taken'),
//             ],
//           ),
//         ),
//         const SizedBox(height: 20),
//         FadeTransition(
//           opacity: _fadeAnimation,
//           child: Card(
//             elevation: 2,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             color: Colors.grey.shade50,
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Compliance Overview',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   if (_reminders.isEmpty)
//                     const SizedBox.shrink()
//                   else
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '${_reminders.isNotEmpty ? (_reminders.where((r) => r['taken'] as bool).length / _reminders.length * 100).toStringAsFixed(1) : '0'}%',
//                               style: const TextStyle(
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blueAccent,
//                               ),
//                             ),
//                             const Text(
//                               'Compliance Rate',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '${_reminders.where((r) => r['taken'] as bool).length}/${_reminders.length}',
//                               style: const TextStyle(
//                                 fontSize: 22,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green,
//                               ),
//                             ),
//                             const Text(
//                               'Taken/Total',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 20),
//         Expanded(
//           child:
//               sortedReminders.isEmpty
//                   ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.info_outline,
//                           size: 60,
//                           color: Colors.grey[400],
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           _showDaily
//                               ? 'No reminders added today.'
//                               : 'No reminders added in the past week.',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                   : SingleChildScrollView(
//                     controller: _scrollController,
//                     child: Column(
//                       children:
//                           sortedReminders.map((reminder) {
//                             final isTaken = reminder['taken'] as bool;
//                             final timestamp =
//                                 (reminder['timestamp'] as Timestamp?)?.toDate();
//                             final dateString =
//                                 timestamp != null
//                                     ? DateFormat(
//                                       'MMM d, h:mm a',
//                                     ).format(timestamp)
//                                     : 'N/A';

//                             return FadeTransition(
//                               opacity: _fadeAnimation,
//                               child: GestureDetector(
//                                 onTap:
//                                     () =>
//                                         _showReminderDetails(context, reminder),
//                                 child: Card(
//                                   elevation: 2,
//                                   margin: const EdgeInsets.symmetric(
//                                     vertical: 6,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   color: Colors.grey.shade50,
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(12),
//                                     child: Row(
//                                       children: [
//                                         CircleAvatar(
//                                           radius: 20,
//                                           backgroundColor:
//                                               isTaken
//                                                   ? Colors.green.withOpacity(
//                                                     0.1,
//                                                   )
//                                                   : Colors.red.withOpacity(0.1),
//                                           child: Icon(
//                                             isTaken
//                                                 ? Icons.check_circle
//                                                 : Icons.warning,
//                                             color:
//                                                 isTaken
//                                                     ? Colors.green
//                                                     : Colors.red,
//                                             size: 24,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 12),
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 reminder['medicine'],
//                                                 style: const TextStyle(
//                                                   fontSize: 18,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black87,
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 2),
//                                               Text(
//                                                 '${reminder['dosage']} • ${reminder['times']}',
//                                                 style: const TextStyle(
//                                                   fontSize: 14,
//                                                   color: Colors.grey,
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 2),
//                                               Text(
//                                                 'Added: $dateString',
//                                                 style: const TextStyle(
//                                                   fontSize: 12,
//                                                   color: Colors.grey,
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 6),
//                                               Container(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                       horizontal: 10,
//                                                       vertical: 4,
//                                                     ),
//                                                 decoration: BoxDecoration(
//                                                   color:
//                                                       isTaken
//                                                           ? Colors.green
//                                                               .withOpacity(0.1)
//                                                           : Colors.red
//                                                               .withOpacity(0.1),
//                                                   borderRadius:
//                                                       BorderRadius.circular(6),
//                                                 ),
//                                                 child: Text(
//                                                   isTaken
//                                                       ? 'Taken'
//                                                       : 'Not Taken',
//                                                   style: TextStyle(
//                                                     fontSize: 12,
//                                                     color:
//                                                         isTaken
//                                                             ? Colors.green
//                                                             : Colors.red,
//                                                     fontWeight: FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                     ),
//                   ),
//         ),
//       ],
//     );
//   }
// }

// class RemindersScreen extends StatelessWidget {
//   const RemindersScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Reminders')),
//       body: const Center(child: Text('Reminders Page')),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_pharmacy/home_page.dart';
import 'package:flutter_application_pharmacy/models/user_model.dart';
import 'package:flutter_application_pharmacy/screens/health_info_form.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class BluetoothManager {
  BluetoothDevice? _device;
  bool _isConnecting = false;
  bool _hasShownInitialMessage = false;

  Future<void> connectToBluetooth({
    required BuildContext context,
    required String docId,
    required Function(String) onHeartRateUpdate,
    required Function(String) onMessage,
    required Function(bool) onFetchingStateChange,
    required bool isRefresh,
  }) async {
    if (_isConnecting) {
      print("Already attempting Bluetooth connection, skipping...");
      return;
    }

    final userModel = Provider.of<UserModel>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No authenticated user found.");
      return;
    }

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
        return;
      }
    }

    if (userModel.role != 'Patient') {
      print("User is not a patient: ${userModel.role}");
      return;
    }

    print("User is a patient, attempting Bluetooth connection...");
    _isConnecting = true;
    onFetchingStateChange(true);

    try {
      if (!(await FlutterBluePlus.isSupported)) {
        return;
      }

      if (!(await FlutterBluePlus.isOn)) {
        if (!_hasShownInitialMessage && !isRefresh) {
          onMessage("Please turn on Bluetooth");
          _hasShownInitialMessage = true;
        } else if (isRefresh) {
          onMessage("Please turn on Bluetooth");
        }
        return;
      }

      List<BluetoothDevice> connectedDevices =
          await FlutterBluePlus.connectedDevices;
      if (connectedDevices.isEmpty) {
        if (isRefresh) {
          onMessage("Please connect to a Bluetooth device");
        }
        return;
      }

      _device = connectedDevices.first;
      print("Connecting to: ${_device!.name} (${_device!.id})");

      BluetoothDeviceState state =
          (await _device!.state.first) as BluetoothDeviceState;
      if (state != BluetoothDeviceState.connected) {
        print("Device not connected, establishing connection...");
        await _device!.connect(timeout: const Duration(seconds: 15));
      } else {
        print("Device already connected: ${_device!.name}");
      }

      await _discoverHeartRateService(docId, onHeartRateUpdate, onMessage);
    } catch (e) {
      print("Bluetooth connection error: $e");
    } finally {
      _isConnecting = false;
      onFetchingStateChange(false);
    }
  }

  Future<void> _discoverHeartRateService(
    String docId,
    Function(String) onHeartRateUpdate,
    Function(String) onMessage,
  ) async {
    if (_device == null) {
      print("No device available for service discovery");
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
          if (characteristic.uuid.toString() ==
                  "00002a37-0000-1000-8000-00805f9b34fb" &&
              characteristic.properties.notify) {
            heartRateServiceFound = true;
            print("Found heart rate characteristic: ${characteristic.uuid}");

            await characteristic.setNotifyValue(true);
            characteristic.value.listen(
              (value) {
                if (value.isNotEmpty) {
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
              },
            );
            break;
          }
        }
        if (heartRateServiceFound) break;
      }
    } catch (e) {
      print("Service discovery error: $e");
    }
  }

  void disconnect() {
    _device?.disconnect();
    _device = null;
    _isConnecting = false;
  }
}

class ReportsPage extends StatefulWidget {
  final String userName;
  const ReportsPage({super.key, required this.userName});

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  String _heartRate = "97";
  String _weight = "103";
  String _bloodGroup = "A+";
  bool _isFetching = false;
  bool _isLoading = false;
  String? _docId;
  late BluetoothManager _bluetoothManager;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print("ReportsPage - Initializing...");
    _bluetoothManager = BluetoothManager();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadHealthData();
    _autoConnectToBluetooth();
    _checkAndDownloadWeeklyReport();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoConnectToBluetooth();
  }

  @override
  void dispose() {
    _bluetoothManager.disconnect();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthData() async {
    print("ReportsPage - Loading health data...");
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in.");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to view reports')),
      );
      return;
    }

    try {
      QuerySnapshot userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();

      if (userQuery.docs.isNotEmpty) {
        _docId = userQuery.docs.first.id;
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_docId)
                .collection('health_info')
                .doc('data')
                .get();

        print("Firestore response - Exists: ${doc.exists}, Doc: $doc");
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _weight = data?['weight'] ?? "103";
            _bloodGroup = data?['bloodGroup'] ?? "A+";
            _heartRate = data?['heartRate'] ?? "97";
            print(
              "ReportsPage - Data loaded: Weight: $_weight, Blood Group: $_bloodGroup, Heart Rate: $_heartRate, DocId: $_docId",
            );
          });
        } else {
          print("No data found at path. Using defaults.");
          setState(() {
            _weight = "103";
            _bloodGroup = "A+";
            _heartRate = "97";
          });
        }
      } else {
        print("No user document found for email: ${user.email}");
      }
    } catch (e) {
      print("Error loading health data: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _autoConnectToBluetooth() async {
    await _bluetoothManager.connectToBluetooth(
      context: context,
      docId: _docId ?? '',
      onHeartRateUpdate: (heartRate) {
        setState(() {
          _heartRate = heartRate;
          _isFetching = false;
        });
      },
      onMessage: (message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      onFetchingStateChange: (isFetching) {
        setState(() => _isFetching = isFetching);
      },
      isRefresh: false,
    );
  }

  void _editHealthInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthInfoForm(userName: widget.userName),
      ),
    ).then((value) {
      if (value == true) {
        _loadHealthData(); // Reload data immediately after saving
      }
    });
  }

  Future<void> _checkAndDownloadWeeklyReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _docId == null) return;

    final now = DateTime.now();
    final isSundayMidnight =
        now.weekday == DateTime.sunday && now.hour == 0 && now.minute < 5;

    if (!isSundayMidnight) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_docId)
              .get();
      final linkedDocId = userDoc.data()?['linkedDocId'] as String?;

      final timeFrame = DateTime.now().subtract(const Duration(days: 7));
      final timestamp = Timestamp.fromDate(timeFrame);
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_docId)
              .collection('reminders')
              .where('timestamp', isGreaterThan: timestamp)
              .get();

      final reminders =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'medicine': data['medicine'] ?? 'Unknown',
              'dosage': data['dosage'] ?? 'N/A',
              'times': (data['times'] as List? ?? [])
                  .map((t) => t.toString())
                  .join(', '),
              'isDaily': data['isDaily'] ?? true,
              'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
              'taken': data['taken'] ?? false,
            };
          }).toList();

      String reportContent =
          "Weekly Health Report (${DateFormat('MMM d, yyyy').format(timeFrame)} - ${DateFormat('MMM d, yyyy').format(now)})\n\n";
      for (var reminder in reminders) {
        reportContent += "Medicine: ${reminder['medicine']}\n";
        reportContent += "Dosage: ${reminder['dosage']}\n";
        reportContent += "Times: ${reminder['times']}\n";
        reportContent +=
            "Frequency: ${reminder['isDaily'] ? 'Daily' : 'Weekly'}\n";
        reportContent +=
            "Status: ${reminder['taken'] ? 'Taken' : 'Not Taken'}\n";
        reportContent +=
            "Added: ${reminder['timestamp'] != null ? DateFormat('MMM d, h:mm a').format(reminder['timestamp'] as DateTime) : 'N/A'}\n\n";
      }

      final directory = await getApplicationDocumentsDirectory();
      final patientFile = File(
        '${directory.path}/weekly_report_${_docId}_${now.millisecondsSinceEpoch}.txt',
      );
      await patientFile.writeAsString(reportContent);
      print("Report saved for patient at: ${patientFile.path}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weekly report downloaded to ${patientFile.path}'),
          ),
        );
      }

      if (linkedDocId != null && linkedDocId.isNotEmpty) {
        final caretakerFile = File(
          '${directory.path}/weekly_report_${linkedDocId}_${now.millisecondsSinceEpoch}.txt',
        );
        await caretakerFile.writeAsString(reportContent);
        print("Report saved for caretaker at: ${caretakerFile.path}");
      }
    } catch (e) {
      print("Error downloading weekly report: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error downloading report: $e')));
      }
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(userName: widget.userName),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    print("ReportsPage - Building UI...");
    final user = FirebaseAuth.instance.currentUser;
    final userModel = Provider.of<UserModel>(context);
    final isPatient = userModel.role == 'Patient';

    if (user == null) {
      return const Center(child: Text('Please log in to view reports.'));
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          toolbarHeight: 56,
          title: const Text(
            'Health Reports',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Stack(
                        children: [
                          InfoCard(
                            title: "Heart Rate",
                            value: _isFetching ? "Fetching..." : _heartRate,
                            unit: "bpm",
                            icon: Icons.monitor_heart,
                            color: Colors.blue.shade100,
                          ),
                          if (isPatient)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () async {
                                  await _bluetoothManager.connectToBluetooth(
                                    context: context,
                                    docId: _docId ?? '',
                                    onHeartRateUpdate: (heartRate) {
                                      setState(() {
                                        _heartRate = heartRate;
                                        _isFetching = false;
                                      });
                                    },
                                    onMessage: (message) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                    },
                                    onFetchingStateChange: (isFetching) {
                                      setState(() => _isFetching = isFetching);
                                    },
                                    isRefresh: true,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onLongPress: _editHealthInfo,
                              child: InfoCard(
                                title: "Weight",
                                value: _weight,
                                unit: "lbs",
                                icon: Icons.scale,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: GestureDetector(
                              onLongPress: _editHealthInfo,
                              child: InfoCard(
                                title: "Blood Group",
                                value: _bloodGroup,
                                unit: "",
                                icon: Icons.water_drop,
                                color: Colors.red.shade200,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Latest Reports",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _LatestReportsSection(
                          userName: widget.userName,
                          docId: _docId,
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "$value $unit",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestReportsSection extends StatefulWidget {
  final String userName;
  final String? docId;

  const _LatestReportsSection({required this.userName, required this.docId});

  @override
  __LatestReportsSectionState createState() => __LatestReportsSectionState();

  static __LatestReportsSectionState? of(BuildContext context) {
    return context.findAncestorStateOfType<__LatestReportsSectionState>();
  }
}

class __LatestReportsSectionState extends State<_LatestReportsSection>
    with SingleTickerProviderStateMixin {
  String _filter = 'All';
  bool _showDaily = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> _reminders = [];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _scrollController = ScrollController();
    _subscribeToReminders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToReminders() {
    if (widget.docId == null) return;

    final timeFrame =
        _showDaily
            ? DateTime.now().subtract(const Duration(days: 1))
            : DateTime.now().subtract(const Duration(days: 7));
    final timestamp = Timestamp.fromDate(timeFrame);

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.docId)
        .collection('reminders')
        .where('timestamp', isGreaterThan: timestamp)
        .snapshots()
        .listen(
          (snapshot) {
            final reminders =
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  return {
                    'id': doc.id,
                    'medicine': data['medicine'] ?? 'Unknown',
                    'dosage': data['dosage'] ?? 'N/A',
                    'times': (data['times'] as List? ?? [])
                        .map((t) => t.toString())
                        .join(', '),
                    'isDaily': data['isDaily'] ?? true,
                    'timestamp': data['timestamp'] as Timestamp?,
                    'taken': data['taken'] ?? false,
                  };
                }).toList();

            setState(() {
              _reminders = reminders;
              print("Reminders updated silently: ${_reminders.length}");
            });
          },
          onError: (e) {
            print("Error subscribing to reminders: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error fetching reminders: $e')),
            );
          },
        );
  }

  Widget _buildFilterButton(String label) {
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _filter == label ? Colors.blueAccent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          boxShadow:
              _filter == label
                  ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ]
                  : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: _filter == label ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (!_showDaily) {
                setState(() {
                  _showDaily = true;
                });
                _subscribeToReminders();
              }
            },
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _showDaily ? Colors.blueAccent : Colors.grey.shade100,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
              ),
              child: Center(
                child: Text(
                  'Daily',
                  style: TextStyle(
                    fontSize: 14,
                    color: _showDaily ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_showDaily) {
                setState(() {
                  _showDaily = false;
                });
                _subscribeToReminders();
              }
            },
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !_showDaily ? Colors.blueAccent : Colors.grey.shade100,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
              ),
              child: Center(
                child: Text(
                  'Weekly',
                  style: TextStyle(
                    fontSize: 14,
                    color: !_showDaily ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderDetails(
    BuildContext context,
    Map<String, dynamic> reminder,
  ) {
    final isTaken = reminder['taken'] as bool;
    final timestamp = (reminder['timestamp'] as Timestamp?)?.toDate();
    final dateString =
        timestamp != null
            ? DateFormat('MMM d, h:mm a').format(timestamp)
            : 'N/A';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        isTaken
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    child: Icon(
                      isTaken ? Icons.check_circle : Icons.warning,
                      color: isTaken ? Colors.green : Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reminder['medicine'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Dosage: ${reminder['dosage']}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                'Times: ${reminder['times']}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                'Frequency: ${reminder['isDaily'] ? 'Daily' : 'Weekly'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                'Added: $dateString',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                'Status: ${isTaken ? 'Taken' : 'Not Taken'}',
                style: TextStyle(
                  fontSize: 14,
                  color: isTaken ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReminders =
        _filter == 'All'
            ? _reminders
            : _filter == 'Taken'
            ? _reminders.where((r) => r['taken'] as bool).toList()
            : _reminders.where((r) => !(r['taken'] as bool)).toList();

    final sortedReminders =
        filteredReminders..sort(
          (a, b) => (b['timestamp'] as Timestamp).compareTo(
            a['timestamp'] as Timestamp,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _buildToggleSwitch()),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterButton('All'),
              const SizedBox(width: 10),
              _buildFilterButton('Taken'),
              const SizedBox(width: 10),
              _buildFilterButton('Not Taken'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compliance Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_reminders.isEmpty)
                    const SizedBox.shrink()
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_reminders.isNotEmpty ? (_reminders.where((r) => r['taken'] as bool).length / _reminders.length * 100).toStringAsFixed(1) : '0'}%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold, // Fixed typo here
                                color: Colors.blueAccent,
                              ),
                            ),
                            const Text(
                              'Compliance Rate',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_reminders.where((r) => r['taken'] as bool).length}/${_reminders.length}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'Taken/Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child:
              sortedReminders.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _showDaily
                              ? 'No reminders added today.'
                              : 'No reminders added in the past week.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                  : SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children:
                          sortedReminders.map((reminder) {
                            final isTaken = reminder['taken'] as bool;
                            final timestamp =
                                (reminder['timestamp'] as Timestamp?)?.toDate();
                            final dateString =
                                timestamp != null
                                    ? DateFormat(
                                      'MMM d, h:mm a',
                                    ).format(timestamp)
                                    : 'N/A';

                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: GestureDetector(
                                onTap:
                                    () =>
                                        _showReminderDetails(context, reminder),
                                child: Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  color: Colors.grey.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              isTaken
                                                  ? Colors.green.withOpacity(
                                                    0.1,
                                                  )
                                                  : Colors.red.withOpacity(0.1),
                                          child: Icon(
                                            isTaken
                                                ? Icons.check_circle
                                                : Icons.warning,
                                            color:
                                                isTaken
                                                    ? Colors.green
                                                    : Colors.red,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reminder['medicine'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${reminder['dosage']} • ${reminder['times']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Added: $dateString',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isTaken
                                                          ? Colors.green
                                                              .withOpacity(0.1)
                                                          : Colors.red
                                                              .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isTaken
                                                      ? 'Taken'
                                                      : 'Not Taken',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        isTaken
                                                            ? Colors.green
                                                            : Colors.red,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
        ),
      ],
    );
  }
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: const Center(child: Text('Reminders Page')),
    );
  }
}
