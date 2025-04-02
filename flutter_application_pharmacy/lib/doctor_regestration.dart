import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_profile.dart';

class DoctorRegistrationPage extends StatefulWidget {
  final String userName;
  final String email;

  const DoctorRegistrationPage({
    super.key,
    required this.userName,
    required this.email,
  });

  @override
  _DoctorRegistrationPageState createState() => _DoctorRegistrationPageState();
}

class _DoctorRegistrationPageState extends State<DoctorRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  List<String> allDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  List<bool> daySelection = List.generate(7, (index) => false);

  List<String> allSlots = [
    "9:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "1:00 PM",
    "2:00 PM",
    "3:00 PM",
    "4:00 PM",
    "5:00 PM",
    "6:00 PM",
    "7:00 PM",
    "8:00 PM",
  ];
  List<bool> slotSelection = List.generate(12, (index) => false);

  bool _isLoading = false;

  Future<void> registerDoctor() async {
    if (_formKey.currentState!.validate()) {
      if (!daySelection.contains(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please select at least one available day"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      if (!slotSelection.contains(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please select at least one time slot"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      List<Map<String, dynamic>> availableSlots = [];
      for (int i = 0; i < allSlots.length; i++) {
        if (slotSelection[i]) {
          availableSlots.add({"time": allSlots[i], "isBooked": false});
        }
      }

      List<String> selectedDays = [];
      for (int i = 0; i < allDays.length; i++) {
        if (daySelection[i]) {
          selectedDays.add(allDays[i]);
        }
      }

      try {
        // Add doctor to Firestore and get the document reference
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('doctors')
            .add({
              "email": widget.email, // Use the email passed from SignIn
              "fullName": _fullNameController.text.trim(),
              "specialty": _specialtyController.text.trim(),
              "location": _locationController.text.trim(),
              "age": int.parse(_ageController.text.trim()),
              "mobile": _mobileController.text.trim(),
              "availableDays": selectedDays,
              "availableSlots": availableSlots,
              "createdAt": FieldValue.serverTimestamp(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Doctor Registered Successfully"),
              ],
            ),
            backgroundColor: Colors.blue[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        _clearForm();

        // Navigate to DoctorProfilePage with the new doctor's ID
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorProfilePage(doctorId: docRef.id),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _fullNameController.clear();
    _specialtyController.clear();
    _locationController.clear();
    _ageController.clear();
    _mobileController.clear();
    setState(() {
      daySelection = List.generate(7, (index) => false);
      slotSelection = List.generate(12, (index) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Doctor Registration",
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.blue[600]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Doctor Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _fullNameController,
                    label: "Full Name",
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter full name";
                      }
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                        return "Name should only contain letters and spaces";
                      }
                      if (value.trim().length < 3) {
                        return "Name must be at least 3 characters long";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _specialtyController,
                    label: "Specialty",
                    icon: Icons.medical_services_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter specialty";
                      }
                      if (value.trim().length < 3) {
                        return "Specialty must be at least 3 characters long";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: "Practice Location",
                    icon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter practice location";
                      }
                      if (value.trim().length < 5) {
                        return "Location must be at least 5 characters long";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _ageController,
                          label: "Age",
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter age";
                            }
                            int? age = int.tryParse(value);
                            if (age == null) {
                              return "Please enter a valid number";
                            }
                            if (age < 25 || age > 100) {
                              return "Age must be between 25 and 100";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                          controller: _mobileController,
                          label: "Contact Number",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter contact number";
                            }
                            if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                              return "Please enter a valid 10-digit number";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Availability Schedule",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Available Days",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: List.generate(allDays.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  daySelection[index] = !daySelection[index];
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      daySelection[index]
                                          ? Colors.blue[500]
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        daySelection[index]
                                            ? Colors.blue[500]!
                                            : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  allDays[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        daySelection[index]
                                            ? Colors.white
                                            : Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Select Available Time Slots",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: List.generate(3, (rowIndex) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: rowIndex < 2 ? 8.0 : 0,
                              ),
                              child: Row(
                                children: List.generate(4, (colIndex) {
                                  int index = rowIndex * 4 + colIndex;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: colIndex < 3 ? 8.0 : 0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            slotSelection[index] =
                                                !slotSelection[index];
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                slotSelection[index]
                                                    ? Colors.blue[500]
                                                    : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  slotSelection[index]
                                                      ? Colors.blue[500]!
                                                      : Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              allSlots[index],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    slotSelection[index]
                                                        ? Colors.white
                                                        : Colors.grey[800],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: _isLoading ? null : registerDoctor,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[500],
                disabledBackgroundColor: Colors.blue[200],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        "Submit Registration",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[700]!, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[700]!, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
      validator: validator,
      style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
    );
  }
}
