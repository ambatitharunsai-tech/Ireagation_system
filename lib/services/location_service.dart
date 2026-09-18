import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String locationName;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });
}

class LocationService {
  Future<LocationData?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null; // Location unavailable
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null; // Permission denied
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null; // Permanently denied
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 1000,
        ),
      );

      String name = 'Unknown Location';
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          if (place.locality != null && place.locality!.isNotEmpty) {
            name = place.locality!;
          } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            name = place.subAdministrativeArea!;
          }
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: name,
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }
}
