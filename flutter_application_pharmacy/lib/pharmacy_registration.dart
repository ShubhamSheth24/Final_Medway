// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'pharmacy_profile.dart';

// class PharmacyRegistrationPage extends StatefulWidget {
//   final String userName;
//   final String email;

//   const PharmacyRegistrationPage({
//     super.key,
//     required this.userName,
//     required this.email,
//   });

//   @override
//   _PharmacyRegistrationPageState createState() =>
//       _PharmacyRegistrationPageState();
// }

// class _PharmacyRegistrationPageState extends State<PharmacyRegistrationPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _pharmacyNameController = TextEditingController();
//   final TextEditingController _ownerNameController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();
//   final TextEditingController _contactController = TextEditingController();

//   List<Map<String, dynamic>> _medicines = [];
//   final TextEditingController _medicineNameController = TextEditingController();
//   final TextEditingController _medicinePriceController =
//       TextEditingController();
//   final TextEditingController _medicineQuantityController =
//       TextEditingController();
//   File? _medicineImage;
//   final picker = ImagePicker();
//   bool _isLoading = false;

//   Future<void> _pickMedicineImage() async {
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null)
//       setState(() => _medicineImage = File(pickedFile.path));
//   }

//   Future<String?> _uploadMedicineImage() async {
//     if (_medicineImage == null) return null;
//     String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//     Reference storageRef = FirebaseStorage.instance.ref().child(
//       'pharmacy_medicines/$fileName.jpg',
//     );
//     UploadTask uploadTask = storageRef.putFile(_medicineImage!);
//     TaskSnapshot taskSnapshot = await uploadTask;
//     return await taskSnapshot.ref.getDownloadURL();
//   }

//   void _addMedicine() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text(
//               "Add Medicine",
//               style: TextStyle(color: Colors.blue),
//             ),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildDialogTextField(
//                     _medicineNameController,
//                     "Medicine Name",
//                   ),
//                   _buildDialogTextField(
//                     _medicinePriceController,
//                     "Price per Packet",
//                     keyboardType: TextInputType.number,
//                   ),
//                   _buildDialogTextField(
//                     _medicineQuantityController,
//                     "Quantity (Packets)",
//                     keyboardType: TextInputType.number,
//                   ),
//                   const SizedBox(height: 16),
//                   _medicineImage == null
//                       ? ElevatedButton(
//                         onPressed: _pickMedicineImage,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue[700],
//                         ),
//                         child: const Text(
//                           "Pick Image",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       )
//                       : Column(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.file(
//                               _medicineImage!,
//                               height: 100,
//                               width: 100,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: _pickMedicineImage,
//                             child: const Text(
//                               "Change Image",
//                               style: TextStyle(color: Colors.blue),
//                             ),
//                           ),
//                         ],
//                       ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Cancel"),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (_medicineNameController.text.trim().isEmpty ||
//                       _medicinePriceController.text.trim().isEmpty ||
//                       _medicineQuantityController.text.trim().isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("Please fill all fields"),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                     return;
//                   }
//                   setState(() => _isLoading = true);
//                   String? imageUrl = await _uploadMedicineImage();
//                   setState(() {
//                     _medicines.add({
//                       "name": _medicineNameController.text.trim(),
//                       "pricePerPacket": double.parse(
//                         _medicinePriceController.text.trim(),
//                       ),
//                       "quantity": int.parse(
//                         _medicineQuantityController.text.trim(),
//                       ),
//                       "imageUrl": imageUrl,
//                     });
//                     _medicineNameController.clear();
//                     _medicinePriceController.clear();
//                     _medicineQuantityController.clear();
//                     _medicineImage = null;
//                     _isLoading = false;
//                   });
//                   Navigator.pop(context);
//                 },
//                 child: const Text("Add"),
//               ),
//             ],
//           ),
//     );
//   }

//   Future<void> registerPharmacy() async {
//     if (_formKey.currentState!.validate()) {
//       if (_medicines.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text("Please add at least one medicine"),
//             backgroundColor: Colors.red[700],
//           ),
//         );
//         return;
//       }

//       setState(() => _isLoading = true);

//       try {
//         DocumentReference pharmacyRef = await FirebaseFirestore.instance
//             .collection('pharmacies')
//             .add({
//               "email": widget.email,
//               "pharmacyName": _pharmacyNameController.text.trim(),
//               "ownerName": _ownerNameController.text.trim(),
//               "location": _locationController.text.trim(),
//               "contact": _contactController.text.trim(),
//               "createdAt": FieldValue.serverTimestamp(),
//             });

//         CollectionReference medicinesRef = pharmacyRef.collection('medicines');
//         for (var medicine in _medicines) {
//           await medicinesRef.add(medicine);
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text("Pharmacy Registered Successfully"),
//             backgroundColor: Colors.blue[600],
//           ),
//         );

//         _clearForm();

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (context) => PharmacyProfilePage(pharmacyId: pharmacyRef.id),
//           ),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error: ${e.toString()}"),
//             backgroundColor: Colors.red[700],
//           ),
//         );
//       } finally {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   void _clearForm() {
//     _pharmacyNameController.clear();
//     _ownerNameController.clear();
//     _locationController.clear();
//     _contactController.clear();
//     setState(() => _medicines = []);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           "Pharmacy Registration",
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Pharmacy Details",
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue[700],
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           _buildTextField(
//                             _pharmacyNameController,
//                             "Pharmacy Name",
//                             Icons.store,
//                           ),
//                           const SizedBox(height: 16),
//                           _buildTextField(
//                             _ownerNameController,
//                             "Owner Name",
//                             Icons.person,
//                           ),
//                           const SizedBox(height: 16),
//                           _buildTextField(
//                             _locationController,
//                             "Location",
//                             Icons.location_on,
//                           ),
//                           const SizedBox(height: 16),
//                           _buildTextField(
//                             _contactController,
//                             "Contact Number",
//                             Icons.phone,
//                             keyboardType: TextInputType.phone,
//                             validator:
//                                 (value) =>
//                                     value!.isEmpty ||
//                                             !RegExp(r'^\d{10}$').hasMatch(value)
//                                         ? "Enter a valid 10-digit number"
//                                         : null,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Medicines Inventory",
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue[700],
//                                 ),
//                               ),
//                               ElevatedButton(
//                                 onPressed: _addMedicine,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue[700],
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 child: const Text(
//                                   "Add Medicine",
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           _medicines.isEmpty
//                               ? const Center(
//                                 child: Text(
//                                   "No medicines added yet",
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               )
//                               : ListView.builder(
//                                 shrinkWrap: true,
//                                 physics: const NeverScrollableScrollPhysics(),
//                                 itemCount: _medicines.length,
//                                 itemBuilder: (context, index) {
//                                   return ListTile(
//                                     leading:
//                                         _medicines[index]['imageUrl'] != null
//                                             ? ClipRRect(
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                               child: Image.network(
//                                                 _medicines[index]['imageUrl'],
//                                                 width: 50,
//                                                 height: 50,
//                                                 fit: BoxFit.cover,
//                                               ),
//                                             )
//                                             : const Icon(
//                                               Icons.image,
//                                               size: 50,
//                                               color: Colors.grey,
//                                             ),
//                                     title: Text(
//                                       _medicines[index]['name'],
//                                       style: const TextStyle(
//                                         color: Colors.black,
//                                       ),
//                                     ),
//                                     subtitle: Text(
//                                       "Price/Packet: \$${_medicines[index]['pricePerPacket']} | Qty: ${_medicines[index]['quantity']}",
//                                       style: TextStyle(color: Colors.grey[700]),
//                                     ),
//                                     trailing: IconButton(
//                                       icon: const Icon(
//                                         Icons.delete,
//                                         color: Colors.red,
//                                       ),
//                                       onPressed:
//                                           () => setState(
//                                             () => _medicines.removeAt(index),
//                                           ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Positioned(
//             left: 16,
//             right: 16,
//             bottom: 16,
//             child: ElevatedButton(
//               onPressed: _isLoading ? null : registerPharmacy,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue[700],
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child:
//                   _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                         "Submit Registration",
//                         style: TextStyle(fontSize: 16, color: Colors.white),
//                       ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField(
//     TextEditingController controller,
//     String label,
//     IconData icon, {
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: Colors.blue[700]),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.blue, width: 2),
//         ),
//       ),
//       validator:
//           validator ?? (value) => value!.isEmpty ? "Please enter $label" : null,
//       style: const TextStyle(color: Colors.black),
//     );
//   }

