import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which door the person walked in through on the entry screen. It only chooses which
/// sign-in or sign-up journey opens first and what the screens say. It is never permission:
/// after authentication the account's own role and verification state decide the destination.
enum EntryExperience { user, agent }

extension EntryExperienceX on EntryExperience {
  String get signupRoute => switch (this) {
    EntryExperience.user => '/signup/user',
    EntryExperience.agent => '/signup/agent',
  };
  String get loginRoute => '/login?as=$name';
}

EntryExperience? entryExperienceFrom(String? v) => switch (v) {
  'user' => EntryExperience.user,
  'agent' => EntryExperience.agent,
  _ => null,
};

final entryExperienceProvider = StateProvider<EntryExperience>(
  (_) => EntryExperience.user,
);
