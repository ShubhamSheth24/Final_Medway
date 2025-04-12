// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class DoctorAppointmentScreen extends StatefulWidget {
//   final String doctorId;

//   const DoctorAppointmentScreen({super.key, required this.doctorId});

//   @override
//   _DoctorAppointmentScreenState createState() =>
//       _DoctorAppointmentScreenState();
// }

// class _DoctorAppointmentScreenState extends State<DoctorAppointmentScreen> {
//   late Future<DocumentSnapshot> _doctorFuture;
//   DateTime _selectedDate = DateTime.now();
//   String? _selectedTimeSlot;
//   List<String> _availableTimeSlots = [];
//   List<DateTime> _availableDates = [];

//   @override
//   void initState() {
//     super.initState();
//     _doctorFuture =
//         FirebaseFirestore.instance
//             .collection('doctors')
//             .doc(widget.doctorId)
//             .get();
//   }

//   void _selectDate(DateTime date) {
//     setState(() {
//       _selectedDate = date;
//       _selectedTimeSlot = null; // Reset selected time slot when date changes
//     });
//   }

//   void _selectTimeSlot(String timeSlot) {
//     setState(() {
//       _selectedTimeSlot = timeSlot;
//     });
//   }

//   Future<void> _bookAppointment() async {
//     if (_selectedTimeSlot == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a time slot'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     try {
//       DocumentReference doctorRef = FirebaseFirestore.instance
//           .collection('doctors')
//           .doc(widget.doctorId);
//       DocumentSnapshot doctorSnapshot = await doctorRef.get();
//       List<dynamic> availableSlots =
//           (doctorSnapshot.data() as Map<String, dynamic>)['availableSlots'] ??
//           [];

//       int slotIndex = availableSlots.indexWhere(
//         (slot) => slot['time'] == _selectedTimeSlot,
//       );
//       if (slotIndex != -1) {
//         // Check if the selected date already has a booking
//         bool isDateBooked = availableSlots.any(
//           (slot) =>
//               slot['isBooked'] == true &&
//               slot['bookedDate'] != null &&
//               DateTime.parse(slot['bookedDate']).day == _selectedDate.day &&
//               DateTime.parse(slot['bookedDate']).month == _selectedDate.month &&
//               DateTime.parse(slot['bookedDate']).year == _selectedDate.year,
//         );

//         if (isDateBooked) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                 'This date is already booked. Please select another date.',
//               ),
//               backgroundColor: Colors.red,
//             ),
//           );
//           return;
//         }

//         availableSlots[slotIndex]['isBooked'] = true;
//         availableSlots[slotIndex]['bookedDate'] =
//             _selectedDate.toIso8601String();

//         await doctorRef.update({'availableSlots': availableSlots});

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Appointment booked successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );

