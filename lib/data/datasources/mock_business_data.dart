import '../models/business.dart';
import '../models/enums.dart';

const _b1Gallery = [
  'assets/businesses/b1/01_Architectural_arch_detail_study.jpg',
  'assets/businesses/b1/02_Architectural_lattice_screen_cas.jpg',
  'assets/businesses/b1/03_Architectural_model_of_contempor.jpg',
  'assets/businesses/b1/05_Contemporary_architectural_facad.jpg',
  'assets/businesses/b1/06_Courtyard_architectural_design_c.jpg',
  'assets/businesses/b1/08_Doubleheight_atrium_architectur.jpg',
];

const _b2Gallery = [
  'assets/businesses/b2/05_Construction_site_with_tower_crane.jpg',
  'assets/businesses/b2/02_Concrete_structural_construction.jpg',
  'assets/businesses/b2/03_Construction_equipment_at_buildi.jpg',
  'assets/businesses/b2/04_Construction_site_structure_in_M.jpg',
  'assets/businesses/b2/01_Building_handover_residential_ar.jpg',
];

const _b3Gallery = [
  'assets/businesses/b3/01_Modern_designer_bathroom_interio.jpg',
  'assets/businesses/b3/02_Modern_designer_bathroom_interio.jpg',
  'assets/businesses/b3/03_Powder_room_interior_photography.jpg',
  'assets/businesses/b3/04_Reading_and_work_nook.jpg',
  'assets/businesses/b3/05_Secondary_bathroom_interior_design.jpg',
  'assets/businesses/b3/06_Styled_bedroom_interior_photography.jpg',
];

const _b4Gallery = [
  'assets/businesses/b4/01_Garden_maintenance_hedge_trimmin.jpg',
  'assets/businesses/b4/02_Home_maintenance_servicing_resid.jpg',
  'assets/businesses/b4/03_Plumbing_maintenance_under_sink.jpg',
  'assets/businesses/b4/04_Technician_maintaining_electrica.jpg',
  'assets/businesses/b4/05_Technician_servicing_air_conditi.jpg',
  'assets/businesses/b4/06_Worker_painting_interior_wall.jpg',
];

/// Fictional demo businesses. Never real companies, awards, or certifications.
final List<Business> mockBusinesses = [
  const Business(
    id: 'b1',
    name: 'Wadi Architecture',
    categories: [BusinessCategory.architecture],
    locationLabel: 'Muscat, Oman',
    description: 'Residential architecture focused on practical, climate-conscious homes.',
    verification: BusinessVerification(status: VerificationStatus.verified),
    serviceArea: 'Muscat governorate',
    galleryUrls: _b1Gallery,
    rating: 4.9,
    reviewCount: 42,
  ),
  const Business(
    id: 'b2',
    name: 'Namaa Construction',
    categories: [BusinessCategory.construction, BusinessCategory.propertyDevelopment],
    locationLabel: 'Muscat, Oman',
    description: 'Construction and development company delivering residential and '
        'commercial projects across Muscat.',
    verification: BusinessVerification(status: VerificationStatus.verified),
    serviceArea: 'Muscat, Sohar',
    galleryUrls: _b2Gallery,
    rating: 4.8,
    reviewCount: 65,
  ),
  const Business(
    id: 'b3',
    name: 'Maysan Design Studio',
    categories: [BusinessCategory.interiorDesign, BusinessCategory.exteriorDesign],
    locationLabel: 'Muscat, Oman',
    description: 'Interior and exterior design studio working with homeowners on '
        'considered, livable spaces.',
    verification: BusinessVerification(status: VerificationStatus.underReview),
    serviceArea: 'Muscat governorate',
    galleryUrls: _b3Gallery,
    rating: 4.9,
    reviewCount: 27,
  ),
  const Business(
    id: 'b4',
    name: 'Rawaq Maintenance Services',
    categories: [BusinessCategory.maintenance],
    locationLabel: 'Muscat, Oman',
    description: 'Home maintenance covering AC, plumbing, electrical and general repairs.',
    verification: BusinessVerification(status: VerificationStatus.verified),
    serviceArea: 'Muscat, Bawshar, Seeb',
    galleryUrls: _b4Gallery,
    rating: 4.7,
    reviewCount: 118,
  ),
];
