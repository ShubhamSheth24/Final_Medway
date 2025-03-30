import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_pharmacy/home_page.dart';
import 'package:flutter_application_pharmacy/models/user_model';
import 'package:flutter_application_pharmacy/screens/doctor_dashboard.dart';
import 'package:flutter_application_pharmacy/screens/pharmacist_dashboard.dart';
import 'package:flutter_application_pharmacy/signup.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> with SingleTickerProviderStateMixin {
  bool passwordVisible = false;
  String email = '';
  String password = '';
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print("SignIn initState started");
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    print("SignIn dispose called");
    _animationController.dispose();
    super.dispose();
  }

  String _generateDocId(String email) {
    return email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String docId = _generateDocId(user.email ?? "googleuser");

        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(docId).get();

        String userName = '';
        String? userRole;
        String? phone;
        DateTime? createdAt;

        if (userDoc.exists) {
          userName = userDoc['name'] ?? "No Name";
          userRole = userDoc['role'] ?? "Patient";
          phone = userDoc['phone'] ?? "";
          createdAt = (userDoc['createdAt'] as Timestamp?)?.toDate();
        } else {
          userName = user.displayName ?? "No Name";
          userRole = "Patient"; // Default role
          phone = "";
          createdAt = DateTime.now();
          await _firestore.collection('users').doc(docId).set({
            'docId': docId,
            'name': userName,
            'email': user.email ?? "No Email",
            'role': userRole,
            'phone': phone,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (userRole == 'Patient') {
            await _firestore.collection('patients').doc(docId).set({
              'docId': docId,
              'age': null,
              'gender': null,
              'medicalHistory': [],
              'caretakerId': null,
              'prescriptions': [],
            }, SetOptions(merge: true));
          } else if (userRole == 'Caretaker') {
            await _firestore.collection('caretakers').doc(docId).set({
              'docId': docId,
              'patientIds': [],
              'emergencyContact': null,
            }, SetOptions(merge: true));
          } else if (userRole == 'Doctor') {
            await _firestore.collection('doctors').doc(docId).set({
              'name': userName,
              'specialty': '',
              'location': '',
              'timeSlots': [],
              'email': user.email,
            }, SetOptions(merge: true));
          } else if (userRole == 'Pharmacist') {
            await _firestore.collection('pharmacies').doc(docId).set({
              'name': '',
              'location': '',
              'medicines': [],
              'email': user.email,
            }, SetOptions(merge: true));
          }
        }

        Provider.of<UserModel>(context, listen: false).setUser(
          docId: docId,
          name: userName,
          email: user.email ?? "No Email",
          role: userRole,
          phone: phone,
          createdAt: createdAt,
        );

        if (!mounted) return;
        print("Google Sign-In successful: $userName, Role: $userRole");
        _navigateBasedOnRole(userRole, userName);
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In Error: $e"),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      print("Starting email/password sign-in with email: $email");

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        User? user = userCredential.user;

        print("User signed in successfully: ${user?.uid}");

        if (user != null) {
          String docId = _generateDocId(email);

          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(docId).get();

          String userName = "No Name";
          String? userRole;
          String? phone;
          DateTime? createdAt;

          if (userDoc.exists) {
            userName = userDoc['name'] ?? "No Name";
            userRole = userDoc['role'] ?? "Patient";
            phone = userDoc['phone'] ?? "";
            createdAt = (userDoc['createdAt'] as Timestamp?)?.toDate();
            print("User data found in Firestore: $userName, Role: $userRole");
          } else {
            print("No user data found in Firestore, creating new entry");
            userRole = "Patient"; // Default role
            phone = "";
            createdAt = DateTime.now();
            await _firestore.collection('users').doc(docId).set({
              'docId': docId,
              'name': userName,
              'email': email,
              'role': userRole,
              'phone': phone,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            if (userRole == 'Patient') {
              await _firestore.collection('patients').doc(docId).set({
                'docId': docId,
                'age': null,
                'gender': null,
                'medicalHistory': [],
                'caretakerId': null,
                'prescriptions': [],
              }, SetOptions(merge: true));
            } else if (userRole == 'Caretaker') {
              await _firestore.collection('caretakers').doc(docId).set({
                'docId': docId,
                'patientIds': [],
                'emergencyContact': null,
              }, SetOptions(merge: true));
            } else if (userRole == 'Doctor') {
              await _firestore.collection('doctors').doc(docId).set({
                'name': userName,
                'specialty': '',
                'location': '',
                'timeSlots': [],
                'email': email,
              }, SetOptions(merge: true));
            } else if (userRole == 'Pharmacist') {
              await _firestore.collection('pharmacies').doc(docId).set({
                'name': '',
                'location': '',
                'medicines': [],
                'email': email,
              }, SetOptions(merge: true));
            }
          }

          Provider.of<UserModel>(context, listen: false).setUser(
            docId: docId,
            name: userName,
            email: email,
            role: userRole,
            phone: phone,
            createdAt: createdAt,
          );

          if (!mounted) return;
          print("Sign-In successful: $userName, Role: $userRole");
          _navigateBasedOnRole(userRole, userName);
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = "Sign-in failed";
        if (e.code == 'user-not-found') {
          errorMessage = "No user found with this email";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Incorrect password";
        }
        print("Sign-In Error: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        print("Unexpected Sign-In Error: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _navigateBasedOnRole(String? role, String userName) {
    switch (role) {
      case "Doctor":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DoctorDashboard(userName: userName)),
        );
        break;
      case "Pharmacist":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PharmacistDashboard(userName: userName)),
        );
        break;
      case "Patient":
      case "Caretaker":
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userName: userName)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: AppBar(
                    backgroundColor: Colors.blue.shade50,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    centerTitle: true,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  prefixIcon: Icons.email,
                  labelText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Email is required';
                    } else if (!value.contains('@') || !value.endsWith('.com')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() => email = value),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  prefixIcon: Icons.lock,
                  labelText: 'Enter your password',
                  obscureText: !passwordVisible,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Password is required';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() => password = value),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => passwordVisible = !passwordVisible),
                  ),
                ),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account? ',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SignUp()),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                    Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/7123025_logo_google_g_icon.png", height: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildTextField({
    required IconData prefixIcon,
    required String labelText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, color: Colors.grey),
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}