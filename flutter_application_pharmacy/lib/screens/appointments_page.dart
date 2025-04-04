import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_pharmacy/models/user_model';
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
        List<dynamic> availableSlots =
            (doctorSnapshot.data() as Map<String, dynamic>)['availableSlots'] ??
            [];
        int slotIndex = availableSlots.indexWhere(
          (slot) =>
              slot['time'] == slotTime &&
              slot['bookedDate'] == bookedDate.toIso8601String(),
        );

        if (slotIndex != -1) {
          availableSlots[slotIndex]['isBooked'] = false;
          availableSlots[slotIndex].remove(
            'bookedDate',
          ); // Remove bookedDate field
          await doctorRef.update({'availableSlots': availableSlots});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully!'),
            ),
          );
          setState(() {}); // Refresh the UI
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling appointment: $e')),
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
        title: const Text('Your Appointments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                      child: Text('Error loading appointments'),
                    );
                  }

                  List<Map<String, dynamic>> appointments = [];
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String doctorId = doc.id;
                    String doctorName = data['fullName'] ?? 'Unknown Doctor';
                    List<dynamic> slots = data['availableSlots'] ?? [];

                    for (var slot in slots) {
                      if (slot['isBooked'] == true &&
                          slot['bookedDate'] != null) {
                        DateTime bookedDate = DateTime.parse(
                          slot['bookedDate'],
                        );
                        appointments.add({
                          'doctorId': doctorId,
                          'doctorName': doctorName,
                          'time': slot['time'],
                          'date': bookedDate,
                        });
                      }
                    }
                  }

                  if (appointments.isEmpty) {
                    return const Center(
                      child: Text('No appointments booked yet'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      var appointment = appointments[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            'Dr. ${appointment['doctorName']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Date: ${DateFormat('MMM d, yyyy').format(appointment['date'])}\nTime: ${appointment['time']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing:
                              isCaretaker
                                  ? IconButton(
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
                                  )
                                  : null, // No trailing icon for patients
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
