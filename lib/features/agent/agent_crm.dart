import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Real Estate Agent workspace data. Everything here is a fictional, in-memory demo record:
/// there is no contacts or calendar service yet, nothing is synced and nothing leaves the device.
/// The records belong to the agent session only; the customer app never reads them.

enum LeadStatus { fresh, contacted, viewing, negotiating, won, lost }

enum NoteKind { note, call, message, viewing, status }

enum AppointmentKind { viewing, meeting, followUp }

enum AppointmentStatus { scheduled, done, cancelled }

@immutable
class ContactNote {
  final String text;
  final DateTime at;
  final NoteKind kind;
  const ContactNote(this.text, this.at, [this.kind = NoteKind.note]);
}

@immutable
class AgentContact {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String source;
  final List<String> interests;
  final String location;
  final int? budgetMin, budgetMax;
  final LeadStatus status;
  final DateTime lastInteraction;
  final DateTime? nextFollowUp;
  final List<String> listingIds;
  final List<ContactNote> notes;
  const AgentContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.source,
    required this.interests,
    required this.location,
    this.budgetMin,
    this.budgetMax,
    required this.status,
    required this.lastInteraction,
    this.nextFollowUp,
    this.listingIds = const [],
    this.notes = const [],
  });

  AgentContact copyWith({
    String? name,
    String? phone,
    String? email,
    String? source,
    List<String>? interests,
    String? location,
    int? budgetMin,
    int? budgetMax,
    LeadStatus? status,
    DateTime? lastInteraction,
    Object? nextFollowUp = _keep,
    List<ContactNote>? notes,
  }) => AgentContact(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    source: source ?? this.source,
    interests: interests ?? this.interests,
    location: location ?? this.location,
    budgetMin: budgetMin ?? this.budgetMin,
    budgetMax: budgetMax ?? this.budgetMax,
    status: status ?? this.status,
    lastInteraction: lastInteraction ?? this.lastInteraction,
    nextFollowUp: identical(nextFollowUp, _keep)
        ? this.nextFollowUp
        : nextFollowUp as DateTime?,
    listingIds: listingIds,
    notes: notes ?? this.notes,
  );

  bool followUpOverdue(DateTime now) =>
      nextFollowUp != null &&
      nextFollowUp!.isBefore(DateTime(now.year, now.month, now.day)) &&
      status != LeadStatus.won &&
      status != LeadStatus.lost;
}

const _keep = Object();

@immutable
class Appointment {
  final String id;
  final String title;
  final AppointmentKind kind;
  final DateTime at;
  final AppointmentStatus status;
  final String? contactId;
  final String? listingTitle;
  const Appointment({
    required this.id,
    required this.title,
    required this.kind,
    required this.at,
    this.status = AppointmentStatus.scheduled,
    this.contactId,
    this.listingTitle,
  });
  Appointment copyWith({DateTime? at, AppointmentStatus? status}) => Appointment(
    id: id,
    title: title,
    kind: kind,
    at: at ?? this.at,
    status: status ?? this.status,
    contactId: contactId,
    listingTitle: listingTitle,
  );
}

/// Sample listings the demo contacts relate to (titles only; the real listing screens use the
/// separate listing service).
const kDemoListingTitles = {
  'L1': '4-Bedroom Villa, Al Mouj',
  'L2': 'Two-Bedroom Apartment, Qurum',
  'L3': 'Residential Plot, Al Khoud',
  'L4': 'Retail Unit, Bawshar',
  'L5': 'Farmhouse, Nizwa',
};

class AgentCrmState {
  final List<AgentContact> contacts;
  final List<Appointment> appointments;
  const AgentCrmState(this.contacts, this.appointments);
}

DateTime _day(DateTime now, int plus, [int hour = 10, int minute = 0]) =>
    DateTime(now.year, now.month, now.day + plus, hour, minute);

