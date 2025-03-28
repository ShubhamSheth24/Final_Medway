import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_pharmacy/models/user_model';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

const String googleApiKey = "AIzaSyDhXcWeIuh9yG1aQ2AKvYCDGN6bVJL1RJk";

class AmbulanceBookingScreen extends StatefulWidget {
  const AmbulanceBookingScreen({super.key});

  @override
  State<AmbulanceBookingScreen> createState() => _AmbulanceBookingScreenState();
}

class _AmbulanceBookingScreenState extends State<AmbulanceBookingScreen> {
  late GoogleMapController _mapController;
  LatLng currentLocation = const LatLng(19.0760, 72.8777); // Default: Mumbai
  LatLng? destinationLocation;
  String pickupAddress = "Fetching address...";
  String? destinationAddress;
  Set<Polyline> polylines = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("AmbulanceBookingScreen initState started");
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    print("AmbulanceBookingScreen dispose called");
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      _getUserLocation();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required!')),
        );
      }
    }
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.animateCamera(CameraUpdate.newLatLng(currentLocation));
        _fetchAddress(position.latitude, position.longitude, isPickup: true);
      });
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAddress(double lat, double lng,
      {required bool isPickup}) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Geocode Response: ${data.toString()}");
      if (data["results"].isNotEmpty) {
        setState(() {
          if (isPickup) {
            pickupAddress = data["results"][0]["formatted_address"];
          } else {
            destinationAddress = data["results"][0]["formatted_address"];
          }
        });
      } else {
        setState(() {
          if (isPickup) pickupAddress = "No address found";
          else destinationAddress = "No address found";
        });
      }
    } else {
      print("Geocode Error: ${response.statusCode} - ${response.body}");
    }
  }

  Future<List<String>> _getPlaceSuggestions(String query) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey&types=geocode";
    final response = await http.get(Uri.parse(url));

    print("Places API URL: $url");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Places API Response: ${data.toString()}");
      if (data["status"] == "OK" && data["predictions"].isNotEmpty) {
        return (data["predictions"] as List)
            .map((prediction) => prediction["description"] as String)
            .toList();
      } else {
        print("No predictions found: ${data["status"]}");
        return [];
      }
    } else {
      print("Places API Error: ${response.statusCode} - ${response.body}");
      return [];
    }
  }

  Future<void> _onPlaceSelected(String place) async {
    setState(() => _isLoading = true);
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(place)}&key=$googleApiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Geocode Place Response: ${data.toString()}");
      if (data["results"].isNotEmpty) {
        final location = data["results"][0]["geometry"]["location"];
        setState(() {
          destinationLocation = LatLng(location["lat"], location["lng"]);
          destinationAddress = place;
          _mapController.animateCamera(
              CameraUpdate.newLatLngZoom(destinationLocation!, 15));
          _fetchRoute();
        });
      }
    } else {
      print("Geocode Place Error: ${response.statusCode} - ${response.body}");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchRoute() async {
    if (destinationLocation == null) return;

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation.latitude},${currentLocation.longitude}&destination=${destinationLocation!.latitude},${destinationLocation!.longitude}&key=$googleApiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Directions API Response: ${data.toString()}");
      if (data["routes"].isNotEmpty) {
        final points = data["routes"][0]["overview_polyline"]["points"];
        final List<LatLng> polylineCoordinates = _decodePolyline(points);

        setState(() {
          polylines = {
            Polyline(
              polylineId: const PolylineId("route"),
              points: polylineCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          };
          _mapController.animateCamera(CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                currentLocation.latitude < destinationLocation!.latitude
                    ? currentLocation.latitude
                    : destinationLocation!.latitude,
                currentLocation.longitude < destinationLocation!.longitude
                    ? currentLocation.longitude
                    : destinationLocation!.longitude,
              ),
              northeast: LatLng(
                currentLocation.latitude > destinationLocation!.latitude
                    ? currentLocation.latitude
                    : destinationLocation!.latitude,
                currentLocation.longitude > destinationLocation!.longitude
                    ? currentLocation.longitude
                    : destinationLocation!.longitude,
              ),
            ),
            100,
          ));
        });
      }
    } else {
      print("Directions API Error: ${response.statusCode} - ${response.body}");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _bookAmbulance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book an ambulance')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docId = _generateDocId(user.email ?? "unknown");
      final bookingId = FirebaseFirestore.instance.collection('bookings').doc().id;

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
        'userDocId': docId,
        'pickupAddress': pickupAddress,
        'pickupLat': currentLocation.latitude,
        'pickupLng': currentLocation.longitude,
        'destinationAddress': destinationAddress,
        'destinationLat': destinationLocation!.latitude,
        'destinationLng': destinationLocation!.longitude,
        'role': Provider.of<UserModel>(context, listen: false).role ?? 'Patient',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print("Ambulance booked: Booking ID $bookingId");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ambulance booked successfully!')),
        );
        Navigator.pop(context); // Go back to HomePage
      }
    } catch (e) {
      print("Error booking ambulance: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking ambulance: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateDocId(String email) {
    return email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Book Ambulance', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: currentLocation, zoom: 15),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: {
              Marker(
                markerId: const MarkerId("currentLocation"),
                position: currentLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
              if (destinationLocation != null)
                Marker(
                  markerId: const MarkerId("destination"),
                  position: destinationLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
            },
            polylines: polylines,
            circles: {
              Circle(
                circleId: const CircleId("accuracyCircle"),
                center: currentLocation,
                radius: 100,
                fillColor: Colors.blue.withOpacity(0.2),
                strokeWidth: 1,
                strokeColor: Colors.blue,
              ),
            },
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: TypeAheadField<String>(
                suggestionsCallback: (pattern) async {
                  if (pattern.isEmpty) return [];
                  return await _getPlaceSuggestions(pattern);
                },
                itemBuilder: (context, String suggestion) {
                  return ListTile(title: Text(suggestion));
                },
                onSelected: (String suggestion) {
                  _searchController.text = suggestion;
                  _onPlaceSelected(suggestion);
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: _searchController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: "Enter destination...",
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.black54),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pickup Address",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          pickupAddress,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (destinationAddress != null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      "Destination Address",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_pin, color: Colors.red),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            destinationAddress!,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: _isLoading || destinationLocation == null
                        ? null
                        : _bookAmbulance,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Book Ambulance", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}