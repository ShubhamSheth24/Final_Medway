import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/services.dart';

const String googleApiKey =
    "AIzaSyCGqVA17yZNyfoDIcowXcI6wBx8BP7fdOg";

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
