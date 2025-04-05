import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class MedicalRecordsPage extends StatefulWidget {
  final String linkedDocId;
  final bool isPatientView;

  const MedicalRecordsPage({
    super.key,
    required this.linkedDocId,
    this.isPatientView = false,
  });

  @override
  _MedicalRecordsPageState createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = false;

  Future<void> _uploadMedicalRecord() async {
    final permissionStatus = await Permission.photos.request();
    if (permissionStatus.isGranted) {
      try {
        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() => _isLoading = true);
          final file = File(pickedFile.path);
          try {
            final storageRef = _storage.ref().child(
              'medical_records/${widget.linkedDocId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            final uploadTask = storageRef.putFile(file);
            final snapshot = await uploadTask;
            final downloadUrl = await snapshot.ref.getDownloadURL();

            DocumentSnapshot patientDoc =
                await _firestore
                    .collection('users')
                    .doc(widget.linkedDocId)
                    .get();
            final patientData =
                patientDoc.exists
                    ? patientDoc.data() as Map<String, dynamic>?
                    : null;
            List<dynamic> existingRecords =
                patientData != null &&
                        patientData.containsKey('medicalRecordUrls')
                    ? List.from(patientData['medicalRecordUrls'])
                    : [];
            existingRecords.add(downloadUrl);

            await _firestore.collection('users').doc(widget.linkedDocId).set({
              'medicalRecordUrls': existingRecords,
            }, SetOptions(merge: true));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Medical record uploaded successfully!'),
              ),
            );
          } catch (e) {
            print("Error uploading medical record: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error uploading medical record: $e')),
            );
          } finally {
            setState(() => _isLoading = false);
          }
        }
      } catch (e) {
        print("Error picking medical record: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking medical record: $e')),
        );
      }
    } else {
      print("Gallery permission denied");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery permission denied')),
      );
    }
  }

  Future<void> _deleteMedicalRecord(String url) async {
    setState(() => _isLoading = true);
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();

      DocumentSnapshot patientDoc =
          await _firestore.collection('users').doc(widget.linkedDocId).get();
      final patientData =
          patientDoc.exists ? patientDoc.data() as Map<String, dynamic>? : null;
      List<dynamic> existingRecords =
          patientData != null && patientData.containsKey('medicalRecordUrls')
              ? List.from(patientData['medicalRecordUrls'])
              : [];
      existingRecords.remove(url);

      await _firestore.collection('users').doc(widget.linkedDocId).set({
        'medicalRecordUrls': existingRecords,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical record deleted successfully!')),
      );
    } catch (e) {
      print("Error deleting medical record: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting medical record: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medical Records',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!widget.isPatientView)
            IconButton(
              icon: const Icon(Icons.add_a_photo, color: Colors.white),
              onPressed: _isLoading ? null : _uploadMedicalRecord,
              tooltip: 'Upload Medical Record',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<DocumentSnapshot>(
                future:
                    _firestore
                        .collection('users')
                        .doc(widget.linkedDocId)
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData ||
                      snapshot.hasError ||
                      !snapshot.data!.exists) {
                    return const Center(
                      child: Text('No medical records available'),
                    );
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  List<dynamic> medicalRecordUrls =
                      data != null && data.containsKey('medicalRecordUrls')
                          ? List.from(data['medicalRecordUrls'])
                          : [];
                  if (medicalRecordUrls.isEmpty) {
                    return const Center(
                      child: Text('No medical records uploaded yet'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: medicalRecordUrls.length,
                    itemBuilder: (context, index) {
                      final url = medicalRecordUrls[index];
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => Dialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.network(
                                            url,
                                            fit: BoxFit.contain,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Text(
                                                'Error loading image',
                                              );
                                            },
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Image.network(
                                url,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text('Error loading image');
                                },
                              ),
                            ),
                          ),
                          if (!widget.isPatientView)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteMedicalRecord(url),
                                tooltip: 'Delete Medical Record',
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
    );
  }
}
