import 'package:flutter/material.dart';
import '../brand/brand_tokens.dart';

/// Geometry shared by the startup film and the entry screen so the film's
/// final logo travels onto the entry logo (same mark, same aspect ratio).
class LogoHandoff {
  /// Logo artwork bounds measured in the film's last frame (1080x1920).
  static const double _srcCx = 566, _srcCy = 896, _srcW = 596;
  /// The master SVG's artwork fills ~97.5% of its 440-wide viewBox.
  static const double _artFill = 0.975;
  static const double _svgAspect = 484 / 440;

  final double entryLogoWidth;
  final double entryCx;
  final double entryCy;
  const LogoHandoff._(this.entryLogoWidth, this.entryCx, this.entryCy);

  /// Width of the entry logo for a given screen (also used by the entry layout).
  static double entryWidth(double screenW, double screenH) {
    final cw = screenW.clamp(0, BrandSpace.maxContent + BrandSpace.gutter * 2).toDouble();
    return screenH < 760 ? (cw * 0.34).clamp(110.0, 230.0) : (cw * 0.42).clamp(150.0, 230.0);
  }

  /// Gap between the top bar and the logo, by available height.
  static double topGap(double bodyHeight) => bodyHeight > 700 ? BrandSpace.s2 : 0;

  static LogoHandoff compute(MediaQueryData mq) {
    final w = entryWidth(mq.size.width, mq.size.height);
    final body = mq.size.height - mq.padding.top - mq.padding.bottom;
    final top = mq.padding.top + BrandSize.tap + topGap(body);
    return LogoHandoff._(w, mq.size.width / 2, top + w * _svgAspect / 2);
  }

  double _k(Size s) => s.width / 1080 > s.height / 1920 ? s.width / 1080 : s.height / 1920;

  Offset videoLogoCenter(Size s) {
    final k = _k(s);
    return Offset(s.width / 2 + (_srcCx - 540) * k, s.height / 2 + (_srcCy - 960) * k);
  }

  double scaleFor(Size s) => (entryLogoWidth * _artFill) / (_srcW * _k(s));

  Offset shiftFor(Size s) => Offset(entryCx, entryCy) - videoLogoCenter(s);
}
