//rzp_test_AZBOQjLqeHohOx
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add Firebase Auth

class RazorpayCheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  final String pharmacyId;
  final String deliveryAddress;
  final VoidCallback? onPaymentSuccess;

  const RazorpayCheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.pharmacyId,
    required this.deliveryAddress,
    this.onPaymentSuccess,
  });

  @override
  _RazorpayCheckoutScreenState createState() => _RazorpayCheckoutScreenState();
}

class _RazorpayCheckoutScreenState extends State<RazorpayCheckoutScreen> {
  late Razorpay _razorpay;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize Firebase Auth

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCheckout();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cartItems_${widget.pharmacyId}');
  }

  Future<void> _createOrderAndUpdateQuantity(
    PaymentSuccessResponse response,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final String? userId = _auth.currentUser?.uid; // Get current user's UID

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (var item in widget.cartItems) {
      // Create order entry with authenticated userId
      await firestore
          .collection('pharmacies')
          .doc(widget.pharmacyId)
          .collection('orders')
          .add({
            'userId': userId, // Use authenticated user ID
            'medicineId': item['medicineId'],
            'medicineName': item['name'],
            'quantity': item['quantity'],
            'totalPrice': item['pricePerPacket'] * item['quantity'],
            'status': 'paid',
            'paymentId': response.paymentId,
            'deliveryAddress': widget.deliveryAddress,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Update medicine quantity
      DocumentSnapshot medicineDoc =
          await firestore
              .collection('pharmacies')
              .doc(widget.pharmacyId)
              .collection('medicines')
              .doc(item['medicineId'])
              .get();
      int currentQuantity =
          (medicineDoc.data() as Map<String, dynamic>)['quantity'];
      await firestore
          .collection('pharmacies')
          .doc(widget.pharmacyId)
          .collection('medicines')
          .doc(item['medicineId'])
          .update({'quantity': currentQuantity - item['quantity']});
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success: Payment ID=${response.paymentId}');
    await _createOrderAndUpdateQuantity(response);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Successful! Payment ID: ${response.paymentId}'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {
      widget.cartItems.clear();
      _clearCart();
    });
    widget.onPaymentSuccess?.call();
    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Failed: Code=${response.code}, Message=${response.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment Failed! Error: ${response.message ?? "Unknown error"}',
        ),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pop(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet Selected: ${response.walletName}'),
      ),
    );
  }

  void _openCheckout() {
    var options = {
      'key':
          'rzp_test_AZBOQjLqeHohOx', // Replace with your actual Razorpay test key
      'amount': (widget.totalAmount * 100).toInt(),
      'name': 'Pharmacy App',
      'description': 'Payment for Medicines',
    };

    try {
      print('Opening Razorpay with options: $options');
      _razorpay.open(options);
    } catch (e) {
      print('Error opening Razorpay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error initiating payment'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Payment'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
