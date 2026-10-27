/// Properties hub, category and type steps, the Home module grid and the entry experiences.
/// ARABIC IS DRAFT COPY and needs native review.
const Map<String, (String, String)> hubStrings = {
  // Properties hub
  'hub.title': ('Properties', 'العقارات'),
  'hub.sub': ('What would you like to do?', 'ماذا تريد أن تفعل؟'),
  'hub.buy': ('Buy', 'شراء'),
  'hub.buy.s': ('Find a property to buy.', 'ابحث عن عقار للشراء.'),
  'hub.rent': ('Rent', 'إيجار'),
  'hub.rent.s': ('Find a property to rent.', 'ابحث عن عقار للإيجار.'),
  'hub.sell': ('Sell', 'بيع'),
  'hub.sell.s': (
    'Offer your property with Aqary e-Broker.',
    'اعرض عقارك عبر وسيط عقاري.',
  ),
  'hub.fav': ('My Favorites', 'مفضلتي'),
  'hub.fav.s': ('Properties you saved.', 'العقارات التي حفظتها.'),
  // category and type steps
  'hubcat.buy': ('Buy: choose a category', 'شراء: اختر فئة'),
  'hubcat.rent': ('Rent: choose a category', 'إيجار: اختر فئة'),
  'hubcat.sub': (
    'Pick the kind of property you are looking for.',
    'اختر نوع العقار الذي تبحث عنه.',
  ),
  'hubty.sub.buy': ('Buy: choose a property type', 'شراء: اختر نوع العقار'),
  'hubty.sub.rent': ('Rent: choose a property type', 'إيجار: اختر نوع العقار'),
  'hubty.rentNote': (
    'Only property types that can be rented are shown here.',
    'تظهر هنا أنواع العقارات القابلة للإيجار فقط.',
  ),
  'hubty.all': ('See all in this category', 'عرض كل ما في هذه الفئة'),
  // type labels used by the browse steps
  'bt.villa': ('Villa', 'فيلا'),
  'bt.apartment': ('Apartment', 'شقة'),
  'bt.residentialLand': ('Residential Land', 'أرض سكنية'),
  'bt.shop': ('Shops', 'محلات'),
  'bt.office': ('Offices', 'مكاتب'),
  'bt.commercialBuilding': ('Building', 'مبنى'),
  'bt.warehouse': ('Storage', 'مخازن'),
  'bt.commercialLand': ('Commercial Land', 'أرض تجارية'),
  'bt.investmentLand': ('Land to invest', 'أرض للاستثمار'),
  'bt.industrial': ('Factory', 'مصنع'),
  'bt.agriculturalLand': ('Agricultural Land', 'أرض زراعية'),
  'bt.farm': ('Farmhouse', 'بيت مزرعة'),
  'ptype.commercialLand': ('Commercial Land', 'أرض تجارية'),
  'ptype.investmentLand': ('Land to invest', 'أرض للاستثمار'),
  // Home module grid
  'hm6.title': ('What do you need?', 'ماذا تحتاج؟'),
  'hm6.properties': ('Properties', 'العقارات'),
  'hm6.development': ('Development', 'التطوير'),
  'hm6.interior': ('Interior & Exterior Designer', 'التصميم الداخلي والخارجي'),
  'hm6.construction': ('Construction Company', 'شركة مقاولات'),
  'hm6.loan': ('Loan Calculator', 'حاسبة القروض'),
  'hm6.maintenance': ('Maintenance', 'الصيانة'),
  // demo shortcuts and the admin link
  'demo.skip': ('Skip for Demo', 'تخطٍّ للعرض التجريبي'),
  'demo.skip.note': (
    'Demo mode: no account was created, registered or verified.',
    'وضع العرض التجريبي: لم يتم إنشاء حساب أو تسجيله أو التحقق منه.',
  ),
  'admin.link': ('Admin Console →', 'لوحة الإدارة ←'),
  'admin.na.t': ('Admin Console is separate', 'لوحة الإدارة منفصلة'),
  'admin.na.b': (
    'The Admin Console is its own application and no address is set for it in this build. To see it, run it locally (flutter run -d chrome -t lib/admin_main.dart --web-port 8081) and open http://localhost:8081, or build the customer app with --dart-define=AQARATI_ADMIN_URL=<address>. Admin sign-in and two-step checks apply as usual.',
    'لوحة الإدارة تطبيق منفصل ولم يُحدَّد لها عنوان في هذا الإصدار. لعرضها شغّلها محلياً (flutter run -d chrome -t lib/admin_main.dart --web-port 8081) ثم افتح http://localhost:8081، أو ابنِ تطبيق العملاء مع --dart-define=AQARATI_ADMIN_URL=<العنوان>. يسري تسجيل دخول المشرف والتحقق بخطوتين كالمعتاد.',
  ),
  'admin.na.ok': ('Got it', 'فهمت'),
  // entry experiences
  'xp.title': ('Continue as', 'المتابعة بصفة'),
  'xp.user': ('User to Shop', 'مستخدم للتسوّق'),
  'xp.user.s': ('Browse and use AQARATI as a buyer.', 'تصفّح واستخدم عقاراتي كمشترٍ.'),
  'xp.agent': ('Real Estate Agent', 'وسيط عقاري'),
  'xp.agent.s': ('Manage listings and leads.', 'أدر عقاراتك والعملاء المحتملين.'),
  'xp.more': ('Other businesses: create an account', 'أنشطة أخرى: أنشئ حساباً'),
  'xp.login.user': ('Signing in to User to Shop', 'تسجيل الدخول إلى مستخدم للتسوّق'),
  'xp.login.agent': ('Signing in as a Real Estate Agent', 'تسجيل الدخول كوسيط عقاري'),
  'xp.mismatch.user': (
    'This account is not a User to Shop account, so we opened the workspace it belongs to.',
    'هذا الحساب ليس حساب مستخدم للتسوّق، لذلك فتحنا مساحة العمل التي ينتمي إليها.',
  ),
  'xp.mismatch.agent': (
    'This account is not a Real Estate Agent account, so we opened the Home it belongs to.',
    'هذا الحساب ليس حساب وسيط عقاري، لذلك فتحنا الصفحة الرئيسية التي ينتمي إليها.',
  ),
};
