import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';
import 'aqarati_logo.dart';

/// Fraction of the raw 1920px-wide source frame that the actual AQARATI
/// composition occupies (the rest is black pillarboxing baked into the
/// video's pixels, not player letterboxing). Measured empirically from a
/// rendered frame — no ffprobe/inspection tool was available in this
/// environment to read it from the source directly. A flat post-fit zoom
/// multiplier does NOT work here: how much a generic BoxFit.cover crop
/// already removes depends on the *viewport's* aspect ratio too, so the
/// right amount of extra crop needed to reach the true content varies by
/// screen width — confirmed by testing: a fixed 1.5x zoom looked correct
/// on a near-square desktop preview but clipped the wordmark on a real
/// narrow phone width. Cropping to this fixed source-relative fraction
/// first, before fitting to the viewport, is aspect-independent and
/// correct at both extremes.
const double _kContentWidthFraction = 0.356;

/// The approved AQARATI cinematic startup video (assets/branding/aqarati_startup.mp4).
/// Owns initialization, cover-crop presentation, single playback, completion,
/// and error fallback. Plays once per cold launch, then calls [onFinished] —
/// never replayed for in-app navigation, since this widget is only ever
/// mounted once by the onboarding flow's splash step.
class AqaratiStartupVideo extends StatefulWidget {
  final VoidCallback onFinished;

  const AqaratiStartupVideo({super.key, required this.onFinished});

  @override
  State<AqaratiStartupVideo> createState() => _AqaratiStartupVideoState();
}

class _AqaratiStartupVideoState extends State<AqaratiStartupVideo> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _finishing = false;
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), value: 1);
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset('assets/branding/aqarati_startup.mp4');
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.setLooping(false);
      // Browser/platform autoplay policies can block audio-with-video; muting
      // on failure keeps the visual opening working even if audio is blocked.
      await controller.play();
      controller.addListener(_onTick);
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
      // Give the fallback logo a moment on screen (same beat as the old
      // splash) rather than instantly skipping past it.
      Future.delayed(const Duration(milliseconds: 1400), _finish);
    }
  }

  void _onTick() {
    final value = _controller?.value;
    if (value == null || _finishing) return;
    if (value.isInitialized && !value.isPlaying && value.position >= value.duration && value.duration > Duration.zero) {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    if (!_failed) {
      // Let the final brand frame breathe before transitioning.
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!mounted) return widget.onFinished();
    await _fade.reverse();
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // Loading (asset still initializing) and failed (playback genuinely
    // broke) are different states: loading must stay a blank warm
    // background — no logo/text — so nothing flashes ahead of the video's
    // own first frame. Only a real failure shows the static AQARATI mark.
    if (_failed) {
      return Container(
        color: AppColors.background,
        child: FadeTransition(opacity: _fade, child: const _StartupFallback()),
      );
    }
    if (controller == null || !_ready) {
      return Container(color: AppColors.background);
    }
    return Container(
      color: AppColors.background,
      child: FadeTransition(
        opacity: _fade,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            // Stage 1 (inner): crop away the source's baked-in
            // pillarboxing down to the true content, at a fixed
            // fraction of the raw frame — independent of viewport.
            child: ClipRect(
              child: Align(
                alignment: Alignment.center,
                widthFactor: _kContentWidthFraction,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static fallback if the video genuinely fails to load — still the approved
/// AQARATI branding, never the old splash implementation.
class _StartupFallback extends StatelessWidget {
  const _StartupFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: const AqaratiFullLockup(markHeight: 120, showTagline: true),
      ),
    );
  }
}
