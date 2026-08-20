import 'package:geolocator/geolocator.dart';

/// The resolved user location plus how it was obtained.
class UserLocation {
  final double latitude;
  final double longitude;

  /// True when it came from the device GPS; false when we fell back.
  final bool precise;

  /// True when the user denied (or the OS blocked) location access.
  final bool permissionDenied;

  /// True when device location services are turned off.
  final bool serviceDisabled;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.precise = true,
    this.permissionDenied = false,
    this.serviceDisabled = false,
  });
}

/// Resolves the device location, always returning a usable coordinate.
///
/// If permission is denied, services are off, or the fix times out, it falls
/// back to a default location (near the demo stores) so the "nearby" home
/// experience still works and never errors.
class LocationService {
  // Fallback near the seeded Lahore stores (Gulberg) so a rider without GPS
  // still sees nearby jobs.
  static const _fallbackLat = 31.5204;
  static const _fallbackLng = 74.3587;

  Future<UserLocation> getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallback(serviceDisabled: true);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback(permissionDenied: true);
      }

      // Prefer a cached fix (instant); otherwise request a fresh one.
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Any failure (timeout, platform error) → usable fallback.
      return _fallback();
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  UserLocation _fallback({
    bool permissionDenied = false,
    bool serviceDisabled = false,
  }) =>
      UserLocation(
        latitude: _fallbackLat,
        longitude: _fallbackLng,
        precise: false,
        permissionDenied: permissionDenied,
        serviceDisabled: serviceDisabled,
      );
}
