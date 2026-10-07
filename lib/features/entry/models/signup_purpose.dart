import '../../../core/localization/entry_strings.dart';

/// The six public sign-up paths (source of truth: product architecture).
/// Maintenance providers are admin-invited and AqaratiBroker is a programme,
/// so neither is a public path and neither appears here.
enum SignupPurpose { userToShop, realEstateAgent, constructionCompany, propertyDevelopmentCompany, buildingArchitecture, interiorExteriorDesign }

class SignupPurposeOption {
  final SignupPurpose id;
  /// Name in the AQARATI icon family (assets/icons/aq).
  final String icon;
  final String route;
  const SignupPurposeOption(this.id, this.icon, this.route);

  String title(EntryStrings s) => _copy[id]![s.ar ? 2 : 0];
  String description(EntryStrings s) => _copy[id]![s.ar ? 3 : 1];
  /// One supportive line shown when the role is chosen and at the start of its form.
  String tagline(EntryStrings s) => _tagline[id]![s.ar ? 1 : 0];
}

const signupPurposeOptions = <SignupPurposeOption>[
  SignupPurposeOption(SignupPurpose.userToShop, 'home', '/signup/user'),
  SignupPurposeOption(SignupPurpose.realEstateAgent, 'agent', '/signup/agent'),
  SignupPurposeOption(SignupPurpose.constructionCompany, 'construction', '/signup/construction'),
  SignupPurposeOption(SignupPurpose.propertyDevelopmentCompany, 'development', '/signup/development'),
  SignupPurposeOption(SignupPurpose.buildingArchitecture, 'architecture', '/signup/architecture'),
  SignupPurposeOption(SignupPurpose.interiorExteriorDesign, 'interior', '/signup/interior-exterior'),
];

// en title, en description, ar title, ar description (Arabic is a draft and needs native review)
const Map<SignupPurpose, List<String>> _copy = {
  SignupPurpose.userToShop: ['User to Shop', 'Browse, discover and use AQARATI as a buyer.', 'مستخدم للتسوّق', 'تصفّح واكتشف واستخدم عقاراتي كمشترٍ.'],
  SignupPurpose.realEstateAgent: ['Real Estate Agent', 'Join AQARATI as a licensed real estate agent.', 'وسيط عقاري', 'انضم إلى عقاراتي كوسيط عقاري مرخّص.'],
  SignupPurpose.constructionCompany: ['Construction Company', 'Register your construction business on AQARATI.', 'شركة مقاولات', 'سجّل شركة المقاولات الخاصة بك في عقاراتي.'],
  SignupPurpose.propertyDevelopmentCompany: ['Property Development Company', 'Present your development company and projects.', 'شركة تطوير عقاري', 'اعرض شركتك التطويرية ومشاريعك.'],
  SignupPurpose.buildingArchitecture: ['Building Architecture', 'Register your architecture practice on AQARATI.', 'العمارة والتصميم الإنشائي', 'سجّل مكتبك الهندسي المعماري في عقاراتي.'],
  SignupPurpose.interiorExteriorDesign: ['Interior & Exterior Design', 'Register your interior and exterior design practice.', 'التصميم الداخلي والخارجي', 'سجّل مكتب التصميم الداخلي والخارجي الخاص بك.'],
};

// en, ar (Arabic is a draft and needs native review)
const Map<SignupPurpose, List<String>> _tagline = {
  SignupPurpose.userToShop: ['Find your place in Oman.', 'اعثر على مكانك في عُمان.'],
  SignupPurpose.realEstateAgent: ['Build trust around every property you represent.', 'ابنِ الثقة حول كل عقار تمثّله.'],
  SignupPurpose.constructionCompany: ['Put your company where Oman builds.', 'ضع شركتك حيث تبني عُمان.'],
  SignupPurpose.propertyDevelopmentCompany: ['Bring your developments into a trusted property ecosystem.', 'اجعل مشاريعك جزءًا من منظومة عقارية موثوقة.'],
  SignupPurpose.buildingArchitecture: ['Let your practice be discovered.', 'دع مكتبك يُكتشف.'],
  SignupPurpose.interiorExteriorDesign: ['Show the work behind the spaces.', 'اعرض العمل وراء المساحات.'],
};
