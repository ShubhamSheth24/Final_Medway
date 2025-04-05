import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cart_screen.dart';

class PharmacyDetailScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  const PharmacyDetailScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName, required Map pharmacy,
  });

  @override
  _PharmacyDetailScreenState createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _medicinesStream;
  int _cartItemCount = 0;
  List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _medicinesStream =
        _firestore
            .collection('pharmacies')
            .doc(widget.pharmacyId)
            .collection('medicines')
            .snapshots();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString('cartItems_${widget.pharmacyId}');
    if (cartData != null) {
      setState(() {
        _cartItems = List<Map<String, dynamic>>.from(jsonDecode(cartData));
        _cartItemCount = _cartItems.fold(
          0,
          (sum, item) => sum + (item['quantity'] as int),
        );
      });
    }
  }

  Future<void> _saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cartItems_${widget.pharmacyId}',
      jsonEncode(_cartItems),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMedicinesManually() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('pharmacies')
              .doc(widget.pharmacyId)
              .collection('medicines')
              .get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>? ?? {};
        data['medicineId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Manual fetch error: $e');
      return [];
    }
  }

  void _showMedicineDetail(
    BuildContext context,
    Map<String, dynamic> medicine,
    String medicineId,
  ) {
    int quantity = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['name'] ?? 'Unnamed Medicine',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child:
                          medicine['imageUrl'] != null
                              ? Image.network(
                                medicine['imageUrl'],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.image,
                                      size: 150,
                                      color: Colors.grey,
                                    ),
                              )
                              : const Icon(
                                Icons.image,
                                size: 150,
                                color: Colors.grey,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Price: \$${medicine['pricePerPacket']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Availability: ${medicine['quantity'] ?? 0} packets',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Description: ${medicine['description'] ?? 'No description available'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.blue),
                          onPressed:
                              quantity > 1
                                  ? () => setState(() => quantity--)
                                  : null,
                        ),
                        Text('$quantity', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.blue),
                          onPressed:
                              (medicine['quantity'] ?? 0) > quantity
                                  ? () => setState(() => quantity++)
                                  : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _cartItemCount += quantity;
                            _cartItems.add({
                              'medicineId': medicineId,
                              'name': medicine['name'] ?? 'Unnamed Medicine',
                              'pricePerPacket':
                                  medicine['pricePerPacket'] ?? 0.0,
                              'quantity': quantity,
                              'imageUrl': medicine['imageUrl'],
                              'availableQuantity': medicine['quantity'] ?? 0,
                            });
                            _saveCartItems();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added $quantity x ${medicine['name'] ?? 'Unnamed Medicine'} to cart',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacyName),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    print(
                      'Cart icon clicked! Navigating to CartScreen with ${_cartItems.length} items for ${widget.pharmacyId}',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CartScreen(
                              cartItems: _cartItems,
                              pharmacyId: widget.pharmacyId,
                              onCartUpdated: () {
                                setState(() {
                                  _loadCartItems();
                                });
                              },
                            ),
                      ),
                    ).then((_) {
                      setState(() {
                        _loadCartItems();
                      });
                    });
                  },
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {},
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _medicinesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchMedicinesManually(),
                    builder: (context, futureSnapshot) {
                      if (futureSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (futureSnapshot.hasError ||
                          !futureSnapshot.hasData ||
                          futureSnapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No medicines available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      final medicines = futureSnapshot.data!;
                      return _buildMedicineGrid(medicines);
                    },
                  );
                }

                final medicines =
                    snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>? ?? {};
                      data['medicineId'] = doc.id;
                      return data;
                    }).toList();

                return _buildMedicineGrid(medicines);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineGrid(List<Map<String, dynamic>> medicines) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        final medicine = medicines[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap:
                () => _showMedicineDetail(
                  context,
                  medicine,
                  medicine['medicineId'],
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child:
                      medicine['imageUrl'] != null
                          ? Image.network(
                            medicine['imageUrl'],
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                          )
                          : const Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey,
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine['name'] ?? 'Unnamed Medicine',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${medicine['pricePerPacket']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'Qty: ${medicine['quantity'] ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
