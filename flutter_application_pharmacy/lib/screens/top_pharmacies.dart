import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_pharmacy/home_page.dart';
import 'package:flutter_application_pharmacy/screens/pharmacy_details.dart';

class TopPharmaciesScreen extends StatefulWidget {
  const TopPharmaciesScreen({super.key});

  @override
  _TopPharmaciesScreenState createState() => _TopPharmaciesScreenState();
}

class _TopPharmaciesScreenState extends State<TopPharmaciesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPharmacies();
  }

  Future<void> _fetchPharmacies() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('pharmacies').get();
      setState(() {
        _pharmacies =
            snapshot.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String pharmacyId = doc.id;
              data['pharmacyId'] = pharmacyId;
              return data;
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching pharmacies: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Pharmacies'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pharmacies.isEmpty
              ? const Center(child: Text('No pharmacies found'))
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _pharmacies.length,
                itemBuilder: (context, index) {
                  final pharmacy = _pharmacies[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          pharmacy['pharmacyName'][0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      title: Text(
                        pharmacy['pharmacyName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Owner: ${pharmacy['ownerName']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pharmacy['location'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        String pharmacyId = pharmacy['pharmacyId'];
                        String pharmacyName = pharmacy['pharmacyName'];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PharmacyDetailScreen(
                                  pharmacyId: pharmacyId,
                                  pharmacyName: pharmacyName,
                                  pharmacy: {},
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
