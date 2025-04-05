import 'package:flutter/material.dart';
import 'package:flutter_application_pharmacy/services/razorpay_checkout_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String pharmacyId;
  final VoidCallback? onCartUpdated;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.pharmacyId,
    this.onCartUpdated,
  });

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get totalAmount {
    return widget.cartItems.fold(
      0.0,
      (sum, item) => sum + (item['pricePerPacket'] * item['quantity']),
    );
  }

  Future<void> _saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cartItems_${widget.pharmacyId}',
      jsonEncode(widget.cartItems),
    );
    widget.onCartUpdated?.call();
  }

  Future<String?> _promptForAddress(BuildContext context) async {
    TextEditingController addressController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delivery Address"),
            content: TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "Enter delivery address",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  if (addressController.text.trim().isNotEmpty) {
                    Navigator.pop(context, addressController.text.trim());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Address cannot be empty"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          widget.cartItems.isEmpty
              ? const Center(
                child: Text(
                  'Your cart is empty',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = widget.cartItems[index];
                        return Dismissible(
                          key: Key(item['medicineId']),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              widget.cartItems.removeAt(index);
                              _saveCartItems();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${item['name']} removed from cart',
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        item['imageUrl'] != null
                                            ? Image.network(
                                              item['imageUrl'],
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.image,
                                                    size: 60,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                            : const Icon(
                                              Icons.image,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${item['pricePerPacket'].toStringAsFixed(2)} x ${item['quantity']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          'Total: \$${(item['pricePerPacket'] * item['quantity']).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (item['quantity'] > 1) {
                                              item['quantity']--;
                                            } else {
                                              widget.cartItems.removeAt(index);
                                            }
                                            _saveCartItems();
                                          });
                                        },
                                      ),
                                      Text(
                                        '${item['quantity']}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            final availableQuantity =
                                                item['availableQuantity'] ?? 0;
                                            if (item['quantity'] <
                                                availableQuantity) {
                                              item['quantity']++;
                                              _saveCartItems();
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final address = await _promptForAddress(context);
                              if (address != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => RazorpayCheckoutScreen(
                                          cartItems: widget.cartItems,
                                          totalAmount: totalAmount,
                                          pharmacyId: widget.pharmacyId,
                                          deliveryAddress:
                                              address, // Pass address
                                          onPaymentSuccess: () {
                                            setState(() {
                                              widget.cartItems.clear();
                                              _saveCartItems();
                                            });
                                          },
                                        ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
