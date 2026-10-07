import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/maps_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'aqarati_map_view_stub.dart' if (dart.library.js_interop) 'aqarati_map_view_web.dart' as web_map;

/// Single reusable Google Map surface for the whole app (Home "Near you"
/// preview, full Map screen, and any future property-detail map). Callers
/// supply markers/camera; this widget owns only the map itself.
///
/// Web renders a real, live Google Map via the classic keyless
/// `output=embed` iframe (no API key/billing needed, same mechanism as
/// Google's own "Share > Embed a map"). Native Android/iOS render the real
/// `GoogleMap` widget when [kGoogleMapsConfigured] is set for a real key, or
/// a clean unavailable state otherwise — never a painted/fake map.
class AqaratiMapView extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final Set<Marker> markers;
  final bool interactive;
  final BorderRadius? borderRadius;
  final ValueChanged<GoogleMapController>? onMapCreated;
  final VoidCallback? onCameraMove;
  final VoidCallback? onCameraIdle;

  const AqaratiMapView({
    super.key,
    required this.initialCenter,
    this.initialZoom = 12,
    this.markers = const {},
    this.interactive = true,
    this.borderRadius,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
  });

  @override
  State<AqaratiMapView> createState() => _AqaratiMapViewState();
}

class _AqaratiMapViewState extends State<AqaratiMapView> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.md);

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: radius,
        child: web_map.buildWebEmbedMap(
          lat: widget.initialCenter.latitude,
          lng: widget.initialCenter.longitude,
          zoom: widget.initialZoom,
          interactive: widget.interactive,
        ),
      );
    }

    if (!kGoogleMapsConfigured) {
      return ClipRRect(borderRadius: radius, child: const _MapUnavailableView());
    }

    return ClipRRect(
      borderRadius: radius,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: widget.initialCenter, zoom: widget.initialZoom),
        markers: widget.markers,
        onMapCreated: (controller) {
          _controller = controller;
          widget.onMapCreated?.call(controller);
        },
        onCameraMove: (_) => widget.onCameraMove?.call(),
        onCameraIdle: widget.onCameraIdle,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        rotateGesturesEnabled: widget.interactive,
        scrollGesturesEnabled: widget.interactive,
        tiltGesturesEnabled: widget.interactive,
        zoomGesturesEnabled: widget.interactive,
        liteModeEnabled: !widget.interactive,
      ),
    );
  }

  Future<void> animateTo(LatLng target, {double zoom = 14}) async {
    await _controller?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Shown wherever a map surface would render but no Google Maps API key is
/// configured for this platform/build — never a painted/fake map standing
/// in for live data.
class _MapUnavailableView extends StatelessWidget {
  const _MapUnavailableView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sand,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, color: AppColors.mist, size: 28),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Map unavailable',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.charcoal),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Google Maps configuration is required for this environment.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.mist),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
