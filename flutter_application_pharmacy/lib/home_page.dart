import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_pharmacy/models/user_model';
import 'package:flutter_application_pharmacy/profile_page.dart';
import 'package:flutter_application_pharmacy/reports.dart';
import 'package:flutter_application_pharmacy/screens/articles.dart';
import 'package:flutter_application_pharmacy/screens/maps.dart';
import 'package:flutter_application_pharmacy/widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

const defaultPadding = EdgeInsets.symmetric(horizontal: 20);

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String userName = "";
  String _searchQuery = '';
  List<SearchItem> _filteredItems = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;
  String? _profileImageUrl;
  int _currentIndex = 0; // Home is index 0

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
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
      String docId = _generateDocId(user.email ?? "unknown");
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();

      if (snapshot.exists && mounted) {
        final userModel = Provider.of<UserModel>(context, listen: false);
        setState(() {
          userName = snapshot.get('name') ?? widget.userName;
          _profileImageUrl = snapshot.get('profileImageUrl') ?? '';
          _isLoading = false;
        });
        userModel.updateName(userName);
        userModel.updateProfileImage(_profileImageUrl ?? '');
        print("User data fetched: $userName, ProfileImage: $_profileImageUrl, Role: ${snapshot.get('role')}");
      } else if (mounted) {
        setState(() => _isLoading = false);
        print("No user document found for $docId");
      }
    } catch (e) {
      print("Firestore fetch error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDoctors() async {
    print("Fetching doctors...");
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('doctors').get();
      setState(() {
        _doctors = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
      print("Fetched ${_doctors.length} doctors");
    } catch (e) {
      print("Error fetching doctors: $e");
    }
  }

  Future<void> _fetchPharmacies() async {
    print("Fetching pharmacies...");
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('pharmacies').get();
      setState(() {
        _pharmacies = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
      print("Fetched ${_pharmacies.length} pharmacies");
    } catch (e) {
      print("Error fetching pharmacies: $e");
    }
  }

  String _generateDocId(String email) {
    return email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  Future<void> _initializeFilteredItemsAsync() async {
    print("Initializing filtered items...");
    _filteredItems = [
      ...articles.map((article) => SearchItem(type: 'article', data: article)),
      ..._doctors.map((doctor) => SearchItem(type: 'doctor', data: doctor)),
      ..._pharmacies.map((pharmacy) => SearchItem(type: 'pharmacy', data: pharmacy)),
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
              .where((article) => article.title.toLowerCase().contains(query.toLowerCase()))
              .map((article) => SearchItem(type: 'article', data: article)),
          ..._doctors
              .where((doctor) =>
                  doctor['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                  doctor['specialty'].toString().toLowerCase().contains(query.toLowerCase()))
              .map((doctor) => SearchItem(type: 'doctor', data: doctor)),
          ..._pharmacies
              .where((pharmacy) =>
                  pharmacy['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                  pharmacy['location'].toString().toLowerCase().contains(query.toLowerCase()))
              .map((pharmacy) => SearchItem(type: 'pharmacy', data: pharmacy)),
        ];
      }
    });
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return; // Prevent re-navigating to same page
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        // Already on HomePage
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ReportsPage(userName: userName)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RemindersScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage(userName: userName)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building HomePage UI, _isLoading: $_isLoading");
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
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
                            height: 260,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                            ),
                            child: Padding(
                              padding: defaultPadding.copyWith(top: 40.0, bottom: 20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 20.0),
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                            ? NetworkImage(_profileImageUrl!)
                                            : const AssetImage('assets/user.jpg') as ImageProvider,
                                        backgroundColor: Colors.grey[200],
                                        onBackgroundImageError: (exception, stackTrace) {
                                          print("Error loading profile image: $exception");
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.blueAccent.withOpacity(0.5),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                hintText: 'Search articles, doctors, pharmacies...',
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
                            child: _searchQuery.isEmpty
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Categories',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const DoctorListScreen()),
                                            ),
                                            child: const CategoryCard(icon: Icons.person, label: 'Top Doctors'),
                                          ),
                                          GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const PharmacyListScreen()),
                                            ),
                                            child: const CategoryCard(icon: Icons.local_pharmacy, label: 'Pharmacies'),
                                          ),
                                          GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const AmbulanceBookingScreen()),
                                            ),
                                            child: const CategoryCard(icon: Icons.map, label: 'Maps'),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 30.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Health Articles',
                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                                GestureDetector(
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => const AllArticlesPage()),
                                                  ),
                                                  child: const Text(
                                                    'See all',
                                                    style: TextStyle(fontSize: 14, color: Colors.blue),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),
                                            ...articles.take(3).map(
                                                  (article) => GestureDetector(
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ArticleDetailPage(article: article),
                                                      ),
                                                    ),
                                                    child: HealthArticleCard(
                                                      title: article.title,
                                                      date: article.date,
                                                      readTime: article.readTime,
                                                      imagePath: article.imagePath,
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
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _filteredItems.length,
                                        itemBuilder: (context, index) {
                                          final item = _filteredItems[index];
                                          switch (item.type) {
                                            case 'article':
                                              final article = item.data as Article;
                                              return GestureDetector(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ArticleDetailPage(article: article),
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
                                              final doctor = item.data as Map<String, dynamic>;
                                              return ListTile(
                                                leading: const Icon(Icons.person, color: Colors.blue),
                                                title: Text(doctor['name'] ?? 'Unknown Doctor'),
                                                subtitle: Text(doctor['specialty'] ?? 'No Specialty'),
                                                trailing: Text(doctor['location'] ?? 'No Location'),
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => BookAppointmentScreen(doctor: doctor),
                                                  ),
                                                ),
                                              );
                                            case 'pharmacy':
                                              final pharmacy = item.data as Map<String, dynamic>;
                                              return ListTile(
                                                leading: const Icon(Icons.local_pharmacy, color: Colors.green),
                                                title: Text(pharmacy['name'] ?? 'Unknown Pharmacy'),
                                                subtitle: Text(pharmacy['location'] ?? 'No Location'),
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => PharmacyDetailScreen(pharmacy: pharmacy),
                                                  ),
                                                ),
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
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTap,
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
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.blue),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// Placeholder screens
class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Doctors')), body: const Center(child: Text('Doctor List')));
  }
}

class PharmacyListScreen extends StatelessWidget {
  const PharmacyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Pharmacies')), body: const Center(child: Text('Pharmacy List')));
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

class PharmacyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pharmacy;

  const PharmacyDetailScreen({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pharmacy['name'] ?? 'Pharmacy')),
      body: Center(child: Text('Pharmacy Details: ${pharmacy['location']}')),
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