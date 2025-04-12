// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_pharmacy/models/user_model.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

// class AppointmentsPage extends StatefulWidget {
//   final String linkedDocId;

//   const AppointmentsPage({super.key, required this.linkedDocId});

//   @override
//   _AppointmentsPageState createState() => _AppointmentsPageState();
// }

// class _AppointmentsPageState extends State<AppointmentsPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool _isLoading = false;

//   Future<void> _cancelAppointment(
//     String doctorId,
//     String slotTime,
//     DateTime bookedDate,
//   ) async {
//     setState(() => _isLoading = true);
//     try {
//       DocumentReference doctorRef = _firestore
//           .collection('doctors')
//           .doc(doctorId);
//       DocumentSnapshot doctorSnapshot = await doctorRef.get();
//       if (doctorSnapshot.exists) {
//         List<dynamic> availableSlots =
//             (doctorSnapshot.data() as Map<String, dynamic>)['availableSlots'] ??
//             [];
//         int slotIndex = availableSlots.indexWhere(
//           (slot) =>
//               slot['time'] == slotTime &&
//               slot['bookedDate'] == bookedDate.toIso8601String(),
//         );

//         if (slotIndex != -1) {
//           availableSlots[slotIndex]['isBooked'] = false;
//           availableSlots[slotIndex].remove(
//             'bookedDate',
//           ); // Remove bookedDate field
//           await doctorRef.update({'availableSlots': availableSlots});
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Appointment cancelled successfully!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//           setState(() {}); // Refresh the UI
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error cancelling appointment: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userModel = Provider.of<UserModel>(context);
//     final isCaretaker = userModel.role == 'Caretaker';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Your Appointments',
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         backgroundColor: Colors.blueAccent,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body:
//           _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : FutureBuilder<QuerySnapshot>(
//                 future: _firestore.collection('doctors').get(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (!snapshot.hasData || snapshot.hasError) {
//                     return const Center(
//                       child: Text(
//                         'Error loading appointments',
//                         style: TextStyle(color: Colors.red, fontSize: 16),
//                       ),
//                     );
//                   }

//                   List<Map<String, dynamic>> appointments = [];
//                   for (var doc in snapshot.data!.docs) {
//                     var data = doc.data() as Map<String, dynamic>;
//                     String doctorId = doc.id;
//                     String doctorName = data['fullName'] ?? 'Unknown Doctor';
//                     List<dynamic> slots = data['availableSlots'] ?? [];

//                     for (var slot in slots) {
//                       if (slot['isBooked'] == true &&
//                           slot['bookedDate'] != null) {
//                         DateTime bookedDate = DateTime.parse(
//                           slot['bookedDate'],
//                         );
//                         appointments.add({
//                           'doctorId': doctorId,
//                           'doctorName': doctorName,
//                           'time': slot['time'],
//                           'date': bookedDate,
//                         });
//                       }
//                     }
//                   }

//                   if (appointments.isEmpty) {
//                     return const Center(
//                       child: Text(
//                         'No appointments booked yet',
//                         style: TextStyle(color: Colors.grey, fontSize: 16),
//                       ),
//                     );
//                   }

//                   return ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: appointments.length,
//                     itemBuilder: (context, index) {
//                       var appointment = appointments[index];
//                       String formattedDate = DateFormat(
//                         'MMM d, yyyy',
//                       ).format(appointment['date']);

//                       return Card(
//                         elevation: 2,
//                         margin: const EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Dr. ${appointment['doctorName']}',
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 18,
//                                         color: Colors.black87,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     Text(
//                                       "Date: $formattedDate",
//                                       style: TextStyle(
//                                         color: Colors.grey[700],
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                     Text(
//                                       "Time: ${appointment['time']}",
//                                       style: TextStyle(
//                                         color: Colors.grey[700],
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               if (isCaretaker)
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.cancel,
//                                     color: Colors.red,
//                                   ),
//                                   onPressed:
//                                       () => _cancelAppointment(
//                                         appointment['doctorId'],
//                                         appointment['time'],
//                                         appointment['date'],
//                                       ),
//                                   tooltip: 'Cancel Appointment',
//                                 ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_pharmacy/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AppointmentsPage extends StatefulWidget {
  final String linkedDocId;

  const AppointmentsPage({super.key, required this.linkedDocId});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _cancelAppointment(
    String doctorId,
    String slotTime,
    DateTime bookedDate,
  ) async {
    setState(() => _isLoading = true);
    try {
      DocumentReference doctorRef = _firestore
          .collection('doctors')
          .doc(doctorId);
      DocumentSnapshot doctorSnapshot = await doctorRef.get();
      if (doctorSnapshot.exists) {
        Map<String, dynamic> data =
            doctorSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> availableSlotsByDate =
            data['availableSlotsByDate'] ?? {};

        String dateKey = bookedDate.toIso8601String().split('T')[0];
        List<dynamic> slots = availableSlotsByDate[dateKey] ?? [];

        int slotIndex = slots.indexWhere((slot) => slot['time'] == slotTime);
        if (slotIndex != -1 && slots[slotIndex]['isBooked'] == true) {
          slots[slotIndex]['isBooked'] = false;
          availableSlotsByDate[dateKey] = slots;

          await doctorRef.update({
            'availableSlotsByDate': availableSlotsByDate,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Refresh the UI
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final isCaretaker = userModel.role == 'Caretaker';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Appointments',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<QuerySnapshot>(
                future: _firestore.collection('doctors').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading appointments',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }

                  List<Map<String, dynamic>> appointments = [];
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String doctorId = doc.id;
                    String doctorName = data['fullName'] ?? 'Unknown Doctor';
                    Map<String, dynamic> availableSlotsByDate =
                        data['availableSlotsByDate'] ?? {};

                    availableSlotsByDate.forEach((dateKey, slots) {
                      DateTime bookedDate;
                      try {
                        bookedDate = DateTime.parse(dateKey);
                      } catch (e) {
                        return; // Skip invalid date keys
                      }
                      for (var slot in slots) {
                        if (slot['isBooked'] == true) {
                          appointments.add({
                            'doctorId': doctorId,
                            'doctorName': doctorName,
                            'time': slot['time'],
                            'date': bookedDate,
                          });
                        }
                      }
                    });
                  }

                  if (appointments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No appointments booked yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      var appointment = appointments[index];
                      String formattedDate = DateFormat(
                        'MMM d, yyyy',
                      ).format(appointment['date']);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ${appointment['doctorName']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Date: $formattedDate",
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "Time: ${appointment['time']}",
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCaretaker)
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _cancelAppointment(
                                        appointment['doctorId'],
                                        appointment['time'],
                                        appointment['date'],
                                      ),
                                  tooltip: 'Cancel Appointment',
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
