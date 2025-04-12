// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_pharmacy/doctor_regestration.dart';
// import 'package:flutter_application_pharmacy/main_screen.dart';
// import 'package:flutter_application_pharmacy/models/user_model.dart';
// import 'package:flutter_application_pharmacy/signup.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_application_pharmacy/doctor_profile.dart';
// import 'package:flutter_application_pharmacy/pharmacy_registration.dart';
// import 'package:flutter_application_pharmacy/pharmacy_profile.dart';

// class SignIn extends StatefulWidget {
//   const SignIn({super.key});

//   @override
//   _SignInState createState() => _SignInState();
// }

// class _SignInState extends State<SignIn> with SingleTickerProviderStateMixin {
//   bool passwordVisible = false;
//   String email = '';
//   String password = '';
//   bool _isLoading = false;

//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     print("SignIn initState started");
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     print("SignIn dispose called");
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<String?> _showRoleSelectionDialog() async {
//     String? selectedRole;
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Select Your Role'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(
//                   labelText: 'Role',
//                   border: OutlineInputBorder(),
//                 ),
//                 value: selectedRole,
//                 items:
//                     ['Patient', 'Caretaker', 'Doctor', 'Pharmacist']
//                         .map(
//                           (role) =>
//                               DropdownMenuItem(value: role, child: Text(role)),
//                         )
//                         .toList(),
//                 onChanged: (value) => setState(() => selectedRole = value),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 if (selectedRole != null) {
//                   Navigator.of(context).pop(selectedRole);
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Please select a role')),
//                   );
//                 }
//               },
//               child: const Text('Confirm'),
//             ),
//           ],
//         );
//       },
//     );
//     return selectedRole;
//   }

//   Future<void> signInWithGoogle() async {
//     setState(() => _isLoading = true);
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       UserCredential userCredential = await _auth.signInWithCredential(
//         credential,
//       );
//       User? user = userCredential.user;

//       if (user != null) {
//         String validEmail = user.email ?? "unknown.google@example.com";
//         if (!validEmail.contains('@')) {
//           validEmail = "unknown.google@example.com";
//         }
//         String validUserName = user.displayName ?? "Unknown";

//         print("Google Sign-In - Email: $validEmail, Name: $validUserName");

//         QuerySnapshot userQuery =
//             await _firestore
//                 .collection('users')
//                 .where('email', isEqualTo: validEmail)
//                 .limit(1)
//                 .get();

//         String docId;
//         String userName = validUserName;
//         String? userRole;
//         String? phone;
//         DateTime? createdAt;

//         if (userQuery.docs.isNotEmpty) {
//           DocumentSnapshot userDoc = userQuery.docs.first;
//           docId = userDoc.id;
//           userName = userDoc['name'] ?? userName;
//           userRole = userDoc['role'] ?? "Patient";
//           phone = userDoc['phone'] ?? "";
//           createdAt = (userDoc['createdAt'] as Timestamp?)?.toDate();
//         } else {
//           userRole = await _showRoleSelectionDialog();
//           if (userRole == null) {
//             setState(() => _isLoading = false);
//             return;
//           }

//           DocumentReference newDoc = await _firestore.collection('users').add({
//             'name': userName,
//             'email': validEmail,
//             'role': userRole,
//             'phone': "",
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//           docId = newDoc.id;
//           phone = "";
//           createdAt = DateTime.now();

//           if (userRole == 'Patient') {
//             await _firestore.collection('patients').doc(docId).set({
//               'docId': docId,
//               'age': 0,
//               'gender': '',
//               'medicalHistory': [],
//               'caretakerId': '',
//               'prescriptions': [],
//             });
//           } else if (userRole == 'Caretaker') {
//             await _firestore.collection('caretakers').doc(docId).set({
//               'docId': docId,
//               'patientIds': [],
//               'emergencyContact': null,
//             });
//           } else if (userRole == 'Doctor') {
//             await _firestore.collection('doctors').doc(docId).set({
//               'name': userName,
//               'specialty': '',
//               'location': '',
//               'timeSlots': [],
//               'email': validEmail,
//             });
//           } else if (userRole == 'Pharmacist') {
//             await _firestore.collection('pharmacies').doc(docId).set({
//               'name': '',
//               'location': '',
//               'medicines': [],
//               'email': validEmail,
//             });
//           }
//         }

//         Provider.of<UserModel>(context, listen: false).setUser(
//           docId: docId,
//           name: userName,
//           email: validEmail,
//           role: userRole,
//           phone: phone,
//           createdAt: createdAt,
//         );

//         if (!mounted) return;
//         print(
//           "Google Sign-In successful: $userName, Role: $userRole, DocId: $docId",
//         );
//         _navigateBasedOnRole(userRole, userName, validEmail);
//       }
//     } catch (e) {
//       print("Google Sign-In Error: $e");
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Google Sign-In Error: $e"),
//           backgroundColor: Colors.red.withOpacity(0.8),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> handleSubmit() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
//       print("Starting email/password sign-in with email: $email");

//       try {
//         UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//           email: email,
//           password: password,
//         );
//         User? user = userCredential.user;

//         if (user != null) {
//           String validEmail = email;
//           String validUserName = "Unknown";

//           print("Email/Password Sign-In - Email: $validEmail");

//           QuerySnapshot userQuery =
//               await _firestore
//                   .collection('users')
//                   .where('email', isEqualTo: validEmail)
//                   .limit(1)
//                   .get();

//           String docId;
//           String userName = validUserName;
//           String? userRole;
//           String? phone;
//           DateTime? createdAt;

//           if (userQuery.docs.isNotEmpty) {
//             DocumentSnapshot userDoc = userQuery.docs.first;
//             docId = userDoc.id;
//             userName = userDoc['name'] ?? "No Name";
//             userRole = userDoc['role'] ?? "Patient";
//             phone = userDoc['phone'] ?? "";
//             createdAt = (userDoc['createdAt'] as Timestamp?)?.toDate();
//             print(
//               "User data found in Firestore: $userName, Role: $userRole, DocId: $docId",
//             );
//           } else {
//             if (!mounted) return;
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text("No account found. Please sign up first."),
//               ),
//             );
//             setState(() => _isLoading = false);
//             return;
//           }

//           Provider.of<UserModel>(context, listen: false).setUser(
//             docId: docId,
//             name: userName,
//             email: validEmail,
//             role: userRole,
//             phone: phone,
//             createdAt: createdAt,
//           );

//           if (!mounted) return;
//           print(
//             "Sign-In successful: $userName, Role: $userRole, DocId: $docId",
//           );
//           _navigateBasedOnRole(userRole, userName, validEmail);
//         }
//       } on FirebaseAuthException catch (e) {
//         String errorMessage = "Sign-in failed";
//         if (e.code == 'user-not-found') {
//           errorMessage = "No user found with this email";
//         } else if (e.code == 'wrong-password') {
//           errorMessage = "Incorrect password";
//         }
//         print("Sign-In Error: $e");
//         if (!mounted) return;
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(errorMessage)));
//       } catch (e) {
//         print("Unexpected Sign-In Error: $e");
//         if (!mounted) return;
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error: $e")));
//       } finally {
//         if (mounted) setState(() => _isLoading = false);
//       }
//     }
//   }

//   Future<void> _navigateBasedOnRole(
//     String? role,
//     String userName,
//     String email,
//   ) async {
//     print("Navigating with Role: $role, Email: $email, UserName: $userName");

//     switch (role) {
//       case "Doctor":
//         QuerySnapshot doctorQuery =
//             await _firestore
//                 .collection('doctors')
//                 .where('email', isEqualTo: email)
//                 .limit(1)
//                 .get();

//         if (doctorQuery.docs.isNotEmpty) {
//           String doctorId = doctorQuery.docs.first.id;
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => DoctorProfilePage(doctorId: doctorId),
//             ),
//           );
//         } else {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (context) =>
//                       DoctorRegistrationPage(userName: userName, email: email),
//             ),
//           );
//         }
//         break;
//       case "Pharmacist":
//         QuerySnapshot pharmacyQuery =
//             await _firestore
//                 .collection('pharmacies')
//                 .where('email', isEqualTo: email)
//                 .limit(1)
//                 .get();

//         print("Pharmacy Query Result: ${pharmacyQuery.docs.length} docs found");
//         if (pharmacyQuery.docs.isNotEmpty) {
//           print("Pharmacy found with ID: ${pharmacyQuery.docs.first.id}");
//           String pharmacyId = pharmacyQuery.docs.first.id;
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PharmacyProfilePage(pharmacyId: pharmacyId),
//             ),
//           );
//         } else {
//           print("No pharmacy found, navigating to registration");
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (context) => PharmacyRegistrationPage(
//                     userName: userName,
//                     email: email,
//                   ),
//             ),
//           );
//         }
//         break;
//       case "Patient":
//       case "Caretaker":
//       default:
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => MainScreen(userName: userName),
//           ),
//         );
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             minHeight: MediaQuery.of(context).size.height,
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 20.0,
//               vertical: 16.0,
//             ),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   const SizedBox(height: 60),
//                   FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: AppBar(
//                       backgroundColor: Colors.transparent,
//                       elevation: 0,
//                       leading: IconButton(
//                         icon: const Icon(
//                           Icons.arrow_back,
//                           size: 30,
//                           color: Colors.black87,
//                         ),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       title: const Text(
//                         'Sign In',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       centerTitle: true,
//                     ),
//                   ),
//                   const SizedBox(height: 40),
//                   _buildTextField(
//                     prefixIcon: Icons.email,
//                     labelText: 'Enter your email',
//                     keyboardType: TextInputType.emailAddress,
//                     validator: (value) {
//                       if (value!.isEmpty) return 'Email is required';
//                       if (!value.contains('@') || !value.endsWith('.com'))
//                         return 'Enter a valid email';
//                       return null;
//                     },
//                     onChanged: (value) => setState(() => email = value),
//                   ),
//                   const SizedBox(height: 20),
//                   _buildTextField(
//                     prefixIcon: Icons.lock,
//                     labelText: 'Enter your password',
//                     obscureText: !passwordVisible,
//                     validator: (value) {
//                       if (value!.isEmpty) return 'Password is required';
//                       if (value.length < 6)
//                         return 'Password must be at least 6 characters';
//                       return null;
//                     },
//                     onChanged: (value) => setState(() => password = value),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         passwordVisible
//                             ? Icons.visibility
//                             : Icons.visibility_off,
//                         color: Colors.grey,
//                       ),
//                       onPressed:
//                           () => setState(
//                             () => passwordVisible = !passwordVisible,
//                           ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : handleSubmit,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         elevation: 4,
//                       ),
//                       child:
//                           _isLoading
//                               ? const SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                 ),
//                               )
//                               : const Text(
//                                 'Sign In',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text(
//                         'Don\'t have an account? ',
//                         style: TextStyle(color: Colors.grey, fontSize: 16),
//                       ),
//                       GestureDetector(
//                         onTap:
//                             () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const SignUp(),
//                               ),
//                             ),
//                         child: const Text(
//                           'Sign up',
//                           style: TextStyle(
//                             color: Colors.blue,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   const Row(
//                     children: [
//                       Expanded(child: Divider(color: Colors.grey)),
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 10.0),
//                         child: Text(
//                           'OR',
//                           style: TextStyle(color: Colors.grey, fontSize: 16),
//                         ),
//                       ),
//                       Expanded(child: Divider(color: Colors.grey)),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : signInWithGoogle,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         side: const BorderSide(color: Colors.grey),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         elevation: 2,
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset(
//                             "assets/7123025_logo_google_g_icon.png",
//                             height: 24,
//                           ),
//                           const SizedBox(width: 12),
//                           const Text(
//                             'Sign in with Google',
//                             style: TextStyle(
//                               color: Colors.black87,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required IconData prefixIcon,
//     required String labelText,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//     void Function(String)? onChanged,
//     bool obscureText = false,
//     Widget? suffixIcon,
//   }) {
//     return TextFormField(
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       decoration: InputDecoration(
//         prefixIcon: Icon(prefixIcon, color: Colors.grey),
//         labelText: labelText,
//         labelStyle: const TextStyle(color: Colors.grey, fontSize: 16),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Colors.blue, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.grey[100],
//         contentPadding: const EdgeInsets.symmetric(
//           vertical: 16,
//           horizontal: 16,
//         ),
//         suffixIcon: suffixIcon,
//       ),
//       validator: validator,
//       onChanged: onChanged,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_pharmacy/doctor_regestration.dart';
import 'package:flutter_application_pharmacy/main_screen.dart';
import 'package:flutter_application_pharmacy/models/user_model.dart';
import 'package:flutter_application_pharmacy/signup.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_pharmacy/doctor_profile.dart';
import 'package:flutter_application_pharmacy/pharmacy_registration.dart';
import 'package:flutter_application_pharmacy/pharmacy_profile.dart';

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

  Future<String?> _showRoleSelectionDialog() async {
    String? selectedRole;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Your Role'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                value: selectedRole,
                items:
                    ['Patient', 'Caretaker', 'Doctor', 'Pharmacist']
                        .map(
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => selectedRole = value),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedRole != null) {
                  Navigator.of(context).pop(selectedRole);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a role')),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return selectedRole;
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

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        String validEmail = user.email ?? "unknown.google@example.com";
        if (!validEmail.contains('@')) {
          validEmail = "unknown.google@example.com";
        }
        String validUserName = user.displayName ?? "Unknown";

        print("Google Sign-In - Email: $validEmail, Name: $validUserName");

        QuerySnapshot userQuery =
            await _firestore
                .collection('users')
                .where('email', isEqualTo: validEmail)
                .limit(1)
                .get();

        String docId;
        String userName = validUserName;
        String? userRole;
        String? phone;
        DateTime? createdAt;

        if (userQuery.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userQuery.docs.first;
          docId = userDoc.id;
          userName = userDoc['name'] ?? userName;
          userRole = userDoc['role'] ?? "Patient";
          phone = userDoc['phone'] ?? "";
          createdAt = (userDoc['createdAt'] as Timestamp?)?.toDate();
        } else {
          userRole = await _showRoleSelectionDialog();
          if (userRole == null) {
            setState(() => _isLoading = false);
            return;
          }

          DocumentReference newDoc = await _firestore.collection('users').add({
            'name': userName,
            'email': validEmail,
            'role': userRole,
            'phone': "",
            'createdAt': FieldValue.serverTimestamp(),
          });
          docId = newDoc.id;
          phone = "";
          createdAt = DateTime.now();

          // Only create additional collections for Patient and Caretaker
          if (userRole == 'Patient') {
            await _firestore.collection('patients').doc(docId).set({
              'docId': docId,
              'age': 0,
              'gender': '',
              'medicalHistory': [],
              'caretakerId': '',
              'prescriptions': [],
            });
          } else if (userRole == 'Caretaker') {
            await _firestore.collection('caretakers').doc(docId).set({
              'docId': docId,
              'patientIds': [],
              'emergencyContact': null,
            });
          }
          // Do not create placeholder for Doctor or Pharmacist
        }

        Provider.of<UserModel>(context, listen: false).setUser(
          docId: docId,
          name: userName,
          email: validEmail,
          role: userRole,
          phone: phone,
          createdAt: createdAt,
        );

        if (!mounted) return;
        print(
          "Google Sign-In successful: $userName, Role: $userRole, DocId: $docId",
        );
        _navigateBasedOnRole(userRole, userName, validEmail);
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In Error: $e"),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
          email: email,
          password: password,
        );
        User? user = userCredential.user;

        if (user != null) {
          String validEmail = email;
          String validUserName = "Unknown";

          print("Email/Password Sign-In - Email: $validEmail");

          QuerySnapshot userQuery =
              await _firestore
                  .collection('users')
                  .where('email', isEqualTo: validEmail)
                  .limit(1)
                  .get();

          String docId;
          String userName = validUserName;
          String? userRole;
          String? phone;
          DateTime? createdAt;

          if (userQuery.docs.isNotEmpty) {
            DocumentSnapshot userDoc = userQuery.docs.first;
            docId = userDoc.id;
            userName = userDoc['name'] ?? "No Name";
            userRole = userDoc['role'] ?? "Patient";
            phone = userDoc['phone'] ?? "";
            createdAt = (userDoc['createdAt'] as Timestamp?)?.toDate();
            print(
              "User data found in Firestore: $userName, Role: $userRole, DocId: $docId",
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No account found. Please sign up first."),
              ),
            );
            setState(() => _isLoading = false);
            return;
          }

          Provider.of<UserModel>(context, listen: false).setUser(
            docId: docId,
            name: userName,
            email: validEmail,
            role: userRole,
            phone: phone,
            createdAt: createdAt,
          );

          if (!mounted) return;
          print(
            "Sign-In successful: $userName, Role: $userRole, DocId: $docId",
          );
          _navigateBasedOnRole(userRole, userName, validEmail);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
        print("Unexpected Sign-In Error: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateBasedOnRole(
    String? role,
    String userName,
    String email,
  ) async {
    print("Navigating with Role: $role, Email: $email, UserName: $userName");

    switch (role) {
      case "Doctor":
        QuerySnapshot doctorQuery =
            await _firestore
                .collection('doctors')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        if (doctorQuery.docs.isNotEmpty) {
          DocumentSnapshot doctorDoc = doctorQuery.docs.first;
          String doctorId = doctorDoc.id;
          // Check if the doctor document has required fields
          Map<String, dynamic> data = doctorDoc.data() as Map<String, dynamic>;
          bool isComplete =
              data.containsKey('fullName') &&
              data['fullName'] != null &&
              data['fullName'].toString().isNotEmpty &&
              data.containsKey('specialty') &&
              data['specialty'] != null &&
              data['specialty'].toString().isNotEmpty &&
              data.containsKey('location') &&
              data['location'] != null &&
              data['location'].toString().isNotEmpty &&
              data.containsKey('age') &&
              data['age'] != null &&
              data.containsKey('mobile') &&
              data['mobile'] != null &&
              data['mobile'].toString().isNotEmpty;

          if (isComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorProfilePage(doctorId: doctorId),
              ),
            );
          } else {
            // Delete incomplete document to avoid conflicts
            await _firestore.collection('doctors').doc(doctorId).delete();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DoctorRegistrationPage(
                      userName: userName,
                      email: email,
                    ),
              ),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      DoctorRegistrationPage(userName: userName, email: email),
            ),
          );
        }
        break;
      case "Pharmacist":
        QuerySnapshot pharmacyQuery =
            await _firestore
                .collection('pharmacies')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        print("Pharmacy Query Result: ${pharmacyQuery.docs.length} docs found");
        if (pharmacyQuery.docs.isNotEmpty) {
          print("Pharmacy found with ID: ${pharmacyQuery.docs.first.id}");
          String pharmacyId = pharmacyQuery.docs.first.id;
          DocumentSnapshot pharmacyDoc = pharmacyQuery.docs.first;
          Map<String, dynamic> data =
              pharmacyDoc.data() as Map<String, dynamic>;
          bool isComplete =
              data.containsKey('name') &&
              data['name'] != null &&
              data['name'].toString().isNotEmpty &&
              data.containsKey('location') &&
              data['location'] != null &&
              data['location'].toString().isNotEmpty;

          if (isComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PharmacyProfilePage(pharmacyId: pharmacyId),
              ),
            );
          } else {
            await _firestore.collection('pharmacies').doc(pharmacyId).delete();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PharmacyRegistrationPage(
                      userName: userName,
                      email: email,
                    ),
              ),
            );
          }
        } else {
          print("No pharmacy found, navigating to registration");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PharmacyRegistrationPage(
                    userName: userName,
                    email: email,
                  ),
            ),
          );
        }
        break;
      case "Patient":
      case "Caretaker":
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(userName: userName),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 30,
                          color: Colors.black87,
                        ),
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
                      if (value!.isEmpty) return 'Email is required';
                      if (!value.contains('@') || !value.endsWith('.com'))
                        return 'Enter a valid email';
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
                      if (value!.isEmpty) return 'Password is required';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                    onChanged: (value) => setState(() => password = value),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed:
                          () => setState(
                            () => passwordVisible = !passwordVisible,
                          ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
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
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUp(),
                              ),
                            ),
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
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/7123025_logo_google_g_icon.png",
                            height: 24,
                          ),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
