// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:med_shakthi/src/features/checkout/data/models/address_model.dart';
import '../screens/address_store.dart';

class AddressEditSheet extends StatefulWidget {
  final AddressModel? addressToEdit;

  const AddressEditSheet({super.key, this.addressToEdit});

  @override
  State<AddressEditSheet> createState() => _AddressEditSheetState();
}

class _AddressEditSheetState extends State<AddressEditSheet> {
  GoogleMapController? mapController;
  LatLng selectedLatLng = const LatLng(28.6139, 77.2090);
  String addressText = "Locating...";
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController(
    text: "Home",
  );
  final TextEditingController _remarksController = TextEditingController();

  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    if (widget.addressToEdit != null) {
      final addr = widget.addressToEdit!;
      _searchController.text = addr.fullAddress;
      selectedLatLng = LatLng(addr.lat, addr.lng);
      addressText = addr.fullAddress;
      _titleController.text = addr.title;
      _remarksController.text = addr.remarks ?? "";
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _remarksController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _getAddress(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isEmpty) return;
      final p = placemarks.first;
      if (mounted) {
        setState(() {
          addressText =
              "${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.postalCode ?? ''}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          addressText = "Address not found";
        });
      }
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        setState(() => selectedLatLng = latLng);
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    final latLng = LatLng(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() => selectedLatLng = latLng);
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search area, street...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _searchAddress(val),
                  ),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedLatLng,
                    zoom: 17,
                  ),
                  onMapCreated: (controller) => mapController = controller,
                  onCameraMove: (position) {
                    selectedLatLng = position.target;
                    if (!_isMoving) setState(() => _isMoving = true);
                  },
                  onCameraIdle: () async {
                    setState(() => _isMoving = false);
                    setState(() => addressText = "Fetching address...");
                    await _getAddress(selectedLatLng);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 35),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(bottom: _isMoving ? 10 : 0),
                      child: const Icon(
                        Icons.location_on,
                        size: 45,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Theme.of(context).cardColor,
                    onPressed: _getCurrentLocation,
                    child: const Icon(Icons.my_location, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          // Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "LOCATION DETAILS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // Address Text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isMoving ? "Locating..." : addressText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title Field (Home/Work/Other)
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Address Title (e.g., Home, Work)",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Remarks Field
                TextField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: "Remarks / Landmark (Optional)",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (_isMoving) return;
                    if (addressText == "Locating..." ||
                        addressText == "Address not found" ||
                        addressText == "Fetching address...") {
                      return;
                    }

                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) return;

                    final newAddress = AddressModel(
                      id: widget.addressToEdit?.id ?? const Uuid().v4(),
                      userId: user.id,
                      title: _titleController.text.isNotEmpty
                          ? _titleController.text
                          : "Home",
                      fullAddress: addressText,
                      lat: selectedLatLng.latitude,
                      lng: selectedLatLng.longitude,
                      remarks: _remarksController.text,
                      isSelected: widget.addressToEdit?.isSelected ?? false,
                    );

                    if (!mounted) return;

                    bool success = false;
                    if (widget.addressToEdit != null) {
                      success = await context
                          .read<AddressStore>()
                          .updateAddress(newAddress);
                    } else {
                      success = await context.read<AddressStore>().addAddress(
                        newAddress,
                      );
                    }

                    if (!mounted) return;
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to save address")),
                      );
                    }
                  },
                  child: const Text(
                    "SAVE ADDRESS",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
