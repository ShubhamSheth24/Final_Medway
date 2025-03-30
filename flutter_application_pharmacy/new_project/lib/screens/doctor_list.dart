import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Doctors'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final doctors = snapshot.data!.docs;
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text(doctor['name']),
                subtitle: Text(doctor['specialty']),
                trailing: Text(doctor['location']),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doctor)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DoctorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(doctor['name']),
        backgroundColor: Colors.blue.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialty: ${doctor['specialty']}', style: const TextStyle(fontSize: 18)),
            Text('Location: ${doctor['location']}', style: const TextStyle(fontSize: 18)),
            Text('Time Slots: ${(doctor['timeSlots'] as List).join(', ')}',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}