// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class OrdersPage extends StatelessWidget {
//   const OrdersPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('My Orders'),
//           backgroundColor: Colors.blueAccent,
//         ),
//         body: const Center(child: Text('Please sign in to view your orders')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Orders'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream:
//             FirebaseFirestore.instance
//                 .collectionGroup('orders')
//                 .where('userId', isEqualTo: user.uid)
//                 .orderBy('timestamp', descending: true)
//                 .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             print("Error fetching orders: ${snapshot.error}");
//             return Center(
//               child: Text(
//                 "Error loading orders: ${snapshot.error}",
//                 style: const TextStyle(color: Colors.red),
//               ),
//             );
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text(
//                 "No orders placed yet",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               var order =
//                   snapshot.data!.docs[index].data() as Map<String, dynamic>;
//               String status = order['status'] ?? 'unknown';
//               String displayStatus =
//                   status == 'paid'
//                       ? 'Pending'
//                       : status == 'dispatched'
//                       ? 'Dispatched'
//                       : status == 'cancelled'
//                       ? 'Cancelled'
//                       : 'Unknown';

//               return Card(
//                 elevation: 2,
//                 margin: const EdgeInsets.symmetric(vertical: 8),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Medicine: ${order['medicineName'] ?? 'N/A'}",
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Quantity: ${order['quantity'] ?? 'N/A'}",
//                         style: TextStyle(color: Colors.grey[700], fontSize: 16),
//                       ),
//                       Text(
//                         "Total: \$${order['totalPrice'] ?? 'N/A'}",
//                         style: TextStyle(color: Colors.grey[700], fontSize: 16),
//                       ),
//                       Text(
//                         "Address: ${order['deliveryAddress'] ?? 'N/A'}",
//                         style: TextStyle(color: Colors.grey[700], fontSize: 16),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Status: $displayStatus",
//                             style: TextStyle(
//                               color:
//                                   displayStatus == 'Pending'
//                                       ? Colors.blue
//                                       : displayStatus == 'Dispatched'
//                                       ? Colors.green
//                                       : displayStatus == 'Cancelled'
//                                       ? Colors.orange
//                                       : Colors.red,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Text(
//                             order['timestamp'] != null
//                                 ? (order['timestamp'] as Timestamp)
//                                     .toDate()
//                                     .toString()
//                                     .substring(0, 16)
//                                 : "N/A",
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Orders',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[900]!, Colors.blue[700]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: Text('Please sign in to view your orders')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collectionGroup('orders')
                .where('userId', isEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching orders: ${snapshot.error}");
            return Center(
              child: Text(
                "Error loading orders: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No orders placed yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String status = order['status'] ?? 'unknown';
              String displayStatus =
                  status == 'paid'
                      ? 'Pending'
                      : status == 'dispatched'
                      ? 'Dispatched'
                      : status == 'cancelled'
                      ? 'Cancelled'
                      : 'Unknown';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Medicine: ${order['medicineName'] ?? 'N/A'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Quantity: ${order['quantity'] ?? 'N/A'}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                      Text(
                        "Total: \$${order['totalPrice'] ?? 'N/A'}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                      Text(
                        "Address: ${order['deliveryAddress'] ?? 'N/A'}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Status: $displayStatus",
                            style: TextStyle(
                              color:
                                  displayStatus == 'Pending'
                                      ? Colors.blue
                                      : displayStatus == 'Dispatched'
                                      ? Colors.green
                                      : displayStatus == 'Cancelled'
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            order['timestamp'] != null
                                ? (order['timestamp'] as Timestamp)
                                    .toDate()
                                    .toString()
                                    .substring(0, 16)
                                : "N/A",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