AgentCrmState seedAgentCrm(DateTime now) {
  AgentContact c(
    String id,
    String name,
    String phone,
    String source,
    List<String> interests,
    String location,
    int? lo,
    int? hi,
    LeadStatus st,
    int lastDaysAgo,
    int? follow, {
    List<String> listings = const [],
    List<ContactNote> notes = const [],
  }) => AgentContact(
    id: id,
    name: name,
    phone: phone,
    email: '${name.toLowerCase().split(' ').first}@example.test',
    source: source,
    interests: interests,
    location: location,
    budgetMin: lo,
    budgetMax: hi,
    status: st,
    lastInteraction: _day(now, -lastDaysAgo, 15),
    nextFollowUp: follow == null ? null : _day(now, follow, 11),
    listingIds: listings,
    notes: notes,
  );
  final contacts = [
    c('C1', 'Layla Demo', '+968 9000 0101', 'Website enquiry', ['Villa', 'Buy'], 'Al Mouj, Muscat', 150000, 220000, LeadStatus.negotiating, 1, 1, listings: ['L1'], notes: [
      ContactNote('Asked for a second viewing with her husband.', _day(now, -1, 16), NoteKind.viewing),
      ContactNote('Budget is flexible up to 220k if the garden is large.', _day(now, -3, 12)),
    ]),
    c('C2', 'Omar Sample', '+968 9000 0102', 'Viewing request', ['Apartment', 'Rent'], 'Qurum, Muscat', 450, 700, LeadStatus.viewing, 0, 0, listings: ['L2'], notes: [
      ContactNote('Viewing booked for this afternoon.', _day(now, 0, 9), NoteKind.viewing),
    ]),
    c('C3', 'Huda Example', '+968 9000 0103', 'Referral', ['Land', 'Buy'], 'Al Khoud, Muscat', 60000, 90000, LeadStatus.contacted, 4, -2, listings: ['L3'], notes: [
      ContactNote('Left a voicemail, will try again.', _day(now, -4, 14), NoteKind.call),
    ]),
    c('C4', 'Salim Test', '+968 9000 0104', 'Aqarati app', ['Shop', 'Rent'], 'Bawshar, Muscat', 800, 1200, LeadStatus.fresh, 0, 1, listings: ['L4']),
    c('C5', 'Mariam Fictional', '+968 9000 0105', 'Walk-in', ['Farm', 'Buy'], 'Nizwa', 120000, 180000, LeadStatus.contacted, 6, -1, listings: ['L5'], notes: [
      ContactNote('Interested in the falaj water share.', _day(now, -6, 11)),
    ]),
    c('C6', 'Khalid Placeholder', '+968 9000 0106', 'Website enquiry', ['Villa', 'Rent'], 'Seeb, Muscat', 900, 1400, LeadStatus.won, 9, null, notes: [
      ContactNote('Lease signed. Thank-you note sent.', _day(now, -9, 17), NoteKind.status),
    ]),
    c('C7', 'Noor Imaginary', '+968 9000 0107', 'Referral', ['Apartment', 'Buy'], 'Al Khuwair, Muscat', 90000, 130000, LeadStatus.lost, 12, null, notes: [
      ContactNote('Bought elsewhere.', _day(now, -12, 10), NoteKind.status),
    ]),
    c('C8', 'Yusuf Mock', '+968 9000 0108', 'Aqarati app', ['Land', 'Buy'], 'Sohar', 40000, 70000, LeadStatus.fresh, 1, 2),
  ];
  final appts = [
    Appointment(id: 'A1', title: 'Viewing with Omar Sample', kind: AppointmentKind.viewing, at: now.add(const Duration(hours: 3)), contactId: 'C2', listingTitle: kDemoListingTitles['L2']),
    Appointment(id: 'A2', title: 'Second viewing with Layla Demo', kind: AppointmentKind.viewing, at: _day(now, 1, 11), contactId: 'C1', listingTitle: kDemoListingTitles['L1']),
    Appointment(id: 'A3', title: 'Call Salim Test', kind: AppointmentKind.followUp, at: _day(now, 1, 9, 30), contactId: 'C4'),
    Appointment(id: 'A4', title: 'Site meeting, Nizwa farmhouse', kind: AppointmentKind.meeting, at: _day(now, 3, 10), contactId: 'C5', listingTitle: kDemoListingTitles['L5']),
    Appointment(id: 'A5', title: 'Call Huda Example', kind: AppointmentKind.followUp, at: _day(now, -2, 11), contactId: 'C3'),
    Appointment(id: 'A6', title: 'Viewing with Khalid Placeholder', kind: AppointmentKind.viewing, at: _day(now, -10, 14), status: AppointmentStatus.done, contactId: 'C6'),
  ];
  return AgentCrmState(contacts, appts);
}

