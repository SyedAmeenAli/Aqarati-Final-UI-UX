import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../brand/brand_tokens.dart';
import 'aqarati_intro_preferences.dart';
import 'intro_state.dart';
import 'logo_handoff.dart';

const _kFilm = 'assets/branding/aqarati_intro.mp4';
const _kPoster = 'assets/branding/aqarati_intro_poster.jpg';
const _kHold = Duration(milliseconds: 200);
const _kHandoff = Duration(milliseconds: 700);

/// Mounts the app (already routed) and, on first install only, lays the
/// 10 s brand film over it. The app shell is never blocked: routing, session
/// restore and guards run underneath while the film plays.
class IntroHost extends ConsumerStatefulWidget {
  final Widget child;
  final AqaratiIntroPreferences prefs;

  IntroHost({super.key, required this.child, AqaratiIntroPreferences? prefs}) : prefs = prefs ?? AqaratiIntroPreferences();

  @override
  ConsumerState<IntroHost> createState() => _IntroHostState();
}

class _IntroHostState extends ConsumerState<IntroHost> {
  bool _decided = false;

  @override
  void initState() {
    super.initState();
    widget.prefs.hasCompletedIntro().then((done) {
      if (!mounted) return;
      ref.read(introStateProvider.notifier).state = done ? IntroState.completed : IntroState.required;
      setState(() => _decided = true);
    });
  }

  /// [persist] is true ONLY for a finished film or the reduced-motion bypass.
  Future<void> _complete({required bool persist}) async {
    if (persist) await widget.prefs.markIntroCompleted();
    if (mounted) ref.read(introStateProvider.notifier).state = IntroState.completed;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(introStateProvider);
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_decided)
          const ColoredBox(color: BrandColors.introIvory)
        else if (state == IntroState.required || state == IntroState.revealing)
          Positioned.fill(
            child: _IntroFilm(
              reducedMotion: reduced,
              onReveal: () => ref.read(introStateProvider.notifier).state = IntroState.revealing,
              onDone: (persist) => _complete(persist: persist),
            ),
          ),
      ],
    );
  }
}

class _IntroFilm extends StatefulWidget {
  final bool reducedMotion;
  final VoidCallback onReveal;
  final void Function(bool persist) onDone;
  const _IntroFilm({required this.reducedMotion, required this.onReveal, required this.onDone});

  @override
  State<_IntroFilm> createState() => _IntroFilmState();
}

class _IntroFilmState extends State<_IntroFilm> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  VideoPlayerController? _video;
  late final AnimationController _move;
  bool _finishing = false;
  bool _failed = false;
  bool _firstFrame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _move = AnimationController(vsync: this, duration: _kHandoff);
    if (widget.reducedMotion) {
      // Deliberate accessibility bypass: no film, short fade, counts as complete.
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish(persist: true, hold: Duration.zero));
    } else {
      _start();
    }
  }

  Future<void> _start() async {
    final c = VideoPlayerController.asset(_kFilm, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    _video = c;
    try {
      await c.initialize();
      if (!mounted) return;
      await c.setVolume(0); // the brand film is silent by design
      await c.setLooping(false);
      c.addListener(_tick);
      await c.play();
      setState(() {});
    } catch (e) {
      debugPrint('AQARATI intro playback failed: $e');
      _fail();
    }
  }

  /// Playback broke: show the poster, move on, never persist.
  void _fail() {
    if (!mounted || _finishing) return;
    setState(() => _failed = true);
    _finish(persist: false, hold: const Duration(milliseconds: 900));
  }

  void _tick() {
    final v = _video?.value;
    if (v == null || _finishing) return;
    if (!_firstFrame && v.position > Duration.zero) setState(() => _firstFrame = true);
    if (v.hasError) {
      debugPrint('AQARATI intro error: ${v.errorDescription}');
      _fail();
      return;
    }
    // Ended: position reached the duration (final frame is on screen).
    if (v.isInitialized && v.duration > Duration.zero && (v.isCompleted || v.position >= v.duration - const Duration(milliseconds: 120))) {
      _finish(persist: true, hold: _kHold);
    }
  }

  Future<void> _finish({required bool persist, required Duration hold}) async {
    if (_finishing) return;
    _finishing = true;
    if (hold > Duration.zero) await Future<void>.delayed(hold);
    if (!mounted) return;
    widget.onReveal();
    final simple = widget.reducedMotion || _failed;
    await _move.animateTo(1, duration: simple ? const Duration(milliseconds: 220) : _kHandoff);
    if (!mounted) return;
    widget.onDone(persist);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final v = _video;
    if (v == null || !v.value.isInitialized || _finishing) return;
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
      v.pause();
    } else if (s == AppLifecycleState.resumed) {
      v.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.removeListener(_tick);
    _video?.dispose();
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _video;
    final ready = v != null && v.value.isInitialized && !_failed;
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final geo = LogoHandoff.compute(mq);
    final simple = widget.reducedMotion || _failed;

    final film = Stack(
      fit: StackFit.expand,
      children: [
        // Frame 0 as a still: instant, and the fallback if playback fails.
        Image.asset(_kPoster, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => const SizedBox.shrink()),
        if (ready)
          Opacity(
            opacity: _firstFrame ? 1 : 0,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: v.value.size.width, height: v.value.size.height, child: VideoPlayer(v)),
            ),
          ),
      ],
    );

    return Semantics(
      label: 'AQARATI',
      child: AnimatedBuilder(
        animation: _move,
        child: film,
        builder: (context, film) {
          final t = Curves.easeInOutCubic.transform(_move.value);
          // Fade starts once the mark is most of the way home.
          final fade = simple ? t : Curves.easeOut.transform(((_move.value - 0.55) / 0.45).clamp(0.0, 1.0));
          final scale = simple ? 1.0 : 1 + (geo.scaleFor(size) - 1) * t;
          final shift = simple ? Offset.zero : geo.shiftFor(size) * t;
          final pivot = geo.videoLogoCenter(size);
          return Opacity(
            opacity: 1 - fade,
            child: ColoredBox(
              color: BrandColors.introIvory,
              child: Transform.translate(
                offset: shift,
                child: Transform(
                  alignment: Alignment((pivot.dx / size.width) * 2 - 1, (pivot.dy / size.height) * 2 - 1),
                  transform: Matrix4.diagonal3Values(scale, scale, 1),
                  child: SizedBox(width: size.width, height: math.max(size.height, 1), child: film),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
