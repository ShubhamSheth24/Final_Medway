// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:intl/intl.dart';

// class DoctorProfilePage extends StatefulWidget {
//   final String doctorId;

//   const DoctorProfilePage({super.key, required this.doctorId});

//   @override
//   _DoctorProfilePageState createState() => _DoctorProfilePageState();
// }

// class _DoctorProfilePageState extends State<DoctorProfilePage>
//     with SingleTickerProviderStateMixin {
//   late Future<DocumentSnapshot> _doctorFuture;
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   File? _image;
//   final picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     _doctorFuture =
//         FirebaseFirestore.instance
//             .collection('doctors')
//             .doc(widget.doctorId)
//             .get();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future pickImage() async {
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() => _image = File(pickedFile.path));
//       uploadImage();
//     }
//   }

//   Future uploadImage() async {
//     if (_image == null) return;

//     String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//     Reference storageRef = FirebaseStorage.instance.ref().child(
//       'images/$fileName.jpg',
//     );

//     UploadTask uploadTask = storageRef.putFile(_image!);
//     TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
//     String downloadUrl = await taskSnapshot.ref.getDownloadURL();

//     await _updateDoctorField({"profileImageUrl": downloadUrl});
//     setState(() {
//       _image = null;
//     });
//   }

//   Future<void> _updateDoctorField(Map<String, dynamic> updatedData) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .update(updatedData);
//       setState(() {
//         _doctorFuture =
//             FirebaseFirestore.instance
//                 .collection('doctors')
//                 .doc(widget.doctorId)
//                 .get();
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text("Profile updated successfully!"),
//           backgroundColor: Colors.green[600],
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error updating profile: $e"),
//           backgroundColor: Colors.red[600],
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//       );
//     }
//   }

//   void _editPersonalInfo(
//     String currentLocation,
//     int currentAge,
//     String currentMobile,
//   ) {
//     TextEditingController locationController = TextEditingController(
//       text: currentLocation,
//     );
//     TextEditingController ageController = TextEditingController(
//       text: currentAge.toString(),
//     );
//     TextEditingController mobileController = TextEditingController(
//       text: currentMobile,
//     );

//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text("Edit Personal Information"),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: locationController,
//                     decoration: const InputDecoration(labelText: "Location"),
//                   ),
//                   TextField(
//                     controller: ageController,
//                     decoration: const InputDecoration(labelText: "Age"),
//                     keyboardType: TextInputType.number,
//                   ),
//                   TextField(
//                     controller: mobileController,
//                     decoration: const InputDecoration(labelText: "Mobile"),
//                     keyboardType: TextInputType.phone,
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Cancel"),
//               ),
//               TextButton(
//                 onPressed: () {
//                   _updateDoctorField({
//                     "location": locationController.text.trim(),
//                     "age": int.parse(ageController.text.trim()),
//                     "mobile": mobileController.text.trim(),
//                   });
//                   Navigator.pop(context);
//                 },
//                 child: const Text("Save"),
//               ),
//             ],
//           ),
//     );
//   }

//   void _editAvailableDays(List<String> currentDays) {
//     List<String> allDays = [
//       "Monday",
//       "Tuesday",
//       "Wednesday",
//       "Thursday",
//       "Friday",
//       "Saturday",
//       "Sunday",
//     ];
//     List<bool> daySelection =
//         allDays.map((day) => currentDays.contains(day)).toList();

//     showDialog(
//       context: context,
//       builder:
//           (context) => StatefulBuilder(
//             builder:
//                 (context, setState) => AlertDialog(
//                   title: const Text("Edit Available Days"),
//                   content: SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: List.generate(allDays.length, (index) {
//                         return CheckboxListTile(
//                           title: Text(allDays[index]),
//                           value: daySelection[index],
//                           onChanged: (value) {
//                             setState(() {
//                               daySelection[index] = value!;
//                             });
//                           },
//                         );
//                       }),
//                     ),
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text("Cancel"),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         List<String> selectedDays = [];
//                         for (int i = 0; i < allDays.length; i++) {
//                           if (daySelection[i]) {
//                             selectedDays.add(allDays[i]);
//                           }
//                         }
//                         _updateDoctorField({"availableDays": selectedDays});
//                         Navigator.pop(context);
//                       },
//                       child: const Text("Save"),
//                     ),
//                   ],
//                 ),
//           ),
//     );
//   }

