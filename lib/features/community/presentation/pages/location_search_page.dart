import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/app_logger.dart';

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({Key? key}) : super(key: key);

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isSearching = false;
  LatLng _currentLocation = const LatLng(23.8103, 90.4125); // Default: Dhaka

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      AppLogger.info('Getting current location', tag: 'LOCATION_SEARCH');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = latLng;
          _selectedLocation = latLng;
        });
        _getAddressFromLocation(latLng);
      }
    } catch (e) {
      AppLogger.warning('Error getting location', tag: 'LOCATION_SEARCH');
      if (mounted) {
        setState(() {
          _selectedLocation = _currentLocation;
        });
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      AppLogger.info('Searching location: $query', tag: 'LOCATION_SEARCH');
      final locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _selectedLocation = latLng;
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
        
        _getAddressFromLocation(latLng);
      }
    } catch (e) {
      AppLogger.warning('Location not found: $query', tag: 'LOCATION_SEARCH');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location not found: $query')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = '${place.street}, ${place.locality}, ${place.country}';
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      AppLogger.warning('Error getting address', tag: 'LOCATION_SEARCH');
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(location),
    );
    _getAddressFromLocation(location);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      context.pop({
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedAddress ?? 'Selected Location',
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search location (e.g., Dhaka, Gulshan)',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.backgroundWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radius12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _searchLocation,
                ),
                if (_selectedAddress != null) ...[
                  const SizedBox(height: AppDimensions.margin8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: AppDimensions.margin8),
                      Expanded(
                        child: Text(
                          _selectedAddress!,
                          style: TextStyle(
                            fontSize: AppFonts.fontSize14,
                            color: isDark ? AppColors.textWhite : AppColors.textBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTap,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedLocation!,
                            draggable: true,
                            onDragEnd: (newPosition) {
                              setState(() {
                                _selectedLocation = newPosition;
                              });
                              _getAddressFromLocation(newPosition);
                            },
                          ),
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                ),

                // Center indicator
                Center(
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: AppButton(
              text: 'Confirm Location',
              onPressed: _selectedLocation != null ? _confirmLocation : null,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

