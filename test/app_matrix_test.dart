import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/features/account/delete_account_screen.dart';
import 'package:aqarati_app/features/activity/activity_screen.dart';
import 'package:aqarati_app/features/maintenance/maintenance_screens.dart';
import 'package:aqarati_app/features/notifications/notifications.dart';
import 'package:aqarati_app/features/business/aq_business_profile.dart';
import 'package:aqarati_app/features/business/aq_professionals.dart';
import 'package:aqarati_app/features/calculators/calculator_models.dart';
import 'package:aqarati_app/features/calculators/calculator_screen.dart';
import 'package:aqarati_app/features/calculators/calculators_list_screen.dart';
import 'package:aqarati_app/features/devbuild/db_discovery.dart';
import 'package:aqarati_app/features/flow/screens/auth_screens.dart';
import 'package:aqarati_app/features/flow/screens/legal_screens.dart';
import 'package:aqarati_app/features/property/property_detail_screen.dart';
import 'package:aqarati_app/features/saved/saved_screen.dart';
import 'package:aqarati_app/features/search/aq_map.dart';
import 'package:aqarati_app/features/search/aq_property_types.dart';
import 'package:aqarati_app/features/search/aq_search.dart';
import 'package:aqarati_app/features/viewing/screens/my_viewings_screen.dart';
import 'package:aqarati_app/features/viewing/screens/viewing_schedule_screens.dart';
import 'package:aqarati_app/features/workspace/aq_app_shell.dart' show AccountTab;
import 'package:aqarati_app/features/workspace/aq_explore.dart';
import 'package:aqarati_app/features/workspace/aq_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whole-app layout matrix: every main screen at narrow widths, in dark, in Arabic RTL and at 200%
/// text. Release builds do not paint overflow stripes, so this is where overflow is caught.
/// (Role homes, signup, the project wizard and workspace screens have their own matrices.)

typedef _Build = Widget Function();

final _screens = <String, _Build>{
  'Home': () => const AQHomeScreen(),
  'Explore': () => const AQExploreScreen(),
  'Activity (viewings)': () => const MyViewingsScreen(),
  'Activity (switch)': () => const ActivityScreen(),
  'Maintenance request': () => const MaintenanceBookScreen(providerId: 'b4'),
  'Maintenance request detail': () => const MaintenanceDetailScreen(id: 'none'),
  'Notifications': () => const NotificationsScreen(),
  'Delete account': () => const DeleteAccountScreen(),
  'Account': () => const AccountTab(),
  'Search start': () => const SearchScreen(),
  'Search results': () => const SearchResultsScreen(initialQuery: 'villa'),
  'Property types': () => const AQPropertyTypesScreen(),
  'Properties (residential)': () => const AQPropertiesScreen(category: 'residential'),
  'Map': () => const AQMapScreen(),
  'Saved': () => const SavedScreen(),
  'Property detail': () => const PropertyDetailScreen(propertyId: 'p1'),
  'Viewing: availability': () => const ViewingAvailabilityScreen(propertyId: 'p1'),
  'Viewing: slot': () => const ViewingSlotScreen(propertyId: 'p1'),
  'Calculators': () => const CalculatorsListScreen(),
  'Calculator: loan': () => const CalculatorScreen(type: CalculatorType.emi),
  'Professionals': () => const AQProfessionalsScreen(),
  'Business profile': () => const AQBusinessProfileScreen(businessId: 'b1'),
  'Development & Building home': () => const DbHomeScreen(),
  'Login': () => const LoginScreen(),
  'Forgot password': () => const ForgotPasswordScreen(),
  'Terms': () => const LegalScreen(kind: LegalKind.terms),
};

class _Cfg {
  final String name;
  final double width, height, scale;
  final bool dark, rtl;
  const _Cfg(this.name, this.width, this.height, {this.scale = 1, this.dark = false, this.rtl = false});
}

const _configs = [
  _Cfg('320 light', 320, 700),
  _Cfg('320 dark', 320, 700, dark: true),
  _Cfg('360 Arabic RTL', 360, 740, rtl: true),
  _Cfg('393 at 200% text', 393, 852, scale: 2.0),
  _Cfg('430 dark Arabic RTL', 430, 900, dark: true, rtl: true),
];

Widget _app(Widget child, _Cfg c) => ProviderScope(
      overrides: [meProvider.overrideWith((ref) async => throw const ApiException(ApiErrorCode.network))],
      child: MaterialApp(
        theme: ThemeData(brightness: c.dark ? Brightness.dark : Brightness.light),
        locale: Locale(c.rtl ? 'ar' : 'en'),
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: MediaQuery(data: MediaQueryData(size: Size(c.width, c.height), textScaler: TextScaler.linear(c.scale)), child: Scaffold(body: child)),
      ),
    );

void main() {
  for (final cfg in _configs) {
    group('layout ${cfg.name}', () {
      for (final e in _screens.entries) {
        testWidgets(e.key, (t) async {
          await t.binding.setSurfaceSize(Size(cfg.width, cfg.height));
          addTearDown(() => t.binding.setSurfaceSize(null));
          await t.pumpWidget(_app(e.value(), cfg));
          for (var i = 0; i < 6; i++) {
            await t.pump(const Duration(milliseconds: 300));
          }
          expect(t.takeException(), isNull);
        });
      }
    });
  }
}
