import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';

/// A real OpenStreetMap map showing the store (pickup), customer (destination)
/// and rider positions with a route line between them. Uses free OSM tiles —
/// no API key required.
class DeliveryMap extends StatelessWidget {
  final LatLng? store;
  final LatLng? destination;
  final LatLng? rider;

  /// The road route (store → destination) the rider follows. When empty, a
  /// direct line between the known points is drawn as a fallback.
  final List<LatLng> route;

  const DeliveryMap({
    super.key,
    this.store,
    this.destination,
    this.rider,
    this.route = const [],
  });

  static const _lahore = LatLng(31.5204, 74.3587);

  @override
  Widget build(BuildContext context) {
    final points = <LatLng>[?store, ?destination, ?rider];
    final routePoints =
        route.length >= 2 ? route : <LatLng>[?store, ?rider, ?destination];

    final MapOptions options;
    if (points.length >= 2) {
      options = MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(60),
          maxZoom: 15,
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      );
    } else {
      options = MapOptions(
        initialCenter: points.isNotEmpty ? points.first : _lahore,
        initialZoom: points.isNotEmpty ? 14 : 12,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      );
    }

    return FlutterMap(
      options: options,
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.grocery_frontend_rider',
          maxZoom: 19,
        ),
        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (store != null)
              _pin(store!, Icons.store_rounded, AppColors.primary, 'Store'),
            if (destination != null)
              _pin(destination!, Icons.home_rounded, AppColors.error, 'You'),
            if (rider != null) _riderMarker(rider!),
          ],
        ),
      ],
    );
  }

  Marker _pin(LatLng point, IconData icon, Color color, String label) {
    return Marker(
      point: point,
      width: 80,
      height: 64,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18), blurRadius: 6),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(label,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Marker _riderMarker(LatLng point) {
    return Marker(
      point: point,
      width: 46,
      height: 46,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.delivery_dining_rounded,
            color: AppColors.white, size: 24),
      ),
    );
  }
}
