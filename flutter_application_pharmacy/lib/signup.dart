// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_application_pharmacy/models/user_model.dart';
// import 'package:flutter_application_pharmacy/signin.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_application_pharmacy/main_screen.dart';
// import 'package:flutter_application_pharmacy/doctor_regestration.dart';
// import 'package:flutter_application_pharmacy/doctor_profile.dart';
// import 'package:flutter_application_pharmacy/pharmacy_registration.dart';
// import 'package:flutter_application_pharmacy/pharmacy_profile.dart';

// class SignUp extends StatefulWidget {
//   const SignUp({super.key});

//   @override
//   _SignUpState createState() => _SignUpState();
// }

// class _SignUpState extends State<SignUp> with SingleTickerProviderStateMixin {
//   bool passwordVisible = false;
//   bool isAgreed = false;
//   String email = "";
//   String password = "";
//   String name = "";
//   String emailError = "";
//   String passwordError = "";
//   String? selectedRole;
//   bool _isLoading = false;

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
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
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> registerUser() async {
//     setState(() => _isLoading = true);
//     try {
//       UserCredential userCredential = await _auth
//           .createUserWithEmailAndPassword(email: email, password: password);
//       User? user = userCredential.user;

//       if (user != null) {
//         DocumentReference newDoc = await _firestore.collection('users').add({
//           'name': name,
//           'email': email,
//           'role': selectedRole,
//           'phone': "",
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//         String docId = newDoc.id;

//         if (selectedRole == 'Patient') {
//           await _firestore.collection('patients').doc(docId).set({
//             'docId': docId,
//             'age': 0,
//             'gender': '',
//           }, SetOptions(merge: true));
//         } else if (selectedRole == 'Caretaker') {
//           await _firestore.collection('caretakers').doc(docId).set({
//             'docId': docId,
//           }, SetOptions(merge: true));
//         } else if (selectedRole == 'Doctor') {
//           await _firestore.collection('doctors').doc(docId).set({
//             'name': name,
//             'specialty': '',
//             'location': '',
//             'timeSlots': [],
//             'email': email,
//           }, SetOptions(merge: true));
//         } else if (selectedRole == 'Pharmacist') {
//           await _firestore.collection('pharmacies').doc(docId).set({
//             'name': '',
//             'location': '',
//             'medicines': [],
//             'email': email,
//           }, SetOptions(merge: true));
//         }

//         Provider.of<UserModel>(context, listen: false).setUser(
//           docId: docId,
//           name: name,
//           email: email,
//           role: selectedRole,
//           phone: "",
//           createdAt: DateTime.now(),
//         );

//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Signed up successfully!")),
//         );
//         _navigateBasedOnRole(selectedRole, name, email);
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = "Error registering user";
//       if (e.code == 'email-already-in-use')
//         errorMessage = "Email is already in use";
//       else if (e.code == 'weak-password')
//         errorMessage = "Password is too weak";
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(errorMessage)));
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   void handleSubmit() {
//     validateEmail();
//     validatePassword();

//     if (emailError.isEmpty &&
//         passwordError.isEmpty &&
//         name.isNotEmpty &&
//         isAgreed &&
//         selectedRole != null) {
//       registerUser();
//     } else {
//       String errorMessage = "";
//       if (!isAgreed)
//         errorMessage = "You must agree to the terms and conditions";
//       else if (selectedRole == null)
//         errorMessage = "Please select a role";
//       else if (name.isEmpty)
//         errorMessage = "Name is required";
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             errorMessage.isEmpty ? "Please fill all fields" : errorMessage,
//           ),
//         ),
//       );
//     }
//   }

//   void validateEmail() {
//     setState(() {
//       email = email.trim();
//       if (email.isEmpty)
//         emailError = "Email is required";
//       else if (!email.contains('@'))
//         emailError = "Email must contain '@'";
//       else if (!email.endsWith('.com'))
//         emailError = "Email must end with '.com'";
//       else
//         emailError = "";
//     });
//   }

//   void validatePassword() {
//     setState(() {
//       password = password.trim();
//       if (password.isEmpty)
//         passwordError = "Password is required";
//       else if (password.length < 6)
//         passwordError = "Password must be at least 6 characters";
//       else
//         passwordError = "";
//     });
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
//               horizontal: 24.0,
//               vertical: 16.0,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 60),
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: AppBar(
//                     backgroundColor: Colors.transparent,
//                     elevation: 0,
//                     leading: IconButton(
//                       icon: const Icon(
//                         Icons.arrow_back,
//                         size: 30,
//                         color: Colors.grey,
//                       ),
//                       onPressed: () => Navigator.of(context).pop(),
//                     ),
//                     title: const Text(
//                       "Sign Up",
//                       style: TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     centerTitle: true,
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 _buildTextField(
//                   prefixIcon: Icons.person,
//                   hintText: "Enter your name",
//                   onChanged: (text) => setState(() => name = text.trim()),
//                   onEditingComplete: () {},
//                 ),
//                 const SizedBox(height: 20),
//                 _buildTextField(
//                   prefixIcon: Icons.email,
//                   hintText: "Enter your email",
//                   keyboardType: TextInputType.emailAddress,
//                   onChanged: (text) => setState(() => email = text.trim()),
//                   onEditingComplete: validateEmail,
//                   errorText: emailError.isEmpty ? null : emailError,
//                 ),
//                 const SizedBox(height: 20),
//                 _buildTextField(
//                   prefixIcon: Icons.lock,
//                   hintText: "Enter your password",
//                   obscureText: !passwordVisible,
//                   onChanged: (text) => setState(() => password = text.trim()),
//                   onEditingComplete: validatePassword,
//                   errorText: passwordError.isEmpty ? null : passwordError,
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       passwordVisible ? Icons.visibility : Icons.visibility_off,
//                       color: Colors.grey,
//                     ),
//                     onPressed:
//                         () =>
//                             setState(() => passwordVisible = !passwordVisible),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: DropdownButtonFormField<String>(
//                     decoration: InputDecoration(
//                       prefixIcon: const Icon(Icons.group, color: Colors.grey),
//                       hintText: "Select your role",
//                       hintStyle: const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 16,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Colors.grey.withOpacity(0.3),
//                         ),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Colors.grey.withOpacity(0.3),
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(
//                           color: Color(0xFF407CE2),
//                           width: 2,
//                         ),
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       contentPadding: const EdgeInsets.symmetric(
//                         vertical: 16,
//                         horizontal: 16,
//                       ),
//                     ),
//                     value: selectedRole,
//                     items:
//                         ['Patient', 'Caretaker', 'Doctor', 'Pharmacist']
//                             .map(
//                               (role) => DropdownMenuItem(
//                                 value: role,
//                                 child: Text(role),
//                               ),
//                             )
//                             .toList(),
//                     onChanged: (value) => setState(() => selectedRole = value),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => setState(() => isAgreed = !isAgreed),
//                         child: Icon(
//                           isAgreed
//                               ? Icons.check_box
//                               : Icons.check_box_outline_blank,
//                           color:
//                               isAgreed ? const Color(0xFF407CE2) : Colors.grey,
//                         ),
//                       ),
//                       const SizedBox(width: 20),
//                       const Expanded(
//                         child: Text(
//                           "I agree to the Healthcare Terms of Service\nand Privacy Policy",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Color(0xFF407CE2),
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : handleSubmit,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF407CE2),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       elevation: 4,
//                     ),
//                     child:
//                         _isLoading
//                             ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                               ),
//                             )
//                             : const Text(
//                               'Sign Up',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Already have an account? ",
//                       style: TextStyle(color: Colors.grey, fontSize: 16),
//                     ),
//                     GestureDetector(
//                       onTap:
//                           () => Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (context) => const SignIn(),
//                             ),
//                           ),
//                       child: const Text(
//                         "Sign In",
//                         style: TextStyle(
//                           color: Color(0xFF407CE2),
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required IconData prefixIcon,
//     required String hintText,
//     TextInputType? keyboardType,
//     void Function(String)? onChanged,
//     bool obscureText = false,
//     Widget? suffixIcon,
//     String? errorText,
//     required void Function() onEditingComplete,
//   }) {
//     return TextField(
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       onChanged: onChanged,
//       onEditingComplete: onEditingComplete,
//       decoration: InputDecoration(
//         prefixIcon: Icon(prefixIcon, color: Colors.grey),
//         hintText: hintText,
//         hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
//         errorText: errorText,
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
//           borderSide: const BorderSide(color: Color(0xFF407CE2), width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.grey[100],
//         contentPadding: const EdgeInsets.symmetric(
//           vertical: 16,
//           horizontal: 16,
//         ),
//         suffixIcon: suffixIcon,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_pharmacy/models/user_model.dart';
import 'package:flutter_application_pharmacy/signin.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_pharmacy/main_screen.dart';
import 'package:flutter_application_pharmacy/doctor_regestration.dart';
import 'package:flutter_application_pharmacy/doctor_profile.dart';
import 'package:flutter_application_pharmacy/pharmacy_registration.dart';
import 'package:flutter_application_pharmacy/pharmacy_profile.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with SingleTickerProviderStateMixin {
  bool passwordVisible = false;
  bool isAgreed = false;
  String email = "";
  String password = "";
  String name = "";
  String emailError = "";
  String passwordError = "";
  String? selectedRole;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        DocumentReference newDoc = await _firestore.collection('users').add({
          'name': name,
          'email': email,
          'role': selectedRole,
          'phone': "",
          'createdAt': FieldValue.serverTimestamp(),
        });
        String docId = newDoc.id;

        if (selectedRole == 'Patient') {
          await _firestore.collection('patients').doc(docId).set({
            'docId': docId,
            'age': 0,
            'gender': '',
          }, SetOptions(merge: true));
        } else if (selectedRole == 'Caretaker') {
          await _firestore.collection('caretakers').doc(docId).set({
            'docId': docId,
          }, SetOptions(merge: true));
        } else if (selectedRole == 'Doctor') {
          await _firestore.collection('doctors').doc(docId).set({
            'name': name,
            'specialty': '',
            'location': '',
            'timeSlots': [],
            'email': email,
          }, SetOptions(merge: true));
        } else if (selectedRole == 'Pharmacist') {
          await _firestore.collection('pharmacies').doc(docId).set({
            'name': '',
            'location': '',
            'medicines': [],
            'email': email,
          }, SetOptions(merge: true));
        }

        // Sign out the user after registration
        await _auth.signOut();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signed up successfully! Please log in."),
          ),
        );
        // Redirect to SignIn page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignIn()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Error registering user";
      if (e.code == 'email-already-in-use')
        errorMessage = "Email is already in use";
      else if (e.code == 'weak-password')
        errorMessage = "Password is too weak";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void handleSubmit() {
    validateEmail();
    validatePassword();

    if (emailError.isEmpty &&
        passwordError.isEmpty &&
        name.isNotEmpty &&
        isAgreed &&
        selectedRole != null) {
      registerUser();
    } else {
      String errorMessage = "";
      if (!isAgreed)
        errorMessage = "You must agree to the terms and conditions";
      else if (selectedRole == null)
        errorMessage = "Please select a role";
      else if (name.isEmpty)
        errorMessage = "Name is required";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage.isEmpty ? "Please fill all fields" : errorMessage,
          ),
        ),
      );
    }
  }

  void validateEmail() {
    setState(() {
      email = email.trim();
      if (email.isEmpty)
        emailError = "Email is required";
      else if (!email.contains('@'))
        emailError = "Email must contain '@'";
      else if (!email.endsWith('.com'))
        emailError = "Email must end with '.com'";
      else
        emailError = "";
    });
  }

  void validatePassword() {
    setState(() {
      password = password.trim();
      if (password.isEmpty)
        passwordError = "Password is required";
      else if (password.length < 6)
        passwordError = "Password must be at least 6 characters";
      else
        passwordError = "";
    });
  }

  // Remove _navigateBasedOnRole since we're redirecting to SignIn
  // void _navigateBasedOnRole(String? role, String userName, String email) async {
  //   // Previous logic removed
  // }

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
              horizontal: 24.0,
              vertical: 16.0,
            ),
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
                        color: Colors.grey,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    title: const Text(
                      "Sign Up",
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
                  prefixIcon: Icons.person,
                  hintText: "Enter your name",
                  onChanged: (text) => setState(() => name = text.trim()),
                  onEditingComplete: () {},
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  prefixIcon: Icons.email,
                  hintText: "Enter your email",
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (text) => setState(() => email = text.trim()),
                  onEditingComplete: validateEmail,
                  errorText: emailError.isEmpty ? null : emailError,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  prefixIcon: Icons.lock,
                  hintText: "Enter your password",
                  obscureText: !passwordVisible,
                  onChanged: (text) => setState(() => password = text.trim()),
                  onEditingComplete: validatePassword,
                  errorText: passwordError.isEmpty ? null : passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed:
                        () =>
                            setState(() => passwordVisible = !passwordVisible),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.group, color: Colors.grey),
                      hintText: "Select your role",
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF407CE2),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    value: selectedRole,
                    items:
                        ['Patient', 'Caretaker', 'Doctor', 'Pharmacist']
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => selectedRole = value),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => isAgreed = !isAgreed),
                        child: Icon(
                          isAgreed
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color:
                              isAgreed ? const Color(0xFF407CE2) : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Text(
                          "I agree to the Healthcare Terms of Service\nand Privacy Policy",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF407CE2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF407CE2),
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
                              'Sign Up',
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
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    GestureDetector(
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignIn(),
                            ),
                          ),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Color(0xFF407CE2),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
    required String hintText,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    required void Function() onEditingComplete,
  }) {
    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, color: Colors.grey),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        errorText: errorText,
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
          borderSide: const BorderSide(color: Color(0xFF407CE2), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
