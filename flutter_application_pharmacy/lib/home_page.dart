// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_pharmacy/models/user_model';
// import 'package:flutter_application_pharmacy/screens/articles.dart';
// import 'package:flutter_application_pharmacy/screens/maps.dart';
// import 'package:flutter_application_pharmacy/screens/top_doctors.dart';
// import 'package:flutter_application_pharmacy/screens/top_pharmacies.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter/services.dart';

// const defaultPadding = EdgeInsets.symmetric(horizontal: 20);

// class HomePage extends StatefulWidget {
//   final String userName;

//   const HomePage({super.key, required this.userName});

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage>
//     with SingleTickerProviderStateMixin {
//   String userName = "";
//   String _searchQuery = '';
//   List<SearchItem> _filteredItems = [];
//   List<Map<String, dynamic>> _doctors = [];
//   List<Map<String, dynamic>> _pharmacies = [];
//   bool _isLoading = true;
//   String? _profileImageUrl;
//   String? _docId;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     print("HomePage initState started");

//     userName = widget.userName;
//     _isLoading = true;

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _animationController.forward();

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _loadInitialData();
//     });
//   }

//   @override
//   void dispose() {
//     print("HomePage dispose called");
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadInitialData() async {
//     print("Loading initial data...");
//     try {
//       await Future.wait([
//         _fetchUserData(),
//         _fetchDoctors(),
//         _fetchPharmacies(),
//         _initializeFilteredItemsAsync(),
//       ]);
//     } catch (e) {
//       print("Error in _loadInitialData: $e");
//       if (mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
//       }
//     }
//   }

//   Future<void> _fetchUserData() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       print("No authenticated user found");
//       if (mounted) setState(() => _isLoading = false);
//       return;
//     }

//     print("Fetching user data for email: ${user.email}");
//     try {
//       QuerySnapshot userQuery =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .where('email', isEqualTo: user.email)
//               .limit(1)
//               .get();

//       if (userQuery.docs.isNotEmpty && mounted) {
//         DocumentSnapshot snapshot = userQuery.docs.first;
//         _docId = snapshot.id;
//         final userModel = Provider.of<UserModel>(context, listen: false);
//         setState(() {
//           userName = snapshot.get('name') ?? widget.userName;
//           _profileImageUrl = snapshot.get('profileImageUrl') ?? '';
//           _isLoading = false;
//         });
//         userModel.updateName(userName);
//         userModel.updateProfileImage(_profileImageUrl ?? '');
//         print(
//           "User data fetched: $userName, ProfileImage: $_profileImageUrl, Role: ${snapshot.get('role')}, DocId: $_docId",
//         );
//       } else if (mounted) {
//         setState(() => _isLoading = false);
//         print("No user document found for email: ${user.email}");
//       }
//     } catch (e) {
//       print("Firestore fetch error: $e");
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _fetchDoctors() async {
//     print("Fetching doctors...");
//     try {
//       QuerySnapshot snapshot =
//           await FirebaseFirestore.instance.collection('doctors').get();
//       setState(() {
//         _doctors =
//             snapshot.docs
//                 .map((doc) => doc.data() as Map<String, dynamic>)
//                 .toList();
//       });
//       print("Fetched ${_doctors.length} doctors");
//     } catch (e) {
//       print("Error fetching doctors: $e");
//     }
//   }

//   Future<void> _fetchPharmacies() async {
//     print("Fetching pharmacies...");
//     try {
//       QuerySnapshot snapshot =
//           await FirebaseFirestore.instance.collection('pharmacies').get();
//       setState(() {
//         _pharmacies =
//             snapshot.docs
//                 .map((doc) => doc.data() as Map<String, dynamic>)
//                 .toList();
//       });
//       print("Fetched ${_pharmacies.length} pharmacies");
//     } catch (e) {
//       print("Error fetching pharmacies: $e");
//     }
//   }

//   Future<void> _initializeFilteredItemsAsync() async {
//     print("Initializing filtered items...");
//     _filteredItems = [
//       ...articles.map((article) => SearchItem(type: 'article', data: article)),
//       ..._doctors.map((doctor) => SearchItem(type: 'doctor', data: doctor)),
//       ..._pharmacies.map(
//         (pharmacy) => SearchItem(type: 'pharmacy', data: pharmacy),
//       ),
//     ];
//     print("Filtered items initialized: ${_filteredItems.length} items");
//     if (mounted) setState(() => _isLoading = false);
//   }

//   void _filterItems(String query) {
//     setState(() {
//       _searchQuery = query;
//       if (query.isEmpty) {
//         _initializeFilteredItemsAsync();
//       } else {
//         _filteredItems = [
//           ...articles
//               .where(
//                 (article) =>
//                     article.title.toLowerCase().contains(query.toLowerCase()),
//               )
//               .map((article) => SearchItem(type: 'article', data: article)),
//           ..._doctors
//               .where(
//                 (doctor) =>
//                     doctor['name'].toString().toLowerCase().contains(
//                       query.toLowerCase(),
//                     ) ||
//                     doctor['specialty'].toString().toLowerCase().contains(
//                       query.toLowerCase(),
//                     ),
//               )
//               .map((doctor) => SearchItem(type: 'doctor', data: doctor)),
//           ..._pharmacies
//               .where(
//                 (pharmacy) =>
//                     pharmacy['name'].toString().toLowerCase().contains(
//                       query.toLowerCase(),
//                     ) ||
//                     pharmacy['location'].toString().toLowerCase().contains(
//                       query.toLowerCase(),
//                     ),
//               )
//               .map((pharmacy) => SearchItem(type: 'pharmacy', data: pharmacy)),
//         ];
//       }
//     });
//   }

//   Future<bool> _onWillPop() async {
//     bool? shouldExit = await showDialog<bool>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Exit App'),
//             content: const Text('Do you want to exit the app?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('No'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: const Text('Yes'),
//               ),
//             ],
//           ),
//     );

//     if (shouldExit == true) {
//       SystemNavigator.pop();
//       return true;
//     }
//     return false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     print("Building HomePage UI, _isLoading: $_isLoading");
//     final user = FirebaseAuth.instance.currentUser;

//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body:
//             _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : user == null
//                 ? const Center(child: Text('Please sign in'))
//                 : RefreshIndicator(
//                   onRefresh: () async {
//                     setState(() => _isLoading = true);
//                     await _initializeFilteredItemsAsync();
//                     await _fetchUserData();
//                     await _fetchDoctors();
//                     await _fetchPharmacies();
//                     setState(() => _isLoading = false);
//                   },
//                   child: SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           height: 300, // Height increased to 300
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade50,
//                             borderRadius: const BorderRadius.only(
//                               bottomLeft: Radius.circular(30),
//                               bottomRight: Radius.circular(30),
//                             ),
//                           ),
//                           child: Padding(
//                             padding: defaultPadding.copyWith(
//                               top: 40.0,
//                               bottom: 20.0,
//                             ),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 FadeTransition(
//                                   opacity: _fadeAnimation,
//                                   child: Padding(
//                                     padding: const EdgeInsets.only(right: 20.0),
//                                     child: CircleAvatar(
//                                       radius: 40,
//                                       backgroundImage:
//                                           _profileImageUrl != null &&
//                                                   _profileImageUrl!.isNotEmpty
//                                               ? NetworkImage(_profileImageUrl!)
//                                               : const AssetImage(
//                                                     'assets/user.jpg',
//                                                   )
//                                                   as ImageProvider,
//                                       backgroundColor: Colors.grey[200],
//                                       onBackgroundImageError: (
//                                         exception,
//                                         stackTrace,
//                                       ) {
//                                         print(
//                                           "Error loading profile image: $exception",
//                                         );
//                                       },
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           border: Border.all(
//                                             color: Colors.blueAccent
//                                                 .withOpacity(0.5),
//                                             width: 2,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 Expanded(
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       FadeTransition(
//                                         opacity: _fadeAnimation,
//                                         child: const Text(
//                                           'Welcome!',
//                                           style: TextStyle(
//                                             fontSize: 18,
//                                             fontWeight: FontWeight.w500,
//                                             color: Colors.black87,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       FadeTransition(
//                                         opacity: _fadeAnimation,
//                                         child: Text(
//                                           userName,
//                                           style: const TextStyle(
//                                             fontSize: 24,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.black,
//                                           ),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       FadeTransition(
//                                         opacity: _fadeAnimation,
//                                         child: const Text(
//                                           'How is it going today?',
//                                           style: TextStyle(
//                                             fontSize: 16,
//                                             color: Colors.black54,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: defaultPadding.copyWith(top: 20.0),
//                           child: TextField(
//                             onChanged: _filterItems,
//                             decoration: InputDecoration(
//                               hintText:
//                                   'Search articles, doctors, pharmacies...',
//                               prefixIcon: const Icon(Icons.search),
//                               filled: true,
//                               fillColor: Colors.grey.shade200,
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(15),
//                                 borderSide: BorderSide.none,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: defaultPadding.copyWith(top: 20.0),
//                           child:
//                               _searchQuery.isEmpty
//                                   ? Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'Categories',
//                                         style: TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 15),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           GestureDetector(
//                                             onTap:
//                                                 () => Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder:
//                                                         (context) =>
//                                                             const TopDoctorsScreen(), // Updated to TopDoctorsScreen
//                                                   ),
//                                                 ),
//                                             child: const CategoryCard(
//                                               icon: Icons.person,
//                                               label: 'Top Doctors',
//                                             ),
//                                           ),
//                                           GestureDetector(
//                                             onTap:
//                                                 () => Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder:
//                                                         (context) =>
//                                                             const TopPharmaciesScreen(),
//                                                   ),
//                                                 ),
//                                             child: const CategoryCard(
//                                               icon: Icons.local_pharmacy,
//                                               label: 'Pharmacies',
//                                             ),
//                                           ),
//                                           GestureDetector(
//                                             onTap:
//                                                 () => Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder:
//                                                         (context) =>
//                                                             const AmbulanceBookingScreen(),
//                                                   ),
//                                                 ),
//                                             child: const CategoryCard(
//                                               icon: Icons.map,
//                                               label: 'Maps',
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       Padding(
//                                         padding: const EdgeInsets.only(
//                                           top: 30.0,
//                                         ),
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment
//                                                       .spaceBetween,
//                                               children: [
//                                                 const Text(
//                                                   'Health Articles',
//                                                   style: TextStyle(
//                                                     fontSize: 18,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                                 GestureDetector(
//                                                   onTap:
//                                                       () => Navigator.push(
//                                                         context,
//                                                         MaterialPageRoute(
//                                                           builder:
//                                                               (context) =>
//                                                                   const AllArticlesPage(),
//                                                         ),
//                                                       ),
//                                                   child: const Text(
//                                                     'See all',
//                                                     style: TextStyle(
//                                                       fontSize: 14,
//                                                       color: Colors.blue,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             const SizedBox(height: 15),
//                                             ...articles
//                                                 .take(3)
//                                                 .map(
//                                                   (article) => GestureDetector(
//                                                     onTap:
//                                                         () => Navigator.push(
//                                                           context,
//                                                           MaterialPageRoute(
//                                                             builder:
//                                                                 (
//                                                                   context,
//                                                                 ) => ArticleDetailPage(
//                                                                   article:
//                                                                       article,
//                                                                 ),
//                                                           ),
//                                                         ),
//                                                     child: HealthArticleCard(
//                                                       title: article.title,
//                                                       date: article.date,
//                                                       readTime:
//                                                           article.readTime,
//                                                       imagePath:
//                                                           article.imagePath,
//                                                     ),
//                                                   ),
//                                                 ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   )
//                                   : _filteredItems.isEmpty
//                                   ? const Center(
//                                     child: Padding(
//                                       padding: EdgeInsets.all(20.0),
//                                       child: Text(
//                                         'No Results Found',
//                                         style: TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   )
//                                   : ListView.builder(
//                                     shrinkWrap: true,
//                                     physics:
//                                         const NeverScrollableScrollPhysics(),
//                                     itemCount: _filteredItems.length,
//                                     itemBuilder: (context, index) {
//                                       final item = _filteredItems[index];
//                                       switch (item.type) {
//                                         case 'article':
//                                           final article = item.data as Article;
//                                           return GestureDetector(
//                                             onTap:
//                                                 () => Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder:
//                                                         (context) =>
//                                                             ArticleDetailPage(
//                                                               article: article,
//                                                             ),
//                                                   ),
//                                                 ),
//                                             child: HealthArticleCard(
//                                               title: article.title,
//                                               date: article.date,
//                                               readTime: article.readTime,
//                                               imagePath: article.imagePath,
//                                             ),
//                                           );
//                                         case 'doctor':
//                                           final doctor =
//                                               item.data as Map<String, dynamic>;
//                                           return ListTile(
//                                             leading: const Icon(
//                                               Icons.person,
//                                               color: Colors.blue,
//                                             ),
//                                             title: Text(
//                                               doctor['name'] ??
//                                                   'Unknown Doctor',
//                                             ),
//                                             subtitle: Text(
//                                               doctor['specialty'] ??
//                                                   'No Specialty',
//                                             ),
//                                             trailing: Text(
//                                               doctor['location'] ??
//                                                   'No Location',
//                                             ),
//                                             onTap:
//                                                 () => Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder:
//                                                         (context) =>
//                                                             BookAppointmentScreen(
//                                                               doctor: doctor,
//                                                             ),
//                                                   ),
//                                                 ),
//                                           );
//                                         case 'pharmacy':
//                                           final pharmacy =
//                                               item.data as Map<String, dynamic>;
//                                           return ListTile(
//                                             leading: const Icon(
//                                               Icons.local_pharmacy,
//                                               color: Colors.green,
//                                             ),
//                                             title: Text(
//                                               pharmacy['name'] ??
//                                                   'Unknown Pharmacy',
//                                             ),
//                                             subtitle: Text(
//                                               pharmacy['location'] ??
//                                                   'No Location',
//                                             ),
//                                             onTap:
//                                                 () => Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder:
//                                                         (context) =>
//                                                             PharmacyDetailScreen(
//                                                               pharmacy:
//                                                                   pharmacy,
//                                                               pharmacyId: null,
//                                                               pharmacyName:
//                                                                   null,
//                                                             ),
//                                                   ),
//                                                 ),
//                                           );
//                                         default:
//                                           return const SizedBox.shrink();
//                                       }
//                                     },
//                                   ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//       ),
//     );
//   }
// }

// class SearchItem {
//   final String type;
//   final dynamic data;

//   SearchItem({required this.type, required this.data});
// }

// class CategoryCard extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const CategoryCard({super.key, required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         CircleAvatar(
//           radius: 30,
//           backgroundColor: Colors.blue.shade50,
//           child: Icon(icon, size: 35, color: Colors.blue),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class PharmacyListScreen extends StatelessWidget {
//   const PharmacyListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Pharmacies')),
//       body: const Center(child: Text('Pharmacy List')),
//     );
//   }
// }

// class BookAppointmentScreen extends StatelessWidget {
//   final Map<String, dynamic> doctor;

//   const BookAppointmentScreen({super.key, required this.doctor});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(doctor['name'] ?? 'Doctor')),
//       body: Center(child: Text('Book Appointment with ${doctor['name']}')),
//     );
//   }
// }

// class PharmacyDetailScreen extends StatelessWidget {
//   final Map<String, dynamic> pharmacy;

//   const PharmacyDetailScreen({
//     super.key,
//     required this.pharmacy,
//     required pharmacyId,
//     required pharmacyName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(pharmacy['name'] ?? 'Pharmacy')),
//       body: Center(child: Text('Pharmacy Details: ${pharmacy['location']}')),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_pharmacy/models/user_model.dart';
import 'package:flutter_application_pharmacy/screens/articles.dart';
import 'package:flutter_application_pharmacy/screens/maps.dart';
import 'package:flutter_application_pharmacy/screens/top_doctors.dart';
import 'package:flutter_application_pharmacy/screens/top_pharmacies.dart';
import 'package:flutter_application_pharmacy/screens/pharmacy_details.dart'; // Added import for PharmacyDetailScreen
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

const defaultPadding = EdgeInsets.symmetric(horizontal: 20);

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String userName = "";
  String _searchQuery = '';
  List<SearchItem> _filteredItems = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;
  String? _profileImageUrl;
  String? _docId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print("HomePage initState started");

    userName = widget.userName;
    _isLoading = true;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialData();
    });
  }

  @override
  void dispose() {
    print("HomePage dispose called");
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    print("Loading initial data...");
    try {
      await Future.wait([
        _fetchUserData(),
        _fetchDoctors(),
        _fetchPharmacies(),
        _initializeFilteredItemsAsync(),
      ]);
    } catch (e) {
      print("Error in _loadInitialData: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No authenticated user found");
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    print("Fetching user data for email: ${user.email}");
    try {
      QuerySnapshot userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();

      if (userQuery.docs.isNotEmpty && mounted) {
        DocumentSnapshot snapshot = userQuery.docs.first;
        _docId = snapshot.id;
        final userModel = Provider.of<UserModel>(context, listen: false);
        setState(() {
          userName = snapshot.get('name') ?? widget.userName;
          _profileImageUrl = snapshot.get('profileImageUrl') ?? '';
          _isLoading = false;
        });
        userModel.updateName(userName);
        userModel.updateProfileImage(_profileImageUrl ?? '');
        print(
          "User data fetched: $userName, ProfileImage: $_profileImageUrl, Role: ${snapshot.get('role')}, DocId: $_docId",
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        print("No user document found for email: ${user.email}");
      }
    } catch (e) {
      print("Firestore fetch error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDoctors() async {
    print("Fetching doctors...");
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('doctors').get();
      setState(() {
        _doctors =
            snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
      });
      print("Fetched ${_doctors.length} doctors");
    } catch (e) {
      print("Error fetching doctors: $e");
    }
  }

  Future<void> _fetchPharmacies() async {
    print("Fetching pharmacies...");
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('pharmacies').get();
      setState(() {
        _pharmacies =
            snapshot.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              data['pharmacyId'] = doc.id; // Add pharmacyId to the data
              return data;
            }).toList();
      });
      print("Fetched ${_pharmacies.length} pharmacies");
    } catch (e) {
      print("Error fetching pharmacies: $e");
    }
  }

  Future<void> _initializeFilteredItemsAsync() async {
    print("Initializing filtered items...");
    _filteredItems = [
      ...articles.map((article) => SearchItem(type: 'article', data: article)),
      ..._doctors.map((doctor) => SearchItem(type: 'doctor', data: doctor)),
      ..._pharmacies.map(
        (pharmacy) => SearchItem(type: 'pharmacy', data: pharmacy),
      ),
    ];
    print("Filtered items initialized: ${_filteredItems.length} items");
    if (mounted) setState(() => _isLoading = false);
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _initializeFilteredItemsAsync();
      } else {
        _filteredItems = [
          ...articles
              .where(
                (article) =>
                    article.title.toLowerCase().contains(query.toLowerCase()),
              )
              .map((article) => SearchItem(type: 'article', data: article)),
          ..._doctors
              .where(
                (doctor) =>
                    doctor['name'].toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    doctor['specialty'].toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .map((doctor) => SearchItem(type: 'doctor', data: doctor)),
          ..._pharmacies
              .where(
                (pharmacy) =>
                    pharmacy['name'].toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    pharmacy['location'].toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .map((pharmacy) => SearchItem(type: 'pharmacy', data: pharmacy)),
        ];
      }
    });
  }

  Future<bool> _onWillPop() async {
    bool? shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    print("Building HomePage UI, _isLoading: $_isLoading");
    final user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : user == null
                ? const Center(child: Text('Please sign in'))
                : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _isLoading = true);
                    await _initializeFilteredItemsAsync();
                    await _fetchUserData();
                    await _fetchDoctors();
                    await _fetchPharmacies();
                    setState(() => _isLoading = false);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 300, // Height increased to 300
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Padding(
                            padding: defaultPadding.copyWith(
                              top: 40.0,
                              bottom: 20.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 20.0),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundImage:
                                          _profileImageUrl != null &&
                                                  _profileImageUrl!.isNotEmpty
                                              ? NetworkImage(_profileImageUrl!)
                                              : const AssetImage(
                                                    'assets/user.jpg',
                                                  )
                                                  as ImageProvider,
                                      backgroundColor: Colors.grey[200],
                                      onBackgroundImageError: (
                                        exception,
                                        stackTrace,
                                      ) {
                                        print(
                                          "Error loading profile image: $exception",
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.blueAccent
                                                .withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: const Text(
                                          'Welcome!',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: Text(
                                          userName,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: const Text(
                                          'How is it going today?',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: defaultPadding.copyWith(top: 20.0),
                          child: TextField(
                            onChanged: _filterItems,
                            decoration: InputDecoration(
                              hintText:
                                  'Search articles, doctors, pharmacies...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: defaultPadding.copyWith(top: 20.0),
                          child:
                              _searchQuery.isEmpty
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Categories',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const TopDoctorsScreen(), // Updated to TopDoctorsScreen
                                                  ),
                                                ),
                                            child: const CategoryCard(
                                              icon: Icons.person,
                                              label: 'Top Doctors',
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const TopPharmaciesScreen(),
                                                  ),
                                                ),
                                            child: const CategoryCard(
                                              icon: Icons.local_pharmacy,
                                              label: 'Pharmacies',
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const AmbulanceBookingScreen(),
                                                  ),
                                                ),
                                            child: const CategoryCard(
                                              icon: Icons.map,
                                              label: 'Maps',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 30.0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Health Articles',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap:
                                                      () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  const AllArticlesPage(),
                                                        ),
                                                      ),
                                                  child: const Text(
                                                    'See all',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),
                                            ...articles
                                                .take(3)
                                                .map(
                                                  (article) => GestureDetector(
                                                    onTap:
                                                        () => Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => ArticleDetailPage(
                                                                  article:
                                                                      article,
                                                                ),
                                                          ),
                                                        ),
                                                    child: HealthArticleCard(
                                                      title: article.title,
                                                      date: article.date,
                                                      readTime:
                                                          article.readTime,
                                                      imagePath:
                                                          article.imagePath,
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                  : _filteredItems.isEmpty
                                  ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text(
                                        'No Results Found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      switch (item.type) {
                                        case 'article':
                                          final article = item.data as Article;
                                          return GestureDetector(
                                            onTap:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            ArticleDetailPage(
                                                              article: article,
                                                            ),
                                                  ),
                                                ),
                                            child: HealthArticleCard(
                                              title: article.title,
                                              date: article.date,
                                              readTime: article.readTime,
                                              imagePath: article.imagePath,
                                            ),
                                          );
                                        case 'doctor':
                                          final doctor =
                                              item.data as Map<String, dynamic>;
                                          return ListTile(
                                            leading: const Icon(
                                              Icons.person,
                                              color: Colors.blue,
                                            ),
                                            title: Text(
                                              doctor['name'] ??
                                                  'Unknown Doctor',
                                            ),
                                            subtitle: Text(
                                              doctor['specialty'] ??
                                                  'No Specialty',
                                            ),
                                            trailing: Text(
                                              doctor['location'] ??
                                                  'No Location',
                                            ),
                                            onTap:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            BookAppointmentScreen(
                                                              doctor: doctor,
                                                            ),
                                                  ),
                                                ),
                                          );
                                        case 'pharmacy':
                                          final pharmacy =
                                              item.data as Map<String, dynamic>;
                                          return ListTile(
                                            leading: const Icon(
                                              Icons.local_pharmacy,
                                              color: Colors.green,
                                            ),
                                            title: Text(
                                              pharmacy['name'] ??
                                                  'Unknown Pharmacy',
                                            ),
                                            subtitle: Text(
                                              pharmacy['location'] ??
                                                  'No Location',
                                            ),
                                            onTap: () {
                                              String? pharmacyId =
                                                  pharmacy['pharmacyId'];
                                              String pharmacyName =
                                                  pharmacy['name'] ??
                                                  'Unknown Pharmacy';
                                              if (pharmacyId == null) {
                                                print(
                                                  'Warning: pharmacyId is null for pharmacy: $pharmacyName',
                                                );
                                              } else {
                                                print(
                                                  'Navigating to PharmacyDetailScreen with pharmacyId: $pharmacyId, pharmacyName: $pharmacyName',
                                                );
                                              }
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          PharmacyDetailScreen(
                                                            pharmacyId:
                                                                pharmacyId ??
                                                                '',
                                                            pharmacyName:
                                                                pharmacyName,
                                                            pharmacy: {},
                                                          ),
                                                ),
                                              );
                                            },
                                          );
                                        default:
                                          return const SizedBox.shrink();
                                      }
                                    },
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

class SearchItem {
  final String type;
  final dynamic data;

  SearchItem({required this.type, required this.data});
}

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const CategoryCard({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, size: 35, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class BookAppointmentScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doctor['name'] ?? 'Doctor')),
      body: Center(child: Text('Book Appointment with ${doctor['name']}')),
    );
  }
}
