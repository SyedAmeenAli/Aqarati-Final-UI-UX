import 'package:flutter/material.dart';

/// Centralized icon layer. Every screen asks for an icon by AQARATI-semantic
/// name through this class, never `Icons.*` directly for anything in this
/// list — so the whole app can move to a sourced/drawn AQARATI icon family
/// later by editing this one file, not every screen.
///
/// Currently backed by Material Symbols (outlined, thin weight) as a stand-in
/// — no custom vector set has been sourced yet. This is explicitly flagged
/// as a temporary implementation state, not a finished icon system.
class AppIcons {
  AppIcons._();

  static const IconData search = Icons.search_rounded;
  static const IconData location = Icons.location_on_outlined;
  static const IconData notification = Icons.notifications_none_rounded;
  static const IconData profile = Icons.person_outline_rounded;
  static const IconData save = Icons.favorite_border_rounded;
  static const IconData saveFilled = Icons.favorite_rounded;
  static const IconData share = Icons.ios_share_rounded;
  static const IconData map = Icons.map_outlined;
  static const IconData arrowForward = Icons.arrow_forward_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;

  static const IconData home = Icons.home_outlined;
  static const IconData homeSelected = Icons.home_rounded;
  static const IconData explore = Icons.explore_outlined;
  static const IconData exploreSelected = Icons.explore_rounded;
  static const IconData messages = Icons.forum_outlined;
  static const IconData messagesSelected = Icons.forum_rounded;

  static const IconData properties = Icons.home_work_outlined;
  static const IconData developments = Icons.apartment_rounded;
  static const IconData agents = Icons.groups_outlined;
  static const IconData construction = Icons.construction_rounded;
  static const IconData architecture = Icons.architecture_outlined;
  static const IconData design = Icons.palette_outlined;

  static const IconData star = Icons.star_rounded;
  static const IconData verified = Icons.check_circle_rounded;
  static const IconData flight = Icons.flight_takeoff_rounded;
}
