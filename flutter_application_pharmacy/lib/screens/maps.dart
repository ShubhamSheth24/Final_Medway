// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../models/user_model';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_typeahead/flutter_typeahead.dart';
// import 'package:provider/provider.dart';

// const String googleApiKey = "AIzaSyDhXcWeIuh9yG1aQ2AKvYCDGN6bVJL1RJk";

// class AmbulanceBookingScreen extends StatefulWidget {
//   const AmbulanceBookingScreen({super.key});

//   @override
//   State<AmbulanceBookingScreen> createState() => _AmbulanceBookingScreenState();
// }

// class _AmbulanceBookingScreenState extends State<AmbulanceBookingScreen> {
//   late GoogleMapController _mapController;
//   LatLng currentLocation = const LatLng(19.0760, 72.8777); // Default: Mumbai
//   LatLng? destinationLocation;
//   String pickupAddress = "Fetching address...";
//   String? destinationAddress;
//   Set<Polyline> polylines = {};
//   final TextEditingController _searchController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     print("AmbulanceBookingScreen initState started");
//     _requestLocationPermission();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     print("AmbulanceBookingScreen dispose called");
//     super.dispose();
//   }

//   Future<void> _requestLocationPermission() async {
//     final status = await Permission.location.request();
//     if (status == PermissionStatus.granted) {
//       _getUserLocation();
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Location permission is required!')),
//         );
//       }
//     }
//   }

