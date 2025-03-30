import 'package:flutter/material.dart';

class UserModel with ChangeNotifier {
  String? docId; // Custom document ID (e.g., patient1, caretaker1)
  String? name;
  String? email;
  String? role;
  String? phone;
  DateTime? createdAt;

  // Role-specific fields
  // For Patients
  int? age;
  String? gender;
  String? caretakerId; // Custom doc ID of the caretaker (e.g., caretaker1)
  List<Map<String, dynamic>>? medicalHistory;
  List<Map<String, dynamic>>? prescriptions;

  // For Caretakers
  List<String>? patientIds; // List of custom patient doc IDs (e.g., [patient1, patient2])
  String? emergencyContact;

  // Getter for profile image (placeholder)
  String? get profileImageUrl => null;

  // Set user data
  void setUser({
    required String docId,
    required String name,
    required String email,
    required String? role,
    String? phone,
    DateTime? createdAt,
  }) {
    this.docId = docId;
    this.name = name;
    this.email = email;
    this.role = role;
    this.phone = phone ?? "";
    this.createdAt = createdAt ?? DateTime.now();

    // Initialize role-specific fields
    if (role == 'Patient') {
      age = null;
      gender = null;
      caretakerId = null; // Will be set later with custom doc ID
      medicalHistory = [];
      prescriptions = [];
    } else if (role == 'Caretaker') {
      patientIds = []; // Will be set later with custom doc IDs
      emergencyContact = null;
    }

    notifyListeners();
  }

  // Clear user data
  void clearUser() {
    docId = null;
    name = null;
    email = null;
    role = null;
    phone = null;
    createdAt = null;
    age = null;
    gender = null;
    caretakerId = null;
    medicalHistory = null;
    prescriptions = null;
    patientIds = null;
    emergencyContact = null;
    notifyListeners();
  }

  // Update individual fields
  void updateName(String newName) {
    name = newName;
    notifyListeners();
  }

  void updatePhone(String newPhone) {
    phone = newPhone;
    notifyListeners();
  }

  // Update Patient details
  void updatePatientDetails({
    int? newAge,
    String? newGender,
    String? newCaretakerId, // Custom caretaker doc ID
    List<Map<String, dynamic>>? newMedicalHistory,
    List<Map<String, dynamic>>? newPrescriptions,
  }) {
    if (role == 'Patient') {
      age = newAge ?? age;
      gender = newGender ?? gender;
      caretakerId = newCaretakerId ?? caretakerId;
      medicalHistory = newMedicalHistory ?? medicalHistory;
      prescriptions = newPrescriptions ?? prescriptions;
      notifyListeners();
    }
  }

  // Update Caretaker details
  void updateCaretakerDetails({
    List<String>? newPatientIds, // List of custom patient doc IDs
    String? newEmergencyContact,
  }) {
    if (role == 'Caretaker') {
      patientIds = newPatientIds ?? patientIds;
      emergencyContact = newEmergencyContact ?? emergencyContact;
      notifyListeners();
    }
  }

  // Placeholder for profile image
  void updateProfileImage(String? newImageUrl) {
    // Implement later if needed
    notifyListeners();
  }

  // Set or update role
  void setRole(String? newRole) {
    role = newRole;
    if (newRole == 'Patient') {
      age = null;
      gender = null;
      caretakerId = null;
      medicalHistory = [];
      prescriptions = [];
    } else if (newRole == 'Caretaker') {
      patientIds = [];
      emergencyContact = null;
    }
    notifyListeners();
  }
}