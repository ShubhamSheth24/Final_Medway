import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PharmacyListScreen extends StatelessWidget {
  const PharmacyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacies'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pharmacies').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final pharmacies = snapshot.data!.docs;
          return ListView.builder(
            itemCount: pharmacies.length,
            itemBuilder: (context, index) {
              final pharmacy = pharmacies[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.local_pharmacy, color: Colors.green),
                title: Text(pharmacy['name']),
                subtitle: Text(pharmacy['location']),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PharmacyDetailScreen(pharmacy: pharmacy)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PharmacyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pharmacy;

  const PharmacyDetailScreen({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pharmacy['name']),
        backgroundColor: Colors.blue.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${pharmacy['location']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Medicines:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...(pharmacy['medicines'] as List).map((med) => Text(
                  '${med['name']} - ${med['quantity']}',
                  style: const TextStyle(fontSize: 16),
                )),
          ],
        ),
      ),
    );
  }
}
