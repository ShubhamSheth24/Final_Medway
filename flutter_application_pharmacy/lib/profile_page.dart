import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_pharmacy/home_page.dart';
import 'package:flutter_application_pharmacy/models/user_model';
import 'package:flutter_application_pharmacy/reports.dart';
import 'package:flutter_application_pharmacy/screens/faqs_page.dart';
import 'package:flutter_application_pharmacy/screens/logout_page.dart';
import 'package:flutter_application_pharmacy/widgets/custom_bottom_nav_bar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For Clipboard

const defaultPadding = EdgeInsets.symmetric(horizontal: 16);

class ProfilePage extends StatefulWidget {
  final String userName;
  const ProfilePage({super.key, required this.userName});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isLoading = false;
  String? _userEmail;
  String? _linkedDocId;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _docIdController = TextEditingController();
  int _currentIndex = 3; // Profile is index 3
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print("ProfilePage initState started");

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchUserData();
    });
  }

  @override
  void dispose() {
    print("ProfilePage dispose called");
    _animationController.dispose();
    _docIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No authenticated user found");
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    print("Fetching user data for UID: ${user.uid}");
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists && mounted) {
        final userModel = Provider.of<UserModel>(context, listen: false);
        setState(() {
          _userEmail = user.email;
          _linkedDocId = snapshot.get('linkedDocId') ?? '';
          _profileImageUrl = snapshot.get('profileImageUrl') ?? '';
          _isLoading = false;
        });
        userModel.updateName(widget.userName);
        userModel.updateProfileImage(_profileImageUrl ?? '');
        print("User data fetched: ${widget.userName}, ProfileImage: $_profileImageUrl, Role: ${snapshot.get('role')}");

        try {
          String docId =""; 
        final QuerySnapshot querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          docId = querySnapshot.docs.first.id;
        }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userName', widget.userName);
          await prefs.setString('userEmail', _userEmail ?? '');
          await prefs.setString('role', snapshot.get('role') ?? 'Patient');
          await prefs.setString('profileImageUrl', _profileImageUrl ?? '');
          print("Stored in SharedPreferences: ${widget.userName}, $_userEmail, ${snapshot.get('role')}");
        } catch (e) {
          print("SharedPreferences error: $e");
        }
      } else if (mounted) {
        setState(() {
          _userEmail = user.email;
          _isLoading = false;
        });
        print("No user document found for ${user.uid}, using email: $_userEmail");
      }
    } catch (e) {
      print("Firestore fetch error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upload an image')),
      );
      return;
    }

    final permissionStatus = await Permission.photos.request();
    if (permissionStatus.isGranted) {
      try {
        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() => _selectedImage = File(pickedFile.path));
          await _uploadImage();
        }
      } catch (e) {
        print("Error picking image: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } else {
      print("Gallery permission denied");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery permission denied')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final storageRef = FirebaseStorage.instance.ref().child(
          'profile_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'profileImageUrl': downloadUrl}, SetOptions(merge: true));

      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel.updateProfileImage(downloadUrl);
      setState(() {
        _profileImageUrl = downloadUrl;
        _selectedImage = null;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageUrl', downloadUrl);
        print("Profile image stored in SharedPreferences: $downloadUrl");
      } catch (e) {
        print("SharedPreferences error: $e");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image uploaded successfully!')),
      );
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _linkCaretaker(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to link')),
      );
      return;
    }

    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Patient Doc ID')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();

      if (snapshot.exists && snapshot.get('role') == 'Patient') {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'linkedDocId': docId}, SetOptions(merge: true));
        await FirebaseFirestore.instance.collection('users').doc(docId).set(
            {'linkedDocId': user.uid}, SetOptions(merge: true));
        setState(() {
          _linkedDocId = docId;
          _docIdController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Linked to Patient: $docId')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Patient ID')),
        );
      }
    } catch (e) {
      print("Error linking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error linking: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyDocIdToClipboard(String docId) {
    Clipboard.setData(ClipboardData(text: docId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Doc ID copied to clipboard!')),
    );
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return; // Prevent re-navigating to same page
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userName: widget.userName)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ReportsPage(userName: widget.userName)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RemindersScreen()),
        );
        break;
      case 3:
        // Already on ProfilePage
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userModel = Provider.of<UserModel>(context);
    final isPatient = userModel.role == 'Patient';
    final isCaretaker = userModel.role == 'Caretaker';

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('Please sign in to view your profile'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: Column(
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.blueAccent.withOpacity(0.5),
                                            width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 2,
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                            ? NetworkImage(_profileImageUrl!)
                                            : const AssetImage('assets/profile.jpg') as ImageProvider,
                                        backgroundColor: Colors.grey[200],
                                        onBackgroundImageError: (exception, stackTrace) {
                                          print("Error loading image: $exception");
                                        },
                                      ),
                                    ),
                                  ),
                                  if (!_isLoading)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.blueAccent,
                                          child: const Icon(Icons.edit, size: 20, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  if (_isLoading)
                                    const Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircularProgressIndicator(
                                        color: Colors.blueAccent,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Text(
                                  widget.userName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    Text(
                                      _userEmail ?? 'Loading...',
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                    if (_linkedDocId != null && _linkedDocId!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        isPatient ? 'Caretaker ID: $_linkedDocId' : 'Linked to Patient: $_linkedDocId',
                                        style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (isPatient && (_linkedDocId == null || _linkedDocId!.isEmpty))
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Your Doc ID: ${user!.uid}',
                                        style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 20, color: Colors.blueAccent),
                                        onPressed: () => _copyDocIdToClipboard(user.uid),
                                        tooltip: 'Copy Doc ID',
                                      ),
                                    ],
                                  ),
                                ),
                              if (isCaretaker && (_linkedDocId == null || _linkedDocId!.isEmpty))
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _docIdController,
                                          decoration: InputDecoration(
                                            hintText: 'Enter Patient Doc ID',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => _linkCaretaker(_docIdController.text.trim()),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text('Link', style: TextStyle(fontSize: 14)),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildHealthStat("Heart rate", "215bpm", Icons.favorite),
                                  _buildHealthStat("Calories", "756cal", Icons.local_fire_department),
                                  _buildHealthStat("Weight", "103lbs", Icons.fitness_center),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildProfileOption(
                          context,
                          "FAQs",
                          Icons.help_outline,
                          Colors.orange,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FAQsPage())),
                        ),
                        _buildProfileOption(
                          context,
                          "Logout",
                          Icons.exit_to_app,
                          Colors.red,
                          () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LogoutPage())),
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildHealthStat(String title, String value, IconData icon) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey.shade50,
        child: ListTile(
          leading: Icon(icon, color: color, size: 24),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Reminders')), body: const Center(child: Text('Reminders Page')));
  }
}