import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LocationPermission? _permission;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    Position? pos;
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (e) {
        // Fallback or ignore
      }
    }

    setState(() {
      _permission = permission;
      _currentPosition = pos;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasPermission = _permission == LocationPermission.always || _permission == LocationPermission.whileInUse;

    return Scaffold(
      body: Stack(
        children: [
          // Full Screen Map Placeholder
          Container(
            height: double.infinity,
            width: double.infinity,
             decoration: BoxDecoration(
              color: Colors.grey[200],
              image: hasPermission && _currentPosition != null ? DecorationImage(
                image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=${_currentPosition!.latitude},${_currentPosition!.longitude}&zoom=13&size=800x1200&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}'),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: hasPermission 
              ? Container(color: Colors.black.withValues(alpha: 0.1)) // Overlay
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Location permission not given',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _checkPermission,
                        child: const Text('Grant Permission'),
                      ),
                    ],
                  ),
                ),
          ),
          
          // Search Bar Overlay
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search area...',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ),
                  const Icon(Icons.filter_list, color: AppColors.primaryLight),
                ],
              ),
            ),
          ),

          // Bottom Sheet Preview (Mock)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning, color: AppColors.accentLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Structure Fire nearby',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '0.2 km away • Emergency',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
