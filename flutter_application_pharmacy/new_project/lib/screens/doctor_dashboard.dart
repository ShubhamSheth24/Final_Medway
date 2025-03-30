import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorDashboard extends StatefulWidget {
  final String userName;

  const DoctorDashboard({super.key, required this.userName});

  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String specialty = '';
  String location = '';
  String timeSlots = '';

  Future<void> _addDoctorProfile() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String docId = user.email!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        await FirebaseFirestore.instance.collection('doctors').doc(docId).set({
          'name': name,
          'specialty': specialty,
          'location': location,
          'timeSlots': timeSlots.split(','), // e.g., "9-10, 11-12"
          'email': user.email,
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile added successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Dashboard - ${widget.userName}'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (value) => name = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Specialty'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (value) => specialty = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (value) => location = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Time Slots (comma-separated)'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (value) => timeSlots = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addDoctorProfile,
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}