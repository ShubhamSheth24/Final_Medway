// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_pharmacy/home_page.dart';

// class TopPharmaciesScreen extends StatefulWidget {
//   const TopPharmaciesScreen({super.key});

//   @override
//   _TopPharmaciesScreenState createState() => _TopPharmaciesScreenState();
// }

// class _TopPharmaciesScreenState extends State<TopPharmaciesScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> _pharmacies = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchPharmacies();
//   }

//   Future<void> _fetchPharmacies() async {
//     try {
//       QuerySnapshot snapshot = await _firestore.collection('pharmacies').get();
//       setState(() {
//         _pharmacies =
//             snapshot.docs.map((doc) {
//               var data = doc.data() as Map<String, dynamic>;
//               data['pharmacyId'] =
//                   doc.id; // Store the document ID for navigation
//               return data;
//             }).toList();
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error fetching pharmacies: $e'),
//           backgroundColor: Colors.red[600],
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Top Pharmacies'),
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body:
//           _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : _pharmacies.isEmpty
//               ? const Center(child: Text('No pharmacies found'))
//               : ListView.builder(
//                 padding: const EdgeInsets.all(16.0),
//                 itemCount: _pharmacies.length,
//                 itemBuilder: (context, index) {
//                   final pharmacy = _pharmacies[index];
//                   return Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     margin: const EdgeInsets.only(bottom: 16.0),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         radius: 30,
//                         backgroundColor: Colors.grey[200],
//                         // No profile image for pharmacies yet, using initial
//                         child: Text(
//                           pharmacy['pharmacyName'][0].toUpperCase(),
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue[900],
//                           ),
//                         ),
//                       ),
//                       title: Text(
//                         pharmacy['pharmacyName'],
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Owner: ${pharmacy['ownerName']}',
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             pharmacy['location'],
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                         ],
//                       ),
//                       trailing: const Icon(
//                         Icons.arrow_forward_ios,
//                         size: 16,
//                         color: Colors.grey,
//                       ),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (context) => PharmacyDetailScreen(
//                                   pharmacyId: pharmacy['pharmacyId'],
//                                   pharmacyName: pharmacy['pharmacyName'],
//                                   pharmacy: {},
//                                 ),
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_pharmacy/home_page.dart';

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
              String pharmacyId = doc.id; // Explicitly capture document ID
              print(
                'Fetched pharmacy: pharmacyId=$pharmacyId, data=$data',
              ); // Debug log
              data['pharmacyId'] = pharmacyId; // Store the document ID
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
                        print(
                          'Navigating to PharmacyDetailScreen with pharmacyId: $pharmacyId, pharmacyName: $pharmacyName',
                        ); // Debug log
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
