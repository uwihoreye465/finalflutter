import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }

    return false;
  }

  static Future<bool> _isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await _isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return {
          'success': false,
          'error': 'Location services are disabled. Please enable location services.',
        };
      }

      // Check location permission
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        debugPrint('Location permission denied.');
        return {
          'success': false,
          'error': 'Location permission denied. Please grant location permission.',
        };
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      String address = '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';

      return {
        'success': true,
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'address': address,
        'location_name': '${place.locality}, ${place.administrativeArea}, ${place.country}',
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting location: $e');
      return {
        'success': false,
        'error': 'Failed to get location: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> getLocationWithFallback() async {
    try {
      // Try to get high accuracy location first
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      String address = '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';

      return {
        'success': true,
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'address': address,
        'location_name': '${place.locality}, ${place.administrativeArea}, ${place.country}',
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('High accuracy location failed, trying low accuracy: $e');
      
      try {
        // Fallback to low accuracy
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );

        return {
          'success': true,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'address': 'Location obtained (${position.accuracy.toStringAsFixed(0)}m accuracy)',
          'location_name': 'Rwanda (Development/Testing)',
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } catch (e2) {
        debugPrint('All location attempts failed: $e2');
        return {
          'success': false,
          'error': 'Unable to get location. Please check your GPS settings.',
        };
      }
    }
  }

  static Future<double> calculateDistance(
    double lat1, double lon1, double lat2, double lon2) async {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
