import 'package:flutter_riverpod/flutter_riverpod.dart';

/// unknown: still reading the flag · required: film will play ·
/// revealing: film is crossfading out · completed: no overlay.
enum IntroState { unknown, required, revealing, completed }

final introStateProvider = StateProvider<IntroState>((ref) => IntroState.unknown);

/// Screens beneath the overlay reveal their content once the film starts
/// handing over (or immediately when there is no film).
bool introAllowsReveal(IntroState s) => s == IntroState.revealing || s == IntroState.completed;
