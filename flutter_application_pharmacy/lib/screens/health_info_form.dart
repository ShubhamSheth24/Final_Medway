import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class HealthInfoForm extends StatefulWidget {
  final String userName;
  const HealthInfoForm({super.key, required this.userName});

  @override
  _HealthInfoFormState createState() => _HealthInfoFormState();
}

class _HealthInfoFormState extends State<HealthInfoForm> {
  final _formKey = GlobalKey<FormState>();
  String? _weight;
  String? _bloodGroup;
  String? _docId;
  String? _linkedDocId;

  // Static list of blood groups
  final List<String> _bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint("HealthInfoForm - Loading data for UID: ${user.uid}");
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      _docId = userDoc.id;
      _linkedDocId = userDoc.data()?['linkedDocId'] as String?;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_docId)
              .collection('health_info')
              .doc('data')
              .get();
      if (doc.exists) {
        setState(() {
          _weight = doc['weight'] as String?;
          _bloodGroup =
              _bloodGroups.contains(doc['bloodGroup'] as String?)
                  ? doc['bloodGroup'] as String?
                  : "A+";
          debugPrint(
            "HealthInfoForm - Loaded data: Weight: $_weight, Blood Group: $_bloodGroup",
          );
        });
      } else {
        setState(() {
          _weight = "103"; // Default weight
          _bloodGroup = "A+"; // Default blood group
        });
        debugPrint("HealthInfoForm - No existing data found, using defaults.");
      }
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint(
          "HealthInfoForm - Attempting to save data for UID: ${user.uid}, Weight: $_weight, Blood Group: $_bloodGroup, DocId: $_docId, LinkedDocId: $_linkedDocId",
        );

        try {
          // Save to caretaker's document
          DocumentReference caretakerRef = FirebaseFirestore.instance
              .collection('users')
              .doc(_docId)
              .collection('health_info')
              .doc('data');

          await caretakerRef.set({
            'weight': _weight,
            'bloodGroup': _bloodGroup,
            'updatedBy': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Verify the save
          DocumentSnapshot caretakerDoc = await caretakerRef.get();
          if (caretakerDoc.exists &&
              caretakerDoc['weight'] == _weight &&
              caretakerDoc['bloodGroup'] == _bloodGroup) {
            debugPrint(
              "HealthInfoForm - Verified save to caretaker's doc: $_docId/health_info/data - Weight: ${caretakerDoc['weight']}, Blood Group: ${caretakerDoc['bloodGroup']}",
            );
          } else {
            debugPrint(
              "HealthInfoForm - Save to caretaker's doc failed verification: Data not found or mismatched",
            );
          }

          // If linked, save to patient's document
          if (_linkedDocId != null && _linkedDocId!.isNotEmpty) {
            DocumentReference patientRef = FirebaseFirestore.instance
                .collection('users')
                .doc(_linkedDocId)
                .collection('health_info')
                .doc('data');

            await patientRef.set({
              'weight': _weight,
              'bloodGroup': _bloodGroup,
              'updatedBy': user.uid,
              'timestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            // Verify the save
            DocumentSnapshot patientDoc = await patientRef.get();
            if (patientDoc.exists &&
                patientDoc['weight'] == _weight &&
                patientDoc['bloodGroup'] == _bloodGroup) {
              debugPrint(
                "HealthInfoForm - Verified save to patient's doc: $_linkedDocId/health_info/data - Weight: ${patientDoc['weight']}, Blood Group: ${patientDoc['bloodGroup']}",
              );
            } else {
              debugPrint(
                "HealthInfoForm - Save to patient's doc failed verification: Data not found or mismatched",
              );
            }
          } else {
            debugPrint(
              "HealthInfoForm - No linked patient found, skipping patient save",
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Health info saved successfully!')),
          );
          Navigator.pop(context, true);
        } catch (e) {
          debugPrint("HealthInfoForm - Error saving data: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving health info: $e')),
          );
        }
      } else {
        debugPrint("HealthInfoForm - No authenticated user found");
      }
    } else {
      debugPrint("HealthInfoForm - Form validation failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Health Info'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: _weight,
                  decoration: const InputDecoration(
                    labelText: 'Weight (lbs)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Only numbers
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter weight';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => _weight = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _bloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _bloodGroups.map((String bloodGroup) {
                        return DropdownMenuItem<String>(
                          value: bloodGroup,
                          child: Text(bloodGroup),
                        );
                      }).toList(),
                  validator:
                      (value) => value == null ? 'Select a blood group' : null,
                  onChanged: (String? newValue) {
                    setState(() {
                      _bloodGroup = newValue;
                    });
                  },
                  onSaved: (value) => _bloodGroup = value,
                ),
                const SizedBox(height: 16), // Space reserved for heart rate
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveData,
                  child: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
