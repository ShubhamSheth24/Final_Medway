import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PharmacistDashboard extends StatefulWidget {
  final String userName;

  const PharmacistDashboard({super.key, required this.userName});

  @override
  _PharmacistDashboardState createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<PharmacistDashboard> {
  final _formKey = GlobalKey<FormState>();
  String pharmacyName = '';
  String location = '';
  String medicineName = '';
  String quantity = '';

  Future<void> _addPharmacy() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String docId = user.email!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        await FirebaseFirestore.instance.collection('pharmacies').doc(docId).set({
          'name': pharmacyName,
          'location': location,
          'medicines': FieldValue.arrayUnion([
            {'name': medicineName, 'quantity': quantity}
          ]),
          'email': user.email,
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pharmacy added successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pharmacist Dashboard - ${widget.userName}'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Pharmacy Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (value) => pharmacyName = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (value) => location = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Medicine Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (value) => medicineName = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (value) => quantity = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addPharmacy,
                child: const Text('Add Pharmacy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}