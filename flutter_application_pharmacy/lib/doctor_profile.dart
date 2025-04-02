import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DoctorProfilePage extends StatefulWidget {
  final String doctorId;

  const DoctorProfilePage({super.key, required this.doctorId});

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage>
    with SingleTickerProviderStateMixin {
  late Future<DocumentSnapshot> _doctorFuture;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _doctorFuture =
        FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .get();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 📸 Pick an image from gallery (from your UploadImageScreen.dart)
  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      uploadImage();
    }
  }

  // 📤 Upload image to Firebase Storage (from your UploadImageScreen.dart)
  Future uploadImage() async {
    if (_image == null) return;

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child(
      'images/$fileName.jpg',
    );

    UploadTask uploadTask = storageRef.putFile(_image!);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    // Update Firestore with the image URL
    await _updateDoctorField({"profileImageUrl": downloadUrl});
    setState(() {
      _image = null; // Clear the local image after upload
    });
  }

  Future<void> _updateDoctorField(Map<String, dynamic> updatedData) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .update(updatedData);
      setState(() {
        _doctorFuture =
            FirebaseFirestore.instance
                .collection('doctors')
                .doc(widget.doctorId)
                .get();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profile updated successfully!"),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile: $e"),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _editPersonalInfo(
    String currentLocation,
    int currentAge,
    String currentMobile,
  ) {
    TextEditingController locationController = TextEditingController(
      text: currentLocation,
    );
    TextEditingController ageController = TextEditingController(
      text: currentAge.toString(),
    );
    TextEditingController mobileController = TextEditingController(
      text: currentMobile,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Personal Information"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: "Location"),
                  ),
                  TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: "Age"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: mobileController,
                    decoration: const InputDecoration(labelText: "Mobile"),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _updateDoctorField({
                    "location": locationController.text.trim(),
                    "age": int.parse(ageController.text.trim()),
                    "mobile": mobileController.text.trim(),
                  });
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  void _editAvailableDays(List<String> currentDays) {
    List<String> allDays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    List<bool> daySelection =
        allDays.map((day) => currentDays.contains(day)).toList();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text("Edit Available Days"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(allDays.length, (index) {
                        return CheckboxListTile(
                          title: Text(allDays[index]),
                          value: daySelection[index],
                          onChanged: (value) {
                            setState(() {
                              daySelection[index] = value!;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        List<String> selectedDays = [];
                        for (int i = 0; i < allDays.length; i++) {
                          if (daySelection[i]) {
                            selectedDays.add(allDays[i]);
                          }
                        }
                        _updateDoctorField({"availableDays": selectedDays});
                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
          ),
    );
  }

  void _editAvailableSlots(List<dynamic> currentSlots) {
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
    List<bool> slotSelection =
        allSlots.map((slot) {
          return currentSlots.any((s) => s['time'] == slot);
        }).toList();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text("Edit Available Time Slots"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(allSlots.length, (index) {
                        return CheckboxListTile(
                          title: Text(allSlots[index]),
                          value: slotSelection[index],
                          onChanged: (value) {
                            setState(() {
                              slotSelection[index] = value!;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        List<Map<String, dynamic>> updatedSlots = [];
                        for (int i = 0; i < allSlots.length; i++) {
                          if (slotSelection[i]) {
                            bool isBooked = currentSlots.any(
                              (s) => s['time'] == allSlots[i] && s['isBooked'],
                            );
                            updatedSlots.add({
                              "time": allSlots[i],
                              "isBooked": isBooked,
                            });
                          }
                        }
                        _updateDoctorField({"availableSlots": updatedSlots});
                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _doctorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading profile",
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String fullName = data['fullName'];
          String specialty = data['specialty'];
          String location = data['location'];
          int age = data['age'];
          String mobile = data['mobile'];
          List<String> availableDays = List<String>.from(data['availableDays']);
          List<dynamic> availableSlots = data['availableSlots'];
          String? profileImageUrl = data['profileImageUrl'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[900]!, Colors.blue[700]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: pickImage, // Trigger image picker on tap
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  profileImageUrl != null
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                              child:
                                  profileImageUrl == null
                                      ? Text(
                                        fullName[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Dr. $fullName",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Doctor Info Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Personal Information",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue[700],
                                onPressed:
                                    () => _editPersonalInfo(
                                      location,
                                      age,
                                      mobile,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.location_on,
                            "Location",
                            location,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.person, "Age", age.toString()),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.phone, "Mobile", mobile),
                        ],
                      ),
                    ),
                  ),
                ),
                // Available Days Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Available Days",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue[700],
                                onPressed:
                                    () => _editAvailableDays(availableDays),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children:
                                availableDays.map((day) {
                                  return Chip(
                                    label: Text(
                                      day,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.blue[700],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 2,
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Available Slots Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Available Time Slots",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue[700],
                                onPressed:
                                    () => _editAvailableSlots(availableSlots),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children:
                                availableSlots.map((slot) {
                                  bool isBooked = slot['isBooked'];
                                  String time = slot['time'];
                                  return Chip(
                                    label: Text(
                                      "$time (${isBooked ? 'Booked' : 'Available'})",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isBooked
                                                ? Colors.grey[800]
                                                : Colors.green[800],
                                      ),
                                    ),
                                    backgroundColor:
                                        isBooked
                                            ? Colors.grey[300]
                                            : Colors.green[100],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color:
                                            isBooked
                                                ? Colors.grey[400]!
                                                : Colors.green[400]!,
                                        width: 1,
                                      ),
                                    ),
                                    elevation: 2,
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[700], size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
