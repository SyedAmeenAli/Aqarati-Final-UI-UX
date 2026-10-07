import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqarati_app/core/startup/aqarati_intro_preferences.dart';

void main() {
  test('intro is required on a fresh install and only completed after markIntroCompleted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = AqaratiIntroPreferences();
    expect(await prefs.hasCompletedIntro(), isFalse);
    await prefs.markIntroCompleted();
    expect(await prefs.hasCompletedIntro(), isTrue);
  });
}