//   Widget _buildDialogTextField(
//     TextEditingController controller,
//     String label, {
//     TextInputType? keyboardType,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: Colors.blue),
//           ),
//         ),
//         style: const TextStyle(color: Colors.black),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'pharmacy_profile.dart';

class PharmacyRegistrationPage extends StatefulWidget {
  final String userName;
  final String email;

  const PharmacyRegistrationPage({
    super.key,
    required this.userName,
    required this.email,
  });

  @override
  _PharmacyRegistrationPageState createState() =>
      _PharmacyRegistrationPageState();
}

class _PharmacyRegistrationPageState extends State<PharmacyRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pharmacyNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  List<Map<String, dynamic>> _medicines = [];
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _medicinePriceController =
      TextEditingController();
  final TextEditingController _medicineQuantityController =
      TextEditingController();
  File? _medicineImage;
  final picker = ImagePicker();
  bool _isLoading = false;

  List<Map<String, dynamic>> _orders = []; // New list for orders
  final TextEditingController _orderUserIdController = TextEditingController();
  final TextEditingController _orderMedicineNameController =
      TextEditingController();
  final TextEditingController _orderQuantityController =
      TextEditingController();
  final TextEditingController _orderTotalPriceController =
      TextEditingController();
  final TextEditingController _orderStatusController = TextEditingController(
    text: "pending",
  );

  Future<void> _pickMedicineImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null)
      setState(() => _medicineImage = File(pickedFile.path));
  }

  Future<String?> _uploadMedicineImage() async {
    if (_medicineImage == null) return null;
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child(
      'pharmacy_medicines/$fileName.jpg',
    );
    UploadTask uploadTask = storageRef.putFile(_medicineImage!);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  void _addMedicine() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              "Add Medicine",
              style: TextStyle(color: Colors.blue),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    _medicineNameController,
                    "Medicine Name",
                  ),
                  _buildDialogTextField(
                    _medicinePriceController,
                    "Price per Packet",
                    keyboardType: TextInputType.number,
                  ),
                  _buildDialogTextField(
                    _medicineQuantityController,
                    "Quantity (Packets)",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _medicineImage == null
                      ? ElevatedButton(
                        onPressed: _pickMedicineImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                        ),
                        child: const Text(
                          "Pick Image",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                      : Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _medicineImage!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          TextButton(
                            onPressed: _pickMedicineImage,
                            child: const Text(
                              "Change Image",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
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
                onPressed: () async {
                  if (_medicineNameController.text.trim().isEmpty ||
                      _medicinePriceController.text.trim().isEmpty ||
                      _medicineQuantityController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill all fields"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  String? imageUrl = await _uploadMedicineImage();
                  setState(() {
                    _medicines.add({
                      "name": _medicineNameController.text.trim(),
                      "pricePerPacket": double.parse(
                        _medicinePriceController.text.trim(),
                      ),
                      "quantity": int.parse(
                        _medicineQuantityController.text.trim(),
                      ),
                      "imageUrl": imageUrl,
                    });
                    _medicineNameController.clear();
                    _medicinePriceController.clear();
                    _medicineQuantityController.clear();
                    _medicineImage = null;
                    _isLoading = false;
                  });
                  Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  void _addOrder() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              "Add Order",
              style: TextStyle(color: Colors.blue),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(_orderUserIdController, "User ID"),
                  _buildDialogTextField(
                    _orderMedicineNameController,
                    "Medicine Name",
                  ),
                  _buildDialogTextField(
                    _orderQuantityController,
                    "Quantity",
                    keyboardType: TextInputType.number,
                  ),
                  _buildDialogTextField(
                    _orderTotalPriceController,
                    "Total Price",
                    keyboardType: TextInputType.number,
                  ),
                  _buildDialogTextField(
                    _orderStatusController,
                    "Status (pending/paid/dispatched)",
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
                  if (_orderUserIdController.text.trim().isEmpty ||
                      _orderMedicineNameController.text.trim().isEmpty ||
                      _orderQuantityController.text.trim().isEmpty ||
                      _orderTotalPriceController.text.trim().isEmpty ||
                      _orderStatusController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill all fields"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _orders.add({
                      "userId": _orderUserIdController.text.trim(),
                      "medicineName": _orderMedicineNameController.text.trim(),
                      "quantity": int.parse(
                        _orderQuantityController.text.trim(),
                      ),
                      "totalPrice": double.parse(
                        _orderTotalPriceController.text.trim(),
                      ),
                      "status": _orderStatusController.text.trim(),
                      "timestamp": FieldValue.serverTimestamp(),
                    });
                    _orderUserIdController.clear();
                    _orderMedicineNameController.clear();
                    _orderQuantityController.clear();
                    _orderTotalPriceController.clear();
                    _orderStatusController.text = "pending";
                  });
                  Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  Future<void> registerPharmacy() async {
    if (_formKey.currentState!.validate()) {
      if (_medicines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please add at least one medicine"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        DocumentReference pharmacyRef = await FirebaseFirestore.instance
            .collection('pharmacies')
            .add({
              "email": widget.email,
              "pharmacyName": _pharmacyNameController.text.trim(),
              "ownerName": _ownerNameController.text.trim(),
              "location": _locationController.text.trim(),
              "contact": _contactController.text.trim(),
              "createdAt": FieldValue.serverTimestamp(),
            });

        CollectionReference medicinesRef = pharmacyRef.collection('medicines');
        for (var medicine in _medicines) {
          await medicinesRef.add(medicine);
        }

        CollectionReference ordersRef = pharmacyRef.collection('orders');
        for (var order in _orders) {
          await ordersRef.add(order);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pharmacy Registered Successfully"),
            backgroundColor: Colors.blue,
          ),
        );

        _clearForm();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => PharmacyProfilePage(pharmacyId: pharmacyRef.id),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red[700],
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _pharmacyNameController.clear();
    _ownerNameController.clear();
    _locationController.clear();
    _contactController.clear();
    setState(() {
      _medicines = [];
      _orders = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Pharmacy Registration",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pharmacy Details",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _pharmacyNameController,
                            "Pharmacy Name",
                            Icons.store,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _ownerNameController,
                            "Owner Name",
                            Icons.person,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _locationController,
                            "Location",
                            Icons.location_on,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _contactController,
                            "Contact Number",
                            Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator:
                                (value) =>
                                    value!.isEmpty ||
                                            !RegExp(r'^\d{10}$').hasMatch(value)
                                        ? "Enter a valid 10-digit number"
                                        : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                              ElevatedButton(
                                onPressed: _addMedicine,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Add Medicine",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _medicines.isEmpty
                              ? const Center(
                                child: Text(
                                  "No medicines added yet",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _medicines.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading:
                                        _medicines[index]['imageUrl'] != null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                _medicines[index]['imageUrl'],
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
                                      _medicines[index]['name'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Price/Packet: ${_medicines[index]['pricePerPacket']} | Qty: ${_medicines[index]['quantity']}",
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => _medicines.removeAt(index),
                                          ),
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Initial Orders",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _addOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Add Order",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _orders.isEmpty
                              ? const Center(
                                child: Text(
                                  "No orders added yet",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _orders.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(
                                      "${_orders[index]['userId']} - ${_orders[index]['medicineName']}",
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Qty: ${_orders[index]['quantity']} | Total: ${_orders[index]['totalPrice']} | Status: ${_orders[index]['status']}",
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => _orders.removeAt(index),
                                          ),
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: _isLoading ? null : registerPharmacy,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        "Submit Registration",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator:
          validator ?? (value) => value!.isEmpty ? "Please enter $label" : null,
      style: const TextStyle(color: Colors.black),
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