//   Future<void> _getUserLocation() async {
//     setState(() => _isLoading = true);
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       setState(() {
//         currentLocation = LatLng(position.latitude, position.longitude);
//         _mapController.animateCamera(CameraUpdate.newLatLng(currentLocation));
//         _fetchAddress(position.latitude, position.longitude, isPickup: true);
//       });
//     } catch (e) {
//       print("Error getting location: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _fetchAddress(
//     double lat,
//     double lng, {
//     required bool isPickup,
//   }) async {
//     final url =
//         "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey";
//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print("Geocode Response: ${data.toString()}");
//       if (data["results"].isNotEmpty) {
//         setState(() {
//           if (isPickup) {
//             pickupAddress = data["results"][0]["formatted_address"];
//           } else {
//             destinationAddress = data["results"][0]["formatted_address"];
//           }
//         });
//       } else {
//         setState(() {
//           if (isPickup)
//             pickupAddress = "No address found";
//           else
//             destinationAddress = "No address found";
//         });
//       }
//     } else {
//       print("Geocode Error: ${response.statusCode} - ${response.body}");
//     }
//   }

//   Future<List<String>> _getPlaceSuggestions(String query) async {
//     final url =
//         "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey&types=geocode";
//     final response = await http.get(Uri.parse(url));

//     print("Places API URL: $url");
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print("Places API Response: ${data.toString()}");
//       if (data["status"] == "OK" && data["predictions"].isNotEmpty) {
//         return (data["predictions"] as List)
//             .map((prediction) => prediction["description"] as String)
//             .toList();
//       } else {
//         print("No predictions found: ${data["status"]}");
//         return [];
//       }
//     } else {
//       print("Places API Error: ${response.statusCode} - ${response.body}");
//       return [];
//     }
//   }

//   Future<void> _onPlaceSelected(String place) async {
//     setState(() => _isLoading = true);
//     final url =
//         "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(place)}&key=$googleApiKey";
//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print("Geocode Place Response: ${data.toString()}");
//       if (data["results"].isNotEmpty) {
//         final location = data["results"][0]["geometry"]["location"];
//         setState(() {
//           destinationLocation = LatLng(location["lat"], location["lng"]);
//           destinationAddress = place;
//           _mapController.animateCamera(
//             CameraUpdate.newLatLngZoom(destinationLocation!, 15),
//           );
//           _fetchRoute();
//         });
//       }
//     } else {
//       print("Geocode Place Error: ${response.statusCode} - ${response.body}");
//     }
//     setState(() => _isLoading = false);
//   }

//   Future<void> _fetchRoute() async {
//     if (destinationLocation == null) return;

//     final url =
//         "https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation.latitude},${currentLocation.longitude}&destination=${destinationLocation!.latitude},${destinationLocation!.longitude}&key=$googleApiKey";
//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print("Directions API Response: ${data.toString()}");
//       if (data["routes"].isNotEmpty) {
//         final points = data["routes"][0]["overview_polyline"]["points"];
//         final List<LatLng> polylineCoordinates = _decodePolyline(points);

//         setState(() {
//           polylines = {
//             Polyline(
//               polylineId: const PolylineId("route"),
//               points: polylineCoordinates,
//               color: Colors.blue,
//               width: 5,
//             ),
//           };
//           _mapController.animateCamera(
//             CameraUpdate.newLatLngBounds(
//               LatLngBounds(
//                 southwest: LatLng(
//                   currentLocation.latitude < destinationLocation!.latitude
//                       ? currentLocation.latitude
//                       : destinationLocation!.latitude,
//                   currentLocation.longitude < destinationLocation!.longitude
//                       ? currentLocation.longitude
//                       : destinationLocation!.longitude,
//                 ),
//                 northeast: LatLng(
//                   currentLocation.latitude > destinationLocation!.latitude
//                       ? currentLocation.latitude
//                       : destinationLocation!.latitude,
//                   currentLocation.longitude > destinationLocation!.longitude
//                       ? currentLocation.longitude
//                       : destinationLocation!.longitude,
//                 ),
//               ),
//               100,
//             ),
//           );
//         });
//       }
//     } else {
//       print("Directions API Error: ${response.statusCode} - ${response.body}");
//     }
//   }

//   List<LatLng> _decodePolyline(String encoded) {
//     List<LatLng> points = [];
//     int index = 0, len = encoded.length;
//     int lat = 0, lng = 0;

//     while (index < len) {
//       int b, shift = 0, result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lat += dlat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lng += dlng;

//       points.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return points;
//   }

//   Future<void> _bookAmbulance() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please sign in to book an ambulance')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);
//     try {
//       final docId = _generateDocId(user.email ?? "unknown");
//       final bookingId =
//           FirebaseFirestore.instance.collection('bookings').doc().id;

//       await FirebaseFirestore.instance
//           .collection('bookings')
//           .doc(bookingId)
//           .set({
//             'userDocId': docId,
//             'pickupAddress': pickupAddress,
//             'pickupLat': currentLocation.latitude,
//             'pickupLng': currentLocation.longitude,
//             'destinationAddress': destinationAddress,
//             'destinationLat': destinationLocation!.latitude,
//             'destinationLng': destinationLocation!.longitude,
//             'role':
//                 Provider.of<UserModel>(context, listen: false).role ??
//                 'Patient',
//             'timestamp': FieldValue.serverTimestamp(),
//             'status': 'pending',
//           });

//       print("Ambulance booked: Booking ID $bookingId");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Ambulance booked successfully!')),
//         );
//         Navigator.pop(context); // Go back to HomePage
//       }
//     } catch (e) {
//       print("Error booking ambulance: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error booking ambulance: $e')));
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   String _generateDocId(String email) {
//     return email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Book Ambulance',
//           style: TextStyle(color: Colors.black87),
//         ),
//         backgroundColor: Colors.blue.shade50,
//         elevation: 0,
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: currentLocation,
//               zoom: 15,
//             ),
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//             onMapCreated: (controller) {
//               _mapController = controller;
//             },
//             markers: {
//               Marker(
//                 markerId: const MarkerId("currentLocation"),
//                 position: currentLocation,
//                 icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueBlue,
//                 ),
//               ),
//               if (destinationLocation != null)
//                 Marker(
//                   markerId: const MarkerId("destination"),
//                   position: destinationLocation!,
//                   icon: BitmapDescriptor.defaultMarkerWithHue(
//                     BitmapDescriptor.hueRed,
//                   ),
//                 ),
//             },
//             polylines: polylines,
//             circles: {
//               Circle(
//                 circleId: const CircleId("accuracyCircle"),
//                 center: currentLocation,
//                 radius: 100,
//                 fillColor: Colors.blue.withOpacity(0.2),
//                 strokeWidth: 1,
//                 strokeColor: Colors.blue,
//               ),
//             },
//           ),
//           Positioned(
//             top: 20,
//             left: 20,
//             right: 20,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 15),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(30),
//                 boxShadow: const [
//                   BoxShadow(color: Colors.black12, blurRadius: 5),
//                 ],
//               ),
//               child: TypeAheadField<String>(
//                 suggestionsCallback: (pattern) async {
//                   if (pattern.isEmpty) return [];
//                   return await _getPlaceSuggestions(pattern);
//                 },
//                 itemBuilder: (context, String suggestion) {
//                   return ListTile(title: Text(suggestion));
//                 },
//                 onSelected: (String suggestion) {
//                   _searchController.text = suggestion;
//                   _onPlaceSelected(suggestion);
//                 },
//                 builder: (context, controller, focusNode) {
//                   return TextField(
//                     controller: _searchController,
//                     focusNode: focusNode,
//                     decoration: const InputDecoration(
//                       hintText: "Enter destination...",
//                       border: InputBorder.none,
//                       icon: Icon(Icons.search, color: Colors.black54),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 30,
//             left: 20,
//             right: 20,
//             child: Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: const [
//                   BoxShadow(color: Colors.black12, blurRadius: 5),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Pickup Address",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on, color: Colors.blue),
//                       const SizedBox(width: 5),
//                       Expanded(
//                         child: Text(
//                           pickupAddress,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.black87,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (destinationAddress != null) ...[
//                     const SizedBox(height: 10),
//                     const Text(
//                       "Destination Address",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.location_pin, color: Colors.red),
//                         const SizedBox(width: 5),
//                         Expanded(
//                           child: Text(
//                             destinationAddress!,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Colors.black87,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       minimumSize: const Size(double.infinity, 45),
//                     ),
//                     onPressed:
//                         _isLoading || destinationLocation == null
//                             ? null
//                             : _bookAmbulance,
//                     child:
//                         _isLoading
//                             ? const CircularProgressIndicator(
//                               color: Colors.white,
//                             )
//                             : const Text(
//                               "Book Ambulance",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],AIzaSyCGqVA17yZNyfoDIcowXcI6wBx8BP7fdOg
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/services.dart';

const String googleApiKey =
    "AIzaSyCGqVA17yZNyfoDIcowXcI6wBx8BP7fdOg"; // Replace with your actual API key

// UI Constants
const double defaultPadding = 20.0;
const Color primaryColor = Colors.blue;
const Color cardBackgroundColor = Colors.white;
const Color shadowColor = Colors.black12;

class AmbulanceBookingScreen extends StatefulWidget {
  const AmbulanceBookingScreen({super.key});

  @override
  State<AmbulanceBookingScreen> createState() => _AmbulanceBookingScreenState();
}

class _AmbulanceBookingScreenState extends State<AmbulanceBookingScreen> {
  late GoogleMapController _mapController;
  LatLng? currentLocation;
  LatLng? closestHospitalLocation;
  String pickupAddress = "Fetching address...";
  String? hospitalAddress;
  Set<Marker> markers = {};
  final TextEditingController _searchController = TextEditingController();
  String? estimatedTime;
  String? distance;
  bool isAmbulanceBooked = false;
  bool isLoading = true;

  // Hardcoded hospitals from Dahisar to Churchgate
  final List<Map<String, dynamic>> hardcodedHospitals = [
    {
      'name': 'Karuna Hospital',
      'location': const LatLng(19.2505, 72.8578),
    }, // Dahisar
    {
      'name': 'Bhaktivedanta Hospital',
      'location': const LatLng(19.2090, 72.8410),
    }, // Mira Road
    {
      'name': 'Wockhardt Hospital',
      'location': const LatLng(19.1726, 72.8397),
    }, // Bhayandar
    {
      'name': 'Kokilaben Dhirubhai Ambani Hospital',
      'location': const LatLng(19.1314, 72.8258),
    }, // Andheri
    {
      'name': 'Lilavati Hospital',
      'location': const LatLng(19.0510, 72.8290),
    }, // Bandra
    {
      'name': 'Hinduja Hospital',
      'location': const LatLng(19.0330, 72.8399),
    }, // Mahim
    {
      'name': 'Jaslok Hospital',
      'location': const LatLng(19.0210, 72.8178),
    }, // Peddar Road
    {
      'name': 'Bombay Hospital',
      'location': const LatLng(18.9430, 72.8228),
    }, // Marine Lines
    {
      'name': 'Saifee Hospital',
      'location': const LatLng(18.9370, 72.8180),
    }, // Churchgate
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      await _getUserLocation();
    } else {
      setState(() {
        pickupAddress = "Location permission denied";
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required!')),
      );
    }
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        markers.add(
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: const InfoWindow(title: "Your Location"),
          ),
        );
        _mapController.animateCamera(CameraUpdate.newLatLng(currentLocation!));
      });
      await _fetchAddress(
        position.latitude,
        position.longitude,
        isPickup: true,
      );
      await _findClosestHospital();
    } catch (e) {
      setState(() {
        pickupAddress = "Unable to fetch location";
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to fetch location'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              setState(() {
                isLoading = true;
                pickupAddress = "Fetching address...";
              });
              _getUserLocation();
            },
          ),
        ),
      );
    }
  }

  Future<void> _fetchAddress(
    double lat,
    double lng, {
    required bool isPickup,
  }) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["results"].isNotEmpty) {
          setState(() {
            if (isPickup) {
              pickupAddress = data["results"][0]["formatted_address"];
            } else {
              hospitalAddress = data["results"][0]["formatted_address"];
            }
            isLoading = false;
          });
        } else {
          setState(() {
            if (isPickup) {
              pickupAddress = "Address not available";
            } else {
              hospitalAddress = "Address not available";
            }
            isLoading = false;
          });
        }
      } else {
        setState(() {
          if (isPickup) {
            pickupAddress = "Address not available";
          } else {
            hospitalAddress = "Address not available";
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        if (isPickup) {
          pickupAddress = "Address not available";
        } else {
          hospitalAddress = "Address not available";
        }
        isLoading = false;
      });
    }
  }

  Future<List<String>> _getPlaceSuggestions(String query) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey&types=geocode&location=${currentLocation?.latitude},${currentLocation?.longitude}&radius=10000";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "OK") {
          return (data["predictions"] as List)
              .map((prediction) => prediction["description"] as String)
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _onPlaceSelected(String place) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(place)}&key=$googleApiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["results"].isNotEmpty) {
          final location = data["results"][0]["geometry"]["location"];
          setState(() {
            closestHospitalLocation = LatLng(location["lat"], location["lng"]);
            hospitalAddress = place;
            markers.clear();
            markers.add(
              Marker(
                markerId: const MarkerId("currentLocation"),
                position: currentLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
                infoWindow: const InfoWindow(title: "Your Location"),
              ),
            );
            markers.add(
              Marker(
                markerId: MarkerId(place),
                position: closestHospitalLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: InfoWindow(title: place),
              ),
            );
          });
          _calculateDistanceAndETA(closestHospitalLocation!);
          _mapController.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  currentLocation!.latitude < closestHospitalLocation!.latitude
                      ? currentLocation!.latitude
                      : closestHospitalLocation!.latitude,
                  currentLocation!.longitude <
                          closestHospitalLocation!.longitude
                      ? currentLocation!.longitude
                      : closestHospitalLocation!.longitude,
                ),
                northeast: LatLng(
                  currentLocation!.latitude > closestHospitalLocation!.latitude
                      ? currentLocation!.latitude
                      : closestHospitalLocation!.latitude,
                  currentLocation!.longitude >
                          closestHospitalLocation!.longitude
                      ? currentLocation!.longitude
                      : closestHospitalLocation!.longitude,
                ),
              ),
              100,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting place: $e')));
    }
  }

  void _calculateDistanceAndETA(LatLng hospital) {
    double dist =
        Geolocator.distanceBetween(
          currentLocation!.latitude,
          currentLocation!.longitude,
          hospital.latitude,
          hospital.longitude,
        ) /
        1000; // Distance in kilometers
    const double averageSpeedKmh = 20.0; // Realistic speed for Mumbai traffic
    const double timeBufferMinutes =
        5.0; // Buffer for starting delays, traffic lights, etc.
    double etaHours = dist / averageSpeedKmh;
    int etaMinutes =
        (etaHours * 60 + timeBufferMinutes).round(); // Add buffer and round

    setState(() {
      distance = "${dist.toStringAsFixed(1)} km";
      estimatedTime = "$etaMinutes mins";
    });
  }

  Future<void> _findClosestHospital() async {
    if (currentLocation == null) return;

    double minDistance = double.infinity;
    Map<String, dynamic>? closestHospital;

    for (var hospital in hardcodedHospitals) {
      double dist = Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        hospital['location'].latitude,
        hospital['location'].longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closestHospital = hospital;
      }
    }

    if (closestHospital != null) {
      setState(() {
        closestHospitalLocation = closestHospital?['location'] as LatLng;
        hospitalAddress = closestHospital?['name'] as String;
        markers.add(
          Marker(
            markerId: MarkerId(closestHospital?['name'] as String),
            position: closestHospitalLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: "${closestHospital?['name']} (Linked)",
            ),
          ),
        );
      });
      await _fetchAddress(
        closestHospitalLocation!.latitude,
        closestHospitalLocation!.longitude,
        isPickup: false,
      );
      _calculateDistanceAndETA(closestHospitalLocation!);
    } else {
      setState(() {
        hospitalAddress = "No nearby hospital found";
        isLoading = false;
      });
    }
  }

  void _recenterMap() {
    if (currentLocation != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(currentLocation!));
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: shadowColor, blurRadius: 5)],
      ),
      child: TypeAheadField<String>(
        suggestionsCallback: _getPlaceSuggestions,
        itemBuilder: (context, String suggestion) {
          return ListTile(title: Text(suggestion));
        },
        onSelected: _onPlaceSelected,
        builder: (context, controller, focusNode) {
          return TextField(
            controller: _searchController,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: "Search destination...",
              border: InputBorder.none,
              icon: Icon(Icons.search, color: primaryColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: shadowColor, blurRadius: 5)],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Pickup: $pickupAddress",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (hospitalAddress != null) ...[
              const SizedBox(height: 10),
              Text(
                "Hospital: $hospitalAddress",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (estimatedTime != null && distance != null) ...[
              const SizedBox(height: 10),
              Text("Distance: $distance"),
              Text("ETA: $estimatedTime"),
            ],
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor:
                    isAmbulanceBooked ? Colors.green : primaryColor,
              ),
              onPressed:
                  closestHospitalLocation == null || isAmbulanceBooked
                      ? null
                      : () {
                        setState(() {
                          isAmbulanceBooked = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ambulance booked successfully!'),
                          ),
                        );
                        Future.delayed(
                          Duration(
                            minutes:
                                estimatedTime != null
                                    ? int.parse(estimatedTime!.split(' ')[0])
                                    : 10,
                          ),
                          () {
                            setState(() {
                              isAmbulanceBooked = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ambulance has reached your location!',
                                ),
                              ),
                            );
                          },
                        );
                      },
              child: Text(
                isAmbulanceBooked ? "Ambulance Booked" : "Book Ambulance",
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Ambulance'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation ?? const LatLng(0, 0),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: markers,
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 10,
            left: defaultPadding,
            right: defaultPadding,
            child: _buildSearchBar(),
          ),
          Positioned(
            top: 70,
            right: defaultPadding,
            child: FloatingActionButton(
              onPressed: _recenterMap,
              backgroundColor: primaryColor,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: defaultPadding,
            left: defaultPadding,
            right: defaultPadding,
            child: _buildBottomCard(),
          ),
        ],
      ),
    );
  }
}
