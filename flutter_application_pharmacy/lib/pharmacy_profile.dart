import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PharmacyProfilePage extends StatefulWidget {
  final String pharmacyId;

  const PharmacyProfilePage({super.key, required this.pharmacyId});

  @override
  _PharmacyProfilePageState createState() => _PharmacyProfilePageState();
}

class _PharmacyProfilePageState extends State<PharmacyProfilePage> {
  late Future<DocumentSnapshot> _pharmacyFuture;
  late Stream<QuerySnapshot> _medicinesStream;
  late Stream<QuerySnapshot> _ordersStream;
  final picker = ImagePicker();
  final Map<String, bool> _expandedOrders =
      {}; // Track expanded state of orders

  @override
  void initState() {
    super.initState();
    _pharmacyFuture =
        FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(widget.pharmacyId)
            .get();
    _medicinesStream =
        FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(widget.pharmacyId)
            .collection('medicines')
            .snapshots();
    _ordersStream =
        FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(widget.pharmacyId)
            .collection('orders')
            .snapshots();
  }

  Future<void> _updatePharmacyField(Map<String, dynamic> updatedData) async {
    await FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(widget.pharmacyId)
        .update(updatedData);
    setState(() {
      _pharmacyFuture =
          FirebaseFirestore.instance
              .collection('pharmacies')
              .doc(widget.pharmacyId)
              .get();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Details updated successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _addOrUpdateMedicine({
    Map<String, dynamic>? existingMedicine,
    String? medicineId,
  }) async {
    TextEditingController nameController = TextEditingController(
      text: existingMedicine?['name'] ?? '',
    );
    TextEditingController priceController = TextEditingController(
      text: existingMedicine?['pricePerPacket']?.toString() ?? '',
    );
    TextEditingController quantityController = TextEditingController(
      text: existingMedicine?['quantity']?.toString() ?? '',
    );
    TextEditingController descriptionController = TextEditingController(
      text: existingMedicine?['description'] ?? '',
    );
    File? newImage;
    String? imageUrl = existingMedicine?['imageUrl'];

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              existingMedicine == null ? "Add Medicine" : "Edit Medicine",
              style: const TextStyle(color: Colors.blue),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(nameController, "Medicine Name"),
                  _buildDialogTextField(
                    priceController,
                    "Price per Packet",
                    keyboardType: TextInputType.number,
                  ),
                  _buildDialogTextField(
                    quantityController,
                    "Quantity (Packets)",
                    keyboardType: TextInputType.number,
                  ),
                  _buildDialogTextField(descriptionController, "Description"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (pickedFile != null) {
                        newImage = File(pickedFile.path);
                        String fileName =
                            DateTime.now().millisecondsSinceEpoch.toString();
                        Reference storageRef = FirebaseStorage.instance
                            .ref()
                            .child('pharmacy_medicines/$fileName.jpg');
                        UploadTask uploadTask = storageRef.putFile(newImage!);
                        TaskSnapshot taskSnapshot = await uploadTask;
                        imageUrl = await taskSnapshot.ref.getDownloadURL();
                        setState(() {}); // Refresh dialog
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                    ),
                    child: Text(
                      existingMedicine == null ? "Pick Image" : "Change Image",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      priceController.text.isNotEmpty &&
                      quantityController.text.isNotEmpty &&
                      descriptionController.text.isNotEmpty) {
                    Map<String, dynamic> medicineData = {
                      "name": nameController.text.trim(),
                      "pricePerPacket": double.parse(
                        priceController.text.trim(),
                      ),
                      "quantity": int.parse(quantityController.text.trim()),
                      "description": descriptionController.text.trim(),
                      "imageUrl": imageUrl,
                    };
                    if (medicineId == null) {
                      await FirebaseFirestore.instance
                          .collection('pharmacies')
                          .doc(widget.pharmacyId)
                          .collection('medicines')
                          .add(medicineData);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('pharmacies')
                          .doc(widget.pharmacyId)
                          .collection('medicines')
                          .doc(medicineId)
                          .update(medicineData);
                    }
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill all fields"),
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

  Future<void> _deleteMedicine(String medicineId) async {
    await FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(widget.pharmacyId)
        .collection('medicines')
        .doc(medicineId)
        .delete();
  }

  Future<void> _dispatchOrder(
    String orderId,
    String medicineId,
    int orderedQuantity,
  ) async {
    DocumentSnapshot orderDoc =
        await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(widget.pharmacyId)
            .collection('orders')
            .doc(orderId)
            .get();
    String status = (orderDoc.data() as Map<String, dynamic>)['status'];
    if (status != 'paid') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot dispatch: Payment not completed"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DocumentSnapshot medicineDoc =
        await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(widget.pharmacyId)
            .collection('medicines')
            .doc(medicineId)
            .get();
    int currentQuantity =
        (medicineDoc.data() as Map<String, dynamic>)['quantity'];
    if (currentQuantity >= orderedQuantity) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Confirm Dispatch"),
              content: const Text(
                "Are you sure you want to dispatch this order?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Dispatch"),
                ),
              ],
            ),
      );

      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(widget.pharmacyId)
            .collection('medicines')
            .doc(medicineId)
            .update({"quantity": currentQuantity - orderedQuantity});
        await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(widget.pharmacyId)
            .collection('orders')
            .doc(orderId)
            .update({"status": "dispatched"});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order dispatched successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient stock to dispatch"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    DocumentSnapshot orderDoc =
        await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(widget.pharmacyId)
            .collection('orders')
            .doc(orderId)
            .get();
    String status = (orderDoc.data() as Map<String, dynamic>)['status'];
    if (status != 'paid') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot cancel: Order already processed"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Cancellation"),
            content: const Text("Are you sure you want to cancel this order?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(widget.pharmacyId)
          .collection('orders')
          .doc(orderId)
          .update({"status": "cancelled"});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order cancelled successfully!"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _editDetails(
    String pharmacyName,
    String ownerName,
    String location,
    String contact,
  ) {
    TextEditingController pharmacyNameController = TextEditingController(
      text: pharmacyName,
    );
    TextEditingController ownerNameController = TextEditingController(
      text: ownerName,
    );
    TextEditingController locationController = TextEditingController(
      text: location,
    );
    TextEditingController contactController = TextEditingController(
      text: contact,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              "Edit Pharmacy Details",
              style: TextStyle(color: Colors.blue),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    pharmacyNameController,
                    "Pharmacy Name",
                  ),
                  _buildDialogTextField(ownerNameController, "Owner Name"),
                  _buildDialogTextField(locationController, "Location"),
                  _buildDialogTextField(
                    contactController,
                    "Contact Number",
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _updatePharmacyField({
                    "pharmacyName": pharmacyNameController.text.trim(),
                    "ownerName": ownerNameController.text.trim(),
                    "location": locationController.text.trim(),
                    "contact": contactController.text.trim(),
                  });
                  Navigator.pop(context);
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Pharmacy Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _pharmacyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.hasError)
            return const Center(child: Text("Error loading profile"));

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String pharmacyName = data['pharmacyName'];
          String ownerName = data['ownerName'];
          String location = data['location'];
          String contact = data['contact'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[900]!, Colors.blue[700]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        pharmacyName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Owner: $ownerName",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Pharmacy Details",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed:
                                    () => _editDetails(
                                      pharmacyName,
                                      ownerName,
                                      location,
                                      contact,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.store,
                            "Pharmacy Name",
                            pharmacyName,
                          ),
                          _buildInfoRow(Icons.person, "Owner Name", ownerName),
                          _buildInfoRow(
                            Icons.location_on,
                            "Location",
                            location,
                          ),
                          _buildInfoRow(Icons.phone, "Contact", contact),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Medicines Inventory",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.blue),
                                onPressed: () => _addOrUpdateMedicine(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream: _medicinesStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting)
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No medicines available",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var medicine =
                                      snapshot.data!.docs[index].data()
                                          as Map<String, dynamic>;
                                  String medicineId =
                                      snapshot.data!.docs[index].id;
                                  return ListTile(
                                    leading:
                                        medicine['imageUrl'] != null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                medicine['imageUrl'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                            : const Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                    title: Text(
                                      medicine['name'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Price/Packet: \$${medicine['pricePerPacket']} | Qty: ${medicine['quantity']}",
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          "Description: ${medicine['description']}",
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed:
                                              () => _addOrUpdateMedicine(
                                                existingMedicine: medicine,
                                                medicineId: medicineId,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _deleteMedicine(medicineId),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Orders",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream: _ordersStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting)
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No orders yet",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var order =
                                      snapshot.data!.docs[index].data()
                                          as Map<String, dynamic>;
                                  String orderId =
                                      snapshot.data!.docs[index].id;
                                  String status = order['status'];
                                  bool isExpanded =
                                      _expandedOrders[orderId] ?? false;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _expandedOrders[orderId] = !isExpanded;
                                      });
                                    },
                                    child: Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Order by ${order['userId']}",
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "Medicine: ${order['medicineName']} | Qty: ${order['quantity']} | Total: \$${order['totalPrice']}",
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  isExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more,
                                                  color: Colors.blue[700],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Status: $status",
                                              style: TextStyle(
                                                color:
                                                    status == 'paid'
                                                        ? Colors.blue
                                                        : status == 'dispatched'
                                                        ? Colors.green
                                                        : status == 'cancelled'
                                                        ? Colors.orange
                                                        : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isExpanded) ...[
                                              const Divider(height: 20),
                                              Text(
                                                "Delivery Address: ${order['deliveryAddress']}",
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              if (status == 'paid') ...[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed:
                                                          () => _dispatchOrder(
                                                            orderId,
                                                            order['medicineId'] ??
                                                                '',
                                                            order['quantity'],
                                                          ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green[700],
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 20,
                                                              vertical: 10,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        "Dispatch",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed:
                                                          () => _cancelOrder(
                                                            orderId,
                                                          ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red[700],
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 20,
                                                              vertical: 10,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        style: const TextStyle(color: Colors.black),
      ),
    );
  }
}
