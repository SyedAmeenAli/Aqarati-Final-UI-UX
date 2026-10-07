import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App language (English LTR / Arabic RTL). Held in memory; persisting it is
/// a one-line change once the project's preference store is settled.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Always opens in light mode; dark is an explicit choice (Account > Appearance).
// QA only: `--dart-define=AQ_THEME=dark` previews the dark system; the product default is always light.
final themeModeProvider = StateProvider<ThemeMode>((ref) => const String.fromEnvironment('AQ_THEME') == 'dark' ? ThemeMode.dark : ThemeMode.light);

/// Strings for the entry + purpose screens. Arabic copy is a draft and needs
/// native review (same status as the brand site).
class EntryStrings {
  final bool ar;
  const EntryStrings._(this.ar);

  static EntryStrings of(BuildContext c) => EntryStrings._(Localizations.localeOf(c).languageCode == 'ar');

  String _t(String en, String arText) => ar ? arText : en;

  String get skip => _t('Skip', 'تخطي');
  String get skipLabel => _t('Skip onboarding', 'تخطي التعريف');
  String get back => _t('Back', 'رجوع');
  String get headlineA => _t('A Brighter\nProperty Journey', 'رحلة عقارية\nأكثر إشراقاً');
  String get headlineB => _t('in Oman', 'في عُمان');
  String get support => _t('Buy, rent, invest or find trusted professionals\n— all in one verified ecosystem.', 'اشترِ أو استأجر أو استثمر أو اعثر على مختصين موثوقين\n— كل ذلك في منظومة واحدة موثّقة.');
  String get createAccount => _t('Create an Account', 'إنشاء حساب');
  String get login => _t('Login', 'تسجيل الدخول');
  String get orContinueWith => _t('OR CONTINUE WITH', 'أو تابع باستخدام');
  String get google => _t('Continue with Google', 'المتابعة عبر Google');
  String get apple => _t('Continue with Apple', 'المتابعة عبر Apple');
  String get language => _t('English', 'العربية');
  String get selectLanguage => _t('Select language', 'اختيار اللغة');
  String get providerUnavailable => _t('This sign-in method is not connected yet.', 'طريقة تسجيل الدخول هذه غير متاحة بعد.');
  String get pageLabel => _t('Page 1 of 4', 'الصفحة 1 من 4');

  // Purpose selection
  String get step => _t('01 / 03', '01 / 03');
  String get stepLabel => _t('Step 1 of 3', 'الخطوة 1 من 3');
  String get purposeTitle => _t('What brings\nyou to AQARATI?', 'ما الذي يجمعك\nبعقاراتي؟');
  String get purposeSub => _t('Choose your main purpose to personalize\nyour experience.', 'اختر غرضك الأساسي لنخصّص\nتجربتك.');
  String get continueLabel => _t('Continue', 'متابعة');
  String continueWith(String purpose) => _t('Continue with $purpose signup', 'المتابعة إلى تسجيل $purpose');
  String get selected => _t('selected', 'محدد');
  String get notSelected => _t('not selected', 'غير محدد');
  String get navFailed => _t('Could not open that form. Please try again.', 'تعذّر فتح النموذج. حاول مرة أخرى.');
  String get retry => _t('Retry', 'إعادة المحاولة');
}