//   void _editAvailableSlots(
//     List<dynamic> currentSlots,
//     List<DateTime> selectedDates,
//   ) {
//     List<String> allSlots = [
//       "9:00 AM",
//       "10:00 AM",
//       "11:00 AM",
//       "12:00 PM",
//       "1:00 PM",
//       "2:00 PM",
//       "3:00 PM",
//       "4:00 PM",
//       "5:00 PM",
//       "6:00 PM",
//       "7:00 PM",
//       "8:00 PM",
//     ];
//     List<bool> slotSelection =
//         allSlots
//             .map((slot) => currentSlots.any((s) => s['time'] == slot))
//             .toList();

//     showDialog(
//       context: context,
//       builder:
//           (context) => StatefulBuilder(
//             builder:
//                 (context, setState) => AlertDialog(
//                   title: const Text("Edit Available Time Slots"),
//                   content: SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: List.generate(3, (rowIndex) {
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 8.0),
//                           child: Row(
//                             children: List.generate(4, (colIndex) {
//                               int index = rowIndex * 4 + colIndex;
//                               final slotTime = allSlots[index];
//                               final now = DateTime.now();
//                               final today = DateTime(
//                                 now.year,
//                                 now.month,
//                                 now.day,
//                               );

//                               bool isTodaySelected = selectedDates.any(
//                                 (d) =>
//                                     d.year == today.year &&
//                                     d.month == today.month &&
//                                     d.day == today.day,
//                               );
//                               bool isPastSlot = false;
//                               if (isTodaySelected) {
//                                 final slotDateTime = _parseTimeSlot(
//                                   slotTime,
//                                   today,
//                                 );
//                                 isPastSlot = slotDateTime.isBefore(now);
//                               }

//                               return Expanded(
//                                 child: Padding(
//                                   padding: EdgeInsets.only(
//                                     right: colIndex < 3 ? 8.0 : 0,
//                                   ),
//                                   child: GestureDetector(
//                                     onTap:
//                                         isPastSlot
//                                             ? null
//                                             : () {
//                                               setState(() {
//                                                 slotSelection[index] =
//                                                     !slotSelection[index];
//                                               });
//                                             },
//                                     child: AnimatedContainer(
//                                       duration: const Duration(
//                                         milliseconds: 200,
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 10,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color:
//                                             slotSelection[index]
//                                                 ? Colors.blue[500]
//                                                 : Colors.white,
//                                         borderRadius: BorderRadius.circular(8),
//                                         border: Border.all(
//                                           color:
//                                               isPastSlot
//                                                   ? Colors.grey[200]!
//                                                   : slotSelection[index]
//                                                   ? Colors.blue[500]!
//                                                   : Colors.grey[300]!,
//                                         ),
//                                       ),
//                                       child: Center(
//                                         child: Text(
//                                           slotTime,
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color:
//                                                 isPastSlot
//                                                     ? Colors.grey[400]
//                                                     : slotSelection[index]
//                                                     ? Colors.white
//                                                     : Colors.grey[800],
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             }),
//                           ),
//                         );
//                       }),
//                     ),
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text("Cancel"),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         List<Map<String, dynamic>> updatedSlots = [];
//                         for (int i = 0; i < allSlots.length; i++) {
//                           if (slotSelection[i]) {
//                             bool isBooked = currentSlots.any(
//                               (s) => s['time'] == allSlots[i] && s['isBooked'],
//                             );
//                             updatedSlots.add({
//                               "time": allSlots[i],
//                               "isBooked": isBooked,
//                             });
//                           }
//                         }
//                         _updateDoctorField({"availableSlots": updatedSlots});
//                         Navigator.pop(context);
//                       },
//                       child: const Text("Save"),
//                     ),
//                   ],
//                 ),
//           ),
//     );
//   }

//   void _editAvailableDates(
//     List<String> currentDates,
//     List<String> availableDays,
//   ) {
//     List<DateTime> selectedDates =
//         currentDates.map((date) => DateTime.parse(date)).toList();
//     DateTime currentMonth = DateTime.now();
//     final DateTime today = DateTime.now();

//     showDialog(
//       context: context,
//       builder:
//           (context) => StatefulBuilder(
//             builder:
//                 (context, setState) => AlertDialog(
//                   title: const Text("Edit Available Dates"),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 0,
//                     vertical: 10,
//                   ),
//                   content: SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 16),
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: Colors.grey[300]!),
//                           ),
//                           child: Column(
//                             children: [
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   IconButton(
//                                     icon: const Icon(
//                                       Icons.arrow_back_ios,
//                                       size: 16,
//                                     ),
//                                     onPressed: () {
//                                       setState(() {
//                                         currentMonth = DateTime(
//                                           currentMonth.year,
//                                           currentMonth.month - 1,
//                                           1,
//                                         );
//                                       });
//                                     },
//                                   ),
//                                   Text(
//                                     DateFormat(
//                                       'MMMM yyyy',
//                                     ).format(currentMonth),
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   IconButton(
//                                     icon: const Icon(
//                                       Icons.arrow_forward_ios,
//                                       size: 16,
//                                     ),
//                                     onPressed: () {
//                                       setState(() {
//                                         currentMonth = DateTime(
//                                           currentMonth.year,
//                                           currentMonth.month + 1,
//                                           1,
//                                         );
//                                       });
//                                     },
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               _buildCalendar(
//                                 currentMonth,
//                                 selectedDates,
//                                 availableDays,
//                                 setState,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text("Cancel"),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         _updateDoctorField({
//                           "availableDates":
//                               selectedDates
//                                   .map((date) => date.toIso8601String())
//                                   .toList(),
//                         });
//                         Navigator.pop(context);
//                       },
//                       child: const Text("Save"),
//                     ),
//                   ],
//                 ),
//           ),
//     );
//   }

//   // Helper function to parse time slot to DateTime
//   DateTime _parseTimeSlot(String timeSlot, DateTime date) {
//     final timeFormat = DateFormat('h:mm a');
//     final parsedTime = timeFormat.parse(timeSlot);
//     return DateTime(
//       date.year,
//       date.month,
//       date.day,
//       parsedTime.hour,
//       parsedTime.minute,
//     );
//   }

//   // Check if there are any future slots available today
//   bool _hasFutureSlotsToday() {
//     final now = DateTime.now();
//     const allSlots = [
//       "9:00 AM",
//       "10:00 AM",
//       "11:00 AM",
//       "12:00 PM",
//       "1:00 PM",
//       "2:00 PM",
//       "3:00 PM",
//       "4:00 PM",
//       "5:00 PM",
//       "6:00 PM",
//       "7:00 PM",
//       "8:00 PM",
//     ];
//     return allSlots.any((slot) {
//       final slotTime = _parseTimeSlot(slot, now);
//       return slotTime.isAfter(now);
//     });
//   }

//   Widget _buildCalendar(
//     DateTime currentMonth,
//     List<DateTime> selectedDates,
//     List<String> availableDays,
//     StateSetter setState,
//   ) {
//     final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
//     final daysInMonth =
//         DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
//     final firstDayWeekday = firstDayOfMonth.weekday % 7; // Sunday as 0
//     final today = DateTime.now();

//     int totalSlots = firstDayWeekday + daysInMonth;
//     int weeks = (totalSlots / 7).ceil();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: const [
//             SizedBox(
//               width: 40,
//               child: Center(
//                 child: Text(
//                   'Sun',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 40,
//               child: Center(
//                 child: Text(
//                   'Mon',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 40,
//               child: Center(
//                 child: Text(
//                   'Tue',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 40,
//               child: Center(
//                 child: Text(
//                   'Wed',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 40,
//               child: Center(
//                 child: Text(
//                   'Thu',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 40,
//               child: Center(
//                 child: Text(
//                   'Fri',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 40,
//               child: Center(
//                 child: Text(
//                   'Sat',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         ...List.generate(weeks, (weekIndex) {
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 4.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: List.generate(7, (dayIndex) {
//                 int dayOffset = weekIndex * 7 + dayIndex - firstDayWeekday + 1;
//                 if (dayOffset <= 0 || dayOffset > daysInMonth) {
//                   return const SizedBox(width: 40, height: 40);
//                 }

//                 final currentDate = DateTime(
//                   currentMonth.year,
//                   currentMonth.month,
//                   dayOffset,
//                 );
//                 final dayName = DateFormat('EEEE').format(currentDate);
//                 final isSelectable = availableDays.contains(dayName);
//                 final isPastDate = currentDate.isBefore(
//                   DateTime(today.year, today.month, today.day),
//                 );
//                 final isToday =
//                     currentDate.day == today.day &&
//                     currentDate.month == today.month &&
//                     currentDate.year == today.year;
//                 final isSelectableToday = isToday && _hasFutureSlotsToday();
//                 final isSelected = selectedDates.any(
//                   (d) =>
//                       d.day == currentDate.day &&
//                       d.month == currentDate.month &&
//                       d.year == currentDate.year,
//                 );

//                 return GestureDetector(
//                   onTap:
//                       (isSelectable && !isPastDate) || isSelectableToday
//                           ? () {
//                             setState(() {
//                               if (isSelected) {
//                                 selectedDates.removeWhere(
//                                   (d) =>
//                                       d.day == currentDate.day &&
//                                       d.month == currentDate.month &&
//                                       d.year == currentDate.year,
//                                 );
//                               } else {
//                                 selectedDates.add(currentDate);
//                               }
//                             });
//                           }
//                           : null,
//                   child: SizedBox(
//                     width: 40,
//                     height: 40,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color:
//                             isSelected ? Colors.blue[500] : Colors.transparent,
//                         shape: BoxShape.circle,
//                         border: Border.all(
//                           color:
//                               (isSelectable && !isPastDate) || isSelectableToday
//                                   ? Colors.grey[400]!
//                                   : Colors.grey[200]!,
//                         ),
//                       ),
//                       child: Center(
//                         child: Text(
//                           '$dayOffset',
//                           style: TextStyle(
//                             color:
//                                 isSelected
//                                     ? Colors.white
//                                     : isPastDate && !isSelectableToday
//                                     ? Colors.grey[400]
//                                     : isSelectable || isSelectableToday
//                                     ? Colors.black
//                                     : Colors.grey[400],
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }),
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           "My Profile",
//           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: FutureBuilder<DocumentSnapshot>(
//         future: _doctorFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//               ),
//             );
//           }
//           if (!snapshot.hasData || snapshot.hasError) {
//             return Center(
//               child: Text(
//                 "Error loading profile",
//                 style: TextStyle(fontSize: 18, color: Colors.red[700]),
//               ),
//             );
//           }

//           var data = snapshot.data!.data() as Map<String, dynamic>;
//           String fullName = data['fullName'];
//           String specialty = data['specialty'];
//           String location = data['location'];
//           int age = data['age'];
//           String mobile = data['mobile'];
//           List<String> availableDays = List<String>.from(data['availableDays']);
//           List<dynamic> availableSlots = data['availableSlots'];
//           String? profileImageUrl = data['profileImageUrl'];
//           List<String> availableDates =
//               data['availableDates'] != null
//                   ? List<String>.from(data['availableDates'])
//                   : [];

//           return SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.blue[900]!, Colors.blue[700]!],
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                     ),
//                     borderRadius: const BorderRadius.vertical(
//                       bottom: Radius.circular(30),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 40),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       GestureDetector(
//                         onTap: pickImage,
//                         child: ScaleTransition(
//                           scale: _scaleAnimation,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.2),
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 4),
//                                 ),
//                               ],
//                             ),
//                             child: CircleAvatar(
//                               radius: 60,
//                               backgroundColor: Colors.white,
//                               backgroundImage:
//                                   profileImageUrl != null
//                                       ? NetworkImage(profileImageUrl)
//                                       : null,
//                               child:
//                                   profileImageUrl == null
//                                       ? Text(
//                                         fullName[0].toUpperCase(),
//                                         style: TextStyle(
//                                           fontSize: 48,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.blue[900],
//                                         ),
//                                       )
//                                       : null,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Text(
//                         "Dr. $fullName",
//                         style: const TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         specialty,
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.white.withOpacity(0.9),
//                           fontStyle: FontStyle.italic,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Personal Information",
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue[900],
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.edit, size: 20),
//                                 color: Colors.blue[700],
//                                 onPressed:
//                                     () => _editPersonalInfo(
//                                       location,
//                                       age,
//                                       mobile,
//                                     ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           _buildInfoRow(
//                             Icons.location_on,
//                             "Location",
//                             location,
//                           ),
//                           const SizedBox(height: 12),
//                           _buildInfoRow(Icons.person, "Age", age.toString()),
//                           const SizedBox(height: 12),
//                           _buildInfoRow(Icons.phone, "Mobile", mobile),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16.0,
//                     vertical: 8,
//                   ),
//                   child: Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Available Days",
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue[900],
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.edit, size: 20),
//                                 color: Colors.blue[700],
//                                 onPressed:
//                                     () => _editAvailableDays(availableDays),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Wrap(
//                             spacing: 10.0,
//                             runSpacing: 10.0,
//                             children:
//                                 availableDays.map((day) {
//                                   return Chip(
//                                     label: Text(
//                                       day,
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                     backgroundColor: Colors.blue[700],
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 6,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     elevation: 2,
//                                   );
//                                 }).toList(),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16.0,
//                     vertical: 8,
//                   ),
//                   child: Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Available Dates",
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue[900],
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.edit, size: 20),
//                                 color: Colors.blue[700],
//                                 onPressed:
//                                     () => _editAvailableDates(
//                                       availableDates,
//                                       availableDays,
//                                     ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Wrap(
//                             spacing: 10.0,
//                             runSpacing: 10.0,
//                             children:
//                                 availableDates.map((date) {
//                                   return Chip(
//                                     label: Text(
//                                       DateFormat(
//                                         'MMM d, yyyy',
//                                       ).format(DateTime.parse(date)),
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                     backgroundColor: Colors.blue[700],
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 6,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     elevation: 2,
//                                   );
//                                 }).toList(),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16.0,
//                     vertical: 8,
//                   ),
//                   child: Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Available Time Slots",
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue[900],
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.edit, size: 20),
//                                 color: Colors.blue[700],
//                                 onPressed: () async {
//                                   final snapshot = await _doctorFuture;
//                                   final data =
//                                       snapshot.data() as Map<String, dynamic>;
//                                   final currentSlots =
//                                       data['availableSlots'] as List<dynamic>;
//                                   final currentDates =
//                                       data['availableDates'] != null
//                                           ? List<String>.from(
//                                             data['availableDates'],
//                                           )
//                                           : [];
//                                   final selectedDates =
//                                       currentDates
//                                           .map((date) => DateTime.parse(date))
//                                           .toList();
//                                   _editAvailableSlots(
//                                     currentSlots,
//                                     selectedDates,
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Wrap(
//                             spacing: 10.0,
//                             runSpacing: 10.0,
//                             children:
//                                 availableSlots.map((slot) {
//                                   bool isBooked = slot['isBooked'];
//                                   String time = slot['time'];
//                                   return Chip(
//                                     label: Text(
//                                       "$time (${isBooked ? 'Booked' : 'Available'})",
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                         color:
//                                             isBooked
//                                                 ? Colors.grey[800]
//                                                 : Colors.green[800],
//                                       ),
//                                     ),
//                                     backgroundColor:
//                                         isBooked
//                                             ? Colors.grey[300]
//                                             : Colors.green[100],
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 6,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(20),
//                                       side: BorderSide(
//                                         color:
//                                             isBooked
//                                                 ? Colors.grey[400]!
//                                                 : Colors.green[400]!,
//                                         width: 1,
//                                       ),
//                                     ),
//                                     elevation: 2,
//                                   );
//                                 }).toList(),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String label, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, color: Colors.blue[700], size: 24),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[800],
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class DoctorProfilePage extends StatefulWidget {
  final String doctorId;

  const DoctorProfilePage({super.key, required this.doctorId});

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage>
    with SingleTickerProviderStateMixin {
  late Future<DocumentSnapshot> _doctorFuture;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _doctorFuture =
        FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .get();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      uploadImage();
    }
  }

  Future uploadImage() async {
    if (_image == null) return;

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child(
      'images/$fileName.jpg',
    );

    UploadTask uploadTask = storageRef.putFile(_image!);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    await _updateDoctorField({"profileImageUrl": downloadUrl});
    setState(() {
      _image = null;
    });
  }

  Future<void> _updateDoctorField(Map<String, dynamic> updatedData) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .update(updatedData);
      setState(() {
        _doctorFuture =
            FirebaseFirestore.instance
                .collection('doctors')
                .doc(widget.doctorId)
                .get();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profile updated successfully!"),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile: $e"),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _cancelAppointment(String date, String time) async {
    try {
      DocumentSnapshot snapshot =
          await	 await FirebaseFirestore.instance
              .collection('doctors')
              .doc(widget.doctorId)
              .get();
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> slotsByDate =
          data['availableSlotsByDate'] as Map<String, dynamic>;

      List<dynamic> slots = slotsByDate[date.split('T')[0]];
      int slotIndex = slots.indexWhere((slot) => slot['time'] == time);
      if (slotIndex != -1) {
        slots[slotIndex]['isBooked'] = false;
        slotsByDate[date.split('T')[0]] = slots;

        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .update({'availableSlotsByDate': slotsByDate});

        setState(() {
          _doctorFuture =
              FirebaseFirestore.instance
                  .collection('doctors')
                  .doc(widget.doctorId)
                  .get();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Appointment cancelled successfully!"),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error cancelling appointment: $e"),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _editPersonalInfo(
    String currentLocation,
    int currentAge,
    String currentMobile,
  ) {
    TextEditingController locationController = TextEditingController(
      text: currentLocation,
    );
    TextEditingController ageController = TextEditingController(
      text: currentAge.toString(),
    );
    TextEditingController mobileController = TextEditingController(
      text: currentMobile,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Personal Information"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: "Location"),
                  ),
                  TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: "Age"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: mobileController,
                    decoration: const InputDecoration(labelText: "Mobile"),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _updateDoctorField({
                    "location": locationController.text.trim(),
                    "age": int.parse(ageController.text.trim()),
                    "mobile": mobileController.text.trim(),
                  });
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  void _editAvailableDays(List<String> currentDays) {
    List<String> allDays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    List<bool> daySelection =
        allDays.map((day) => currentDays.contains(day)).toList();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text("Edit Available Days"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(allDays.length, (index) {
                        return CheckboxListTile(
                          title: Text(allDays[index]),
                          value: daySelection[index],
                          onChanged: (value) {
                            setState(() {
                              daySelection[index] = value!;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        List<String> selectedDays = [];
                        for (int i = 0; i < allDays.length; i++) {
                          if (daySelection[i]) {
                            selectedDays.add(allDays[i]);
                          }
                        }
                        _updateDoctorField({"availableDays": selectedDays});
                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
          ),
    );
  }

  void _editAvailableSlots(
    Map<String, dynamic> currentSlotsByDate,
    List<DateTime> selectedDates,
  ) {
    List<String> allSlots = [
      "9:00 AM",
      "10:00 AM",
      "11:00 AM",
      "12:00 PM",
      "1:00 PM",
      "2:00 PM",
      "3:00 PM",
      "4:00 PM",
      "5:00 PM",
      "6:00 PM",
      "7:00 PM",
      "8:00 PM",
    ];
    DateTime? selectedDate;
    List<bool> slotSelection = List.generate(allSlots.length, (_) => false);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text("Edit Available Time Slots"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<DateTime>(
                          hint: const Text("Select Date"),
                          value: selectedDate,
                          items:
                              selectedDates.map((date) {
                                return DropdownMenuItem(
                                  value: date,
                                  child: Text(
                                    DateFormat('MMM d, yyyy').format(date),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDate = value;
                              if (value != null) {
                                String dateKey =
                                    value.toIso8601String().split('T')[0];
                                List<dynamic> slots =
                                    currentSlotsByDate[dateKey] ?? [];
                                slotSelection =
                                    allSlots.map((slot) {
                                      return slots.any(
                                        (s) => s['time'] == slot,
                                      );
                                    }).toList();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        if (selectedDate != null)
                          Column(
                            children: List.generate(3, (rowIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: List.generate(4, (colIndex) {
                                    int index = rowIndex * 4 + colIndex;
                                    final slotTime = allSlots[index];
                                    final now = DateTime.now();
                                    final today = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                    );

                                    bool isTodaySelected =
                                        selectedDate!.year == today.year &&
                                        selectedDate!.month == today.month &&
                                        selectedDate!.day == today.day;
                                    bool isPastSlot = false;
                                    if (isTodaySelected) {
                                      final slotDateTime = _parseTimeSlot(
                                        slotTime,
                                        today,
                                      );
                                      isPastSlot = slotDateTime.isBefore(now);
                                    }

                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: colIndex < 3 ? 8.0 : 0,
                                        ),
                                        child: GestureDetector(
                                          onTap:
                                              isPastSlot
                                                  ? null
                                                  : () {
                                                    setState(() {
                                                      slotSelection[index] =
                                                          !slotSelection[index];
                                                    });
                                                  },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  slotSelection[index]
                                                      ? Colors.blue[500]
                                                      : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color:
                                                    isPastSlot
                                                        ? Colors.grey[200]!
                                                        : slotSelection[index]
                                                        ? Colors.blue[500]!
                                                        : Colors.grey[300]!,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                slotTime,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      isPastSlot
                                                          ? Colors.grey[400]
                                                          : slotSelection[index]
                                                          ? Colors.white
                                                          : Colors.grey[800],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            }),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed:
                          selectedDate == null
                              ? null
                              : () {
                                String dateKey =
                                    selectedDate!.toIso8601String().split(
                                      'T',
                                    )[0];
                                List<Map<String, dynamic>> updatedSlots = [];
                                for (int i = 0; i < allSlots.length; i++) {
                                  if (slotSelection[i]) {
                                    bool isBooked = false;
                                    if (currentSlotsByDate[dateKey] != null) {
                                      var existingSlot =
                                          currentSlotsByDate[dateKey]
                                              .firstWhere(
                                                (s) => s['time'] == allSlots[i],
                                                orElse: () => null,
                                              );
                                      if (existingSlot != null) {
                                        isBooked =
                                            existingSlot['isBooked'] ?? false;
                                      }
                                    }
                                    updatedSlots.add({
                                      "time": allSlots[i],
                                      "isBooked": isBooked,
                                    });
                                  }
                                }
                                currentSlotsByDate[dateKey] = updatedSlots;
                                _updateDoctorField({
                                  "availableSlotsByDate": currentSlotsByDate,
                                });
                                Navigator.pop(context);
                              },
                      child: const Text("Save"),
                    ),
                  ],
                ),
          ),
    );
  }

  void _editAvailableDates(
    List<String> currentDates,
    List<String> availableDays,
  ) {
    List<DateTime> selectedDates =
        currentDates.map((date) => DateTime.parse(date)).toList();
    DateTime currentMonth = DateTime.now();
    final DateTime today = DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text("Edit Available Dates"),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 10,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        currentMonth = DateTime(
                                          currentMonth.year,
                                          currentMonth.month - 1,
                                          1,
                                        );
                                      });
                                    },
                                  ),
                                  Text(
                                    DateFormat(
                                      'MMMM yyyy',
                                    ).format(currentMonth),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        currentMonth = DateTime(
                                          currentMonth.year,
                                          currentMonth.month + 1,
                                          1,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildCalendar(
                                currentMonth,
                                selectedDates,
                                availableDays,
                                setState,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        _updateDoctorField({
                          "availableDates":
                              selectedDates
                                  .map((date) => date.toIso8601String())
                                  .toList(),
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
          ),
    );
  }

  // Helper function to parse time slot to DateTime
  DateTime _parseTimeSlot(String timeSlot, DateTime date) {
    final timeFormat = DateFormat('h:mm a');
    final parsedTime = timeFormat.parse(timeSlot);
    return DateTime(
      date.year,
      date.month,
      date.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  // Check if there are any future slots available today
  bool _hasFutureSlotsToday() {
    final now = DateTime.now();
    const allSlots = [
      "9:00 AM",
      "10:00 AM",
      "11:00 AM",
      "12:00 PM",
      "1:00 PM",
      "2:00 PM",
      "3:00 PM",
      "4:00 PM",
      "5:00 PM",
      "6:00 PM",
      "7:00 PM",
      "8:00 PM",
    ];
    return allSlots.any((slot) {
      final slotTime = _parseTimeSlot(slot, now);
      return slotTime.isAfter(now);
    });
  }

  Widget _buildCalendar(
    DateTime currentMonth,
    List<DateTime> selectedDates,
    List<String> availableDays,
    StateSetter setState,
  ) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Sunday as 0
    final today = DateTime.now();

    int totalSlots = firstDayWeekday + daysInMonth;
    int weeks = (totalSlots / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  'Sun',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  'Mon',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  'Tue',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  'Wed',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  'Thu',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  'Fri',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  'Sat',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(weeks, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (dayIndex) {
                int dayOffset = weekIndex * 7 + dayIndex - firstDayWeekday + 1;
                if (dayOffset <= 0 || dayOffset > daysInMonth) {
                  return const SizedBox(width: 40, height: 40);
                }

                final currentDate = DateTime(
                  currentMonth.year,
                  currentMonth.month,
                  dayOffset,
                );
                final dayName = DateFormat('EEEE').format(currentDate);
                final isSelectable = availableDays.contains(dayName);
                final isPastDate = currentDate.isBefore(
                  DateTime(today.year, today.month, today.day),
                );
                final isToday =
                    currentDate.day == today.day &&
                    currentDate.month == today.month &&
                    currentDate.year == today.year;
                final isSelectableToday = isToday && _hasFutureSlotsToday();
                final isSelected = selectedDates.any(
                  (d) =>
                      d.day == currentDate.day &&
                      d.month == currentDate.month &&
                      d.year == currentDate.year,
                );

                return GestureDetector(
                  onTap:
                      (isSelectable && !isPastDate) || isSelectableToday
                          ? () {
                            setState(() {
                              if (isSelected) {
                                selectedDates.removeWhere(
                                  (d) =>
                                      d.day == currentDate.day &&
                                      d.month == currentDate.month &&
                                      d.year == currentDate.year,
                                );
                              } else {
                                selectedDates.add(currentDate);
                              }
                            });
                          }
                          : null,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blue[500] : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              (isSelectable && !isPastDate) || isSelectableToday
                                  ? Colors.grey[400]!
                                  : Colors.grey[200]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$dayOffset',
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : isPastDate && !isSelectableToday
                                    ? Colors.grey[400]
                                    : isSelectable || isSelectableToday
                                    ? Colors.black
                                    : Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _doctorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading profile",
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String fullName = data['fullName'] ?? 'Unknown Doctor';
          String specialty = data['specialty'] ?? 'No Specialty';
          String location = data['location'] ?? 'No Location';
          int age = data['age'] ?? 0;
          String mobile = data['mobile'] ?? 'No Mobile';
          List<String> availableDays = data['availableDays'] != null
              ? List<String>.from(data['availableDays'])
              : [];
          Map<String, dynamic> availableSlotsByDate =
              data['availableSlotsByDate'] ?? {};
          String? profileImageUrl = data['profileImageUrl'];
          List<String> availableDates =
              data['availableDates'] != null
                  ? List<String>.from(data['availableDates'])
                  : [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[900]!, Colors.blue[700]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: pickImage,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  profileImageUrl != null
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                              child:
                                  profileImageUrl == null
                                      ? Text(
                                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Dr. $fullName",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Personal Information",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue[700],
                                onPressed:
                                    () => _editPersonalInfo(
                                      location,
                                      age,
                                      mobile,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.location_on,
                            "Location",
                            location,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.person, "Age", age.toString()),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.phone, "Mobile", mobile),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Available Days",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue[700],
                                onPressed:
                                    () => _editAvailableDays(availableDays),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children:
                                availableDays.map((day) {
                                  return Chip(
                                    label: Text(
                                      day,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.blue[700],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 2,
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Available Dates",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue[700],
                                onPressed:
                                    () => _editAvailableDates(
                                      availableDates,
                                      availableDays,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children:
                                availableDates.map((date) {
                                  return Chip(
                                    label: Text(
                                      DateFormat(
                                        'MMM d, yyyy',
                                      ).format(DateTime.parse(date)),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.blue[700],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 2,
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Available Time Slots",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue[700],
                                onPressed:
                                    () => _editAvailableSlots(
                                      availableSlotsByDate,
                                      availableDates
                                          .map((d) => DateTime.parse(d))
                                          .toList(),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...availableDates.map((date) {
                            String dateKey = date.split('T')[0];
                            List<dynamic> slots =
                                availableSlotsByDate[dateKey] ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(DateTime.parse(date)),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10.0,
                                  runSpacing: 10.0,
                                  children:
                                      slots.map((slot) {
                                        bool isBooked = slot['isBooked'];
                                        String time = slot['time'];
                                        return GestureDetector(
                                          onTap:
                                              isBooked
                                                  ? () {
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            title: const Text(
                                                              "Cancel Appointment",
                                                            ),
                                                            content: Text(
                                                              "Cancel appointment for $time on ${DateFormat('MMM d, yyyy').format(DateTime.parse(date))}?",
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      "No",
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  _cancelAppointment(
                                                                    date,
                                                                    time,
                                                                  );
                                                                  Navigator.pop(
                                                                    context,
                                                                  );
                                                                },
                                                                child:
                                                                    const Text(
                                                                      "Yes",
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                  }
                                                  : null,
                                          child: Chip(
                                            label: Text(
                                              "$time (${isBooked ? 'Booked' : 'Available'})",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    isBooked
                                                        ? Colors.grey[800]
                                                        : Colors.green[800],
                                              ),
                                            ),
                                            backgroundColor:
                                                isBooked
                                                    ? Colors.grey[300]
                                                    : Colors.green[100],
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              side: BorderSide(
                                                color:
                                                    isBooked
                                                        ? Colors.grey[400]!
                                                        : Colors.green[400]!,
                                                width: 1,
                                              ),
                                            ),
                                            elevation: 2,
                                          ),
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[700], size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}