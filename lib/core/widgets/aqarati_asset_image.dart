import 'package:flutter/material.dart';

/// Decodes the asset at roughly its rendered size (× device pixel ratio)
/// instead of full source resolution — the source photography is ~1200px+,
/// showing it in an 80px thumbnail without `cacheWidth` decodes and holds
/// the full image in memory for nothing. Detail/gallery contexts that want
/// full resolution simply omit `displayWidth`.
class AqaratiAssetImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? displayWidth;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AqaratiAssetImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.displayWidth,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cacheWidth = displayWidth == null
        ? null
        : (displayWidth! * MediaQuery.of(context).devicePixelRatio).round();
    return Image.asset(
      path,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: errorBuilder,
    );
  }
}
