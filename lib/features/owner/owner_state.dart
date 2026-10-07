import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/property.dart';

final ownerListingsProvider = StateProvider<List<Property>>((ref) => []);