class AgentCrm extends StateNotifier<AgentCrmState> {
  AgentCrm(DateTime now) : super(seedAgentCrm(now));
  int _seq = 100;

  AgentContact? contact(String id) {
    for (final c in state.contacts) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _put(AgentContact next) => state = AgentCrmState([
    for (final c in state.contacts) c.id == next.id ? next : c,
  ], state.appointments);

  String addContact({
    required String name,
    required String phone,
    String email = '',
    String source = 'Added by you',
    List<String> interests = const [],
    String location = '',
    int? budgetMin,
    int? budgetMax,
  }) {
    final id = 'C${++_seq}';
    final now = DateTime.now();
    state = AgentCrmState([
      AgentContact(
        id: id,
        name: name,
        phone: phone,
        email: email,
        source: source,
        interests: interests,
        location: location,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        status: LeadStatus.fresh,
        lastInteraction: now,
        notes: [ContactNote('Contact added.', now, NoteKind.status)],
      ),
      ...state.contacts,
    ], state.appointments);
    return id;
  }

  void edit(String id, AgentContact Function(AgentContact c) change) {
    final c = contact(id);
    if (c != null) _put(change(c));
  }

  void addNote(String id, String text, [NoteKind kind = NoteKind.note]) {
    final c = contact(id);
    if (c == null || text.trim().isEmpty) return;
    final now = DateTime.now();
    _put(c.copyWith(
      lastInteraction: now,
      notes: [ContactNote(text.trim(), now, kind), ...c.notes],
    ));
  }

  void setStatus(String id, LeadStatus s) {
    final c = contact(id);
    if (c == null || c.status == s) return;
    final now = DateTime.now();
    _put(c.copyWith(
      status: s,
      lastInteraction: now,
      nextFollowUp: s == LeadStatus.won || s == LeadStatus.lost ? null : c.nextFollowUp,
      notes: [ContactNote('Status changed to ${s.name}.', now, NoteKind.status), ...c.notes],
    ));
  }

  /// Sets the next follow-up and adds it to the calendar (one open follow-up per contact).
  void scheduleFollowUp(String id, DateTime at) {
    final c = contact(id);
    if (c == null) return;
    final now = DateTime.now();
    _put(c.copyWith(
      nextFollowUp: at,
      notes: [ContactNote('Follow-up scheduled.', now, NoteKind.status), ...c.notes],
    ));
    state = AgentCrmState(state.contacts, [
      for (final a in state.appointments)
        if (!(a.kind == AppointmentKind.followUp && a.contactId == id && a.status == AppointmentStatus.scheduled)) a,
      Appointment(id: 'A${++_seq}', title: 'Follow up with ${c.name}', kind: AppointmentKind.followUp, at: at, contactId: id),
    ]);
  }

  void reschedule(String appointmentId, DateTime at) => state = AgentCrmState(state.contacts, [
    for (final a in state.appointments) a.id == appointmentId ? a.copyWith(at: at) : a,
  ]);

  void setAppointmentStatus(String appointmentId, AppointmentStatus s) => state = AgentCrmState(state.contacts, [
    for (final a in state.appointments) a.id == appointmentId ? a.copyWith(status: s) : a,
  ]);
}

final agentCrmProvider = StateNotifierProvider<AgentCrm, AgentCrmState>(
  (ref) => AgentCrm(DateTime.now()),
);
