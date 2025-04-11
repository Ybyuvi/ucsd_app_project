import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_ucsd_app/constants.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _currentPosition;
  LatLng? _destination;
  BitmapDescriptor? _currentLocationIcon;

  @override
  void initState() {
    super.initState();
    _setCustomMarkerIcon();
    // Wait until the first frame is rendered and then delay a bit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkAndRequestLocationPermission();
      });
    });
  }

  Future<void> _setCustomMarkerIcon() async {
    final Uint8List markerIcon = await getBytesFromAsset('assets/location_pin.png', 100);
    setState(() {
      _currentLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45,
        title: const Text(
          "Maps",
          style: TextStyle(
            decoration: TextDecoration.none, 
          ),
        ),
      ),
      body: Stack(
        children: [
          _currentPosition == null
              ? const Center(child: Text("Loading..."))
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) =>
                      _mapController.complete(controller),
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("_currentLocation"),
                      icon: _currentLocationIcon ?? BitmapDescriptor.defaultMarker,
                      position: _currentPosition!,
                    ),
                    if (_destination != null)
                      Marker(
                        markerId: const MarkerId("_destinationLocation"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                        position: _destination!,
                      ),
                  },
                ),
          //Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            right: 15,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: _searchController,
                  googleAPIKey: googleMapsApiKey,
                  inputDecoration: InputDecoration(
                    hintText: "Search...",
                    hintStyle: TextStyle(color: const ui.Color.fromARGB(255, 255, 255, 255)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Icon(Icons.search, color: Colors.blue[700], size: 24),
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                  ),
                  textStyle: const TextStyle(color: ui.Color.fromARGB(221, 255, 255, 255), fontSize: 16),
                  debounceTime: 400,
                  isLatLngRequired: true,
                  containerHorizontalPadding: 5,
                  containerVerticalPadding: 5,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    setState(() {
                      _destination = LatLng(
                        double.parse(prediction.lat ?? "0"),
                        double.parse(prediction.lng ?? "0"),
                      );
                      _searchController.text = prediction.description ?? "";
                      _cameraToPosition(_destination!);
                    });
                  },
                  itemClick: (Prediction prediction) {
                    _searchController.text = prediction.description ?? "";
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: prediction.description?.length ?? 0),
                    );
                  },
                  itemBuilder: (context, index, Prediction prediction) {
                    return ListTile(
                      leading: Icon(Icons.location_on_outlined, color: Colors.blue[700]),
                      title: Text(prediction.description ?? "",
                          style: const TextStyle(fontSize: 16)),
                      subtitle: Text(prediction.description ?? "",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentPosition != null && _destination != null
          ? FloatingActionButton.extended(
              onPressed: _openInGoogleMaps,
              label: const Text("Open in Google Maps"),
              icon: const Icon(Icons.directions),
              backgroundColor: Colors.blue[700],
            )
          : null,
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(target: pos, zoom: 15);
    await controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }

  Future<void> _checkAndRequestLocationPermission() async {
    // Check if location service is enabled
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location service not enabled. Requesting...");
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        debugPrint("Location service is still disabled.");
        return;
      }
    }

    // Check permission status
    PermissionStatus permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      debugPrint("Location permission denied. Requesting permission...");
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        debugPrint("Location permission not granted.");
        return;
      }
    }
    if (permissionGranted == PermissionStatus.deniedForever) {
      debugPrint("Location permission permanently denied. Please enable it from settings.");
      return;
    }

    debugPrint("Location permission granted, starting location updates.");
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentPosition = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
        _cameraToPosition(_currentPosition!);
        debugPrint("Current location updated: $_currentPosition");
      }
    });
  }

  void _openInGoogleMaps() async {
    if (_currentPosition == null || _destination == null) return;

    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${_destination!.latitude},${_destination!.longitude}&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps.")),
      );
    }
  }
}