//         setState(() {
//           _doctorFuture =
//               FirebaseFirestore.instance
//                   .collection('doctors')
//                   .doc(widget.doctorId)
//                   .get();
//           _selectedTimeSlot = null;
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error booking appointment: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'Book Appointment',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: FutureBuilder<DocumentSnapshot>(
//         future: _doctorFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(color: Colors.blue),
//             );
//           }
//           if (!snapshot.hasData || snapshot.hasError) {
//             return const Center(
//               child: Text(
//                 'Error loading doctor details',
//                 style: TextStyle(color: Colors.red, fontSize: 16),
//               ),
//             );
//           }

//           var data = snapshot.data!.data() as Map<String, dynamic>;
//           String fullName = data['fullName'] ?? 'Unknown Doctor';
//           String specialty = data['specialty'] ?? 'No Specialty';
//           String location = data['location'] ?? 'Unknown Location';
//           List<dynamic> availableSlots = data['availableSlots'] ?? [];
//           List<String> availableDates =
//               data['availableDates'] != null
//                   ? List<String>.from(data['availableDates'])
//                   : [];
//           _availableDates =
//               availableDates.map((date) => DateTime.parse(date)).toList();
//           _availableTimeSlots =
//               availableSlots.map((slot) => slot['time'] as String).toList();

//           // Ensure _selectedDate is one of the available dates
//           if (_availableDates.isNotEmpty &&
//               !_availableDates.any(
//                 (d) =>
//                     d.day == _selectedDate.day &&
//                     d.month == _selectedDate.month &&
//                     d.year == _selectedDate.year,
//               )) {
//             _selectedDate = _availableDates.first;
//           }

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 90,
//                         height: 90,
//                         decoration: BoxDecoration(
//                           color: Colors.blue[50],
//                           borderRadius: BorderRadius.circular(15),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.2),
//                               blurRadius: 8,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: Text(
//                             fullName[0].toUpperCase(),
//                             style: TextStyle(
//                               fontSize: 40,
//                               color: Colors.blue[800],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 15),
//                       Text(
//                         'Dr. $fullName',
//                         style: const TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       Text(
//                         specialty,
//                         style: TextStyle(color: Colors.grey[600], fontSize: 16),
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(
//                             Icons.location_on,
//                             color: Colors.grey,
//                             size: 16,
//                           ),
//                           const SizedBox(width: 5),
//                           Text(
//                             location,
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 const Text(
//                   'Select Date',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 _buildCalendar(),
//                 const SizedBox(height: 30),
//                 const Text(
//                   'Select Time Slot',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 _buildTimeSlots(availableSlots),
//                 const SizedBox(height: 40),
//                 Center(
//                   child: ElevatedButton(
//                     onPressed: _bookAppointment,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[700],
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 50,
//                         vertical: 15,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 5,
//                     ),
//                     child: const Text(
//                       'Book Appointment',
//                       style: TextStyle(
//                         fontSize: 18,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCalendar() {
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               IconButton(
//                 icon: const Icon(
//                   Icons.arrow_back_ios,
//                   size: 18,
//                   color: Colors.blue,
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _selectedDate = DateTime(
//                       _selectedDate.year,
//                       _selectedDate.month - 1,
//                       _selectedDate.day,
//                     );
//                   });
//                 },
//               ),
//               Text(
//                 DateFormat('MMMM yyyy').format(_selectedDate),
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(
//                   Icons.arrow_forward_ios,
//                   size: 18,
//                   color: Colors.blue,
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _selectedDate = DateTime(
//                       _selectedDate.year,
//                       _selectedDate.month + 1,
//                       _selectedDate.day,
//                     );
//                   });
//                 },
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: const [
//               Text(
//                 'Sun',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Text(
//                 'Mon',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Text(
//                 'Tue',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Text(
//                 'Wed',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Text(
//                 'Thu',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Text(
//                 'Fri',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Text(
//                 'Sat',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 15),
//           _buildCalendarDays(),
//         ],
//       ),
//     );
//   }

//   Widget _buildCalendarDays() {
//     final firstDayOfMonth = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       1,
//     );
//     final daysInMonth =
//         DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
//     final firstDayWeekday = firstDayOfMonth.weekday % 7;

//     List<Widget> dayWidgets = [];
//     for (int i = 0; i < firstDayWeekday; i++) {
//       dayWidgets.add(const SizedBox(width: 40, height: 40));
//     }

//     for (int day = 1; day <= daysInMonth; day++) {
//       final currentDate = DateTime(
//         _selectedDate.year,
//         _selectedDate.month,
//         day,
//       );
//       final isAvailable = _availableDates.any(
//         (d) =>
//             d.day == currentDate.day &&
//             d.month == currentDate.month &&
//             d.year == currentDate.year,
//       );
//       final isSelected =
//           currentDate.day == _selectedDate.day &&
//           currentDate.month == _selectedDate.month &&
//           currentDate.year == _selectedDate.year;

//       dayWidgets.add(
//         GestureDetector(
//           onTap: isAvailable ? () => _selectDate(currentDate) : null,
//           child: Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: isSelected ? Colors.blue[700] : Colors.transparent,
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color:
//                     isAvailable
//                         ? (isSelected ? Colors.blue[700]! : Colors.grey[200]!)
//                         : Colors.grey[200]!,
//                 width: 1,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 '$day',
//                 style: TextStyle(
//                   color:
//                       isAvailable
//                           ? (isSelected ? Colors.white : Colors.black87)
//                           : Colors.grey[400],
//                   fontWeight: FontWeight.w500,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     return Wrap(spacing: 8, runSpacing: 8, children: dayWidgets);
//   }

//   Widget _buildTimeSlots(List<dynamic> availableSlots) {
//     return Wrap(
//       spacing: 12,
//       runSpacing: 12,
//       children:
//           _availableTimeSlots.map((time) {
//             final slot = availableSlots.firstWhere(
//               (slot) => slot['time'] == time,
//             );
//             final isBooked = slot['isBooked'] ?? false;
//             final bookedDate =
//                 slot['bookedDate'] != null
//                     ? DateTime.parse(slot['bookedDate'])
//                     : null;
//             final isDateBooked =
//                 isBooked &&
//                 bookedDate != null &&
//                 bookedDate.day == _selectedDate.day &&
//                 bookedDate.month == _selectedDate.month &&
//                 bookedDate.year == _selectedDate.year;
//             final isSelected = _selectedTimeSlot == time;

//             return GestureDetector(
//               onTap: isDateBooked ? null : () => _selectTimeSlot(time),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   color:
//                       isDateBooked
//                           ? Colors.grey[400]
//                           : (isSelected ? Colors.blue[100] : Colors.grey[100]),
//                   border: Border.all(
//                     color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
//                     width: 1.5,
//                   ),
//                   borderRadius: BorderRadius.circular(10),
//                   boxShadow: [
//                     if (isSelected)
//                       BoxShadow(
//                         color: Colors.blue.withOpacity(0.2),
//                         blurRadius: 5,
//                         offset: const Offset(0, 2),
//                       ),
//                   ],
//                 ),
//                 child: Text(
//                   time,
//                   style: TextStyle(
//                     color: isDateBooked ? Colors.white : Colors.black87,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorAppointmentScreen extends StatefulWidget {
  final String doctorId;

  const DoctorAppointmentScreen({super.key, required this.doctorId});

  @override
  _DoctorAppointmentScreenState createState() =>
      _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState extends State<DoctorAppointmentScreen> {
  late Future<DocumentSnapshot> _doctorFuture;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  List<String> _availableTimeSlots = [];
  List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _doctorFuture =
        FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .get();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null; // Reset selected time slot when date changes
    });
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
  }

  Future<void> _bookAppointment() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      DocumentReference doctorRef = FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId);
      DocumentSnapshot doctorSnapshot = await doctorRef.get();
      Map<String, dynamic> data = doctorSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> availableSlotsByDate =
          data['availableSlotsByDate'] ?? {};

      String dateKey = _selectedDate.toIso8601String().split('T')[0];
      List<dynamic> slots = availableSlotsByDate[dateKey] ?? [];

      int slotIndex = slots.indexWhere(
        (slot) => slot['time'] == _selectedTimeSlot,
      );
      if (slotIndex != -1) {
        if (slots[slotIndex]['isBooked'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This time slot is already booked.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        slots[slotIndex]['isBooked'] = true;
        availableSlotsByDate[dateKey] = slots;

        await doctorRef.update({'availableSlotsByDate': availableSlotsByDate});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _doctorFuture =
              FirebaseFirestore.instance
                  .collection('doctors')
                  .doc(widget.doctorId)
                  .get();
          _selectedTimeSlot = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected time slot is not available.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _doctorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading doctor details',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String fullName = data['fullName'] ?? 'Unknown Doctor';
          String specialty = data['specialty'] ?? 'No Specialty';
          String location = data['location'] ?? 'Unknown Location';
          Map<String, dynamic> availableSlotsByDate =
              data['availableSlotsByDate'] ?? {};
          List<String> availableDates =
              data['availableDates'] != null
                  ? List<String>.from(data['availableDates'])
                  : [];
          _availableDates =
              availableDates.map((date) => DateTime.parse(date)).toList();

          String dateKey = _selectedDate.toIso8601String().split('T')[0];
          _availableTimeSlots =
              (availableSlotsByDate[dateKey] ?? [])
                  .map<String>((slot) => slot['time'] as String)
                  .toList();

          // Ensure _selectedDate is one of the available dates
          if (_availableDates.isNotEmpty &&
              !_availableDates.any(
                (d) =>
                    d.day == _selectedDate.day &&
                    d.month == _selectedDate.month &&
                    d.year == _selectedDate.year,
              )) {
            _selectedDate = _availableDates.first;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            fullName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Dr. $fullName',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        specialty,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                _buildCalendar(),
                const SizedBox(height: 30),
                const Text(
                  'Select Time Slot',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                _buildTimeSlots(availableSlotsByDate[dateKey] ?? []),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: _bookAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Book Appointment',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Colors.blue,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                      _selectedDate.day,
                    );
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.blue,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                      _selectedDate.day,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Sun',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Mon',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Tue',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Wed',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Thu',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Fri',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Sat',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildCalendarDays(),
        ],
      ),
    );
  }

  Widget _buildCalendarDays() {
    final firstDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstDayWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];
    for (int i = 0; i < firstDayWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 40, height: 40));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        day,
      );
      final isAvailable = _availableDates.any(
        (d) =>
            d.day == currentDate.day &&
            d.month == currentDate.month &&
            d.year == currentDate.year,
      );
      final isSelected =
          currentDate.day == _selectedDate.day &&
          currentDate.month == _selectedDate.month &&
          currentDate.year == _selectedDate.year;

      dayWidgets.add(
        GestureDetector(
          onTap: isAvailable ? () => _selectDate(currentDate) : null,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[700] : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isAvailable
                        ? (isSelected ? Colors.blue[700]! : Colors.grey[200]!)
                        : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color:
                      isAvailable
                          ? (isSelected ? Colors.white : Colors.black87)
                          : Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: dayWidgets);
  }

  Widget _buildTimeSlots(List<dynamic> availableSlots) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          _availableTimeSlots.map((time) {
            final slot = availableSlots.firstWhere(
              (slot) => slot['time'] == time,
              orElse: () => {'isBooked': false},
            );
            final isBooked = slot['isBooked'] ?? false;
            final isSelected = _selectedTimeSlot == time;

            return GestureDetector(
              onTap: isBooked ? null : () => _selectTimeSlot(time),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isBooked
                          ? Colors.grey[400]
                          : (isSelected ? Colors.blue[100] : Colors.grey[100]),
                  border: Border.all(
                    color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isBooked ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
