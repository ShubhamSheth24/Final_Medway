import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_pharmacy/main_screen.dart';

class PatientRegistrationPage extends StatefulWidget {
  final String docId;
  final String userName;
  final String email;

  const PatientRegistrationPage({
    required this.docId,
    required this.userName,
    required this.email,
    super.key,
  });

  @override
  _PatientRegistrationPageState createState() =>
      _PatientRegistrationPageState();
}

class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedGender;
  String age = '';
  String medicalHistory = '';
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitPatientDetails() async {
    if (_formKey.currentState!.validate() && selectedGender != null) {
      setState(() => _isLoading = true);
      try {
        await _firestore.collection('patients').doc(widget.docId).update({
          'age': int.parse(age),
          'gender': selectedGender,
          'medicalHistory': [
            medicalHistory,
          ], // Stored as a list as per original structure
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(userName: widget.userName),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving details: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                value: selectedGender,
                items:
                    ['Male', 'Female', 'Other']
                        .map(
                          (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => selectedGender = value),
                validator:
                    (value) => value == null ? 'Please select a gender' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
                onChanged: (value) => setState(() => age = value),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Medical History',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator:
                    (value) =>
                        value!.isEmpty
                            ? 'Please enter your medical history'
                            : null,
                onChanged: (value) => setState(() => medicalHistory = value),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPatientDetails,
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
