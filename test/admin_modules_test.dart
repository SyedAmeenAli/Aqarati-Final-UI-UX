import 'package:aqarati_app/admin/admin_directory.dart';
import 'package:aqarati_app/admin/admin_modules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every module has records, and every record status is one the module defines', () {
    final seed = seedModules();
    for (final k in ModKey.values) {
      final def = kModules[k]!;
      expect(seed[k], isNotEmpty, reason: '${k.name} has sample records');
      for (final r in seed[k]!) {
        expect(def.statuses, contains(r.status), reason: '${k.name}/${r.id}');
        for (final a in def.actions[r.status] ?? const <ModAction>[]) {
          expect(def.statuses, contains(a.target), reason: '${k.name} action ${a.label}');
        }
      }
      expect(def.route, '/m/${k.name}');
    }
  });

  test('search and status filters narrow a list', () {
    final l = seedModules()[ModKey.listings]!;
    expect(filterModule(l).length, l.length);
    expect(filterModule(l, query: 'salalah').map((r) => r.id), ['L2']);
    expect(filterModule(l, status: 'Removed').map((r) => r.id), ['L5']);
    expect(filterModule(l, query: 'zzz'), isEmpty);
  });

  test('a status change updates only that record and is written to the activity log', () {
    final logs = <String>[];
    final n = AdminModulesNotifier((a, t, g) => logs.add('$a|$t|$g'));
    final before = n.state[ModKey.projects]!;
    n.setStatus(ModKey.projects, 'P2', 'Published', 'Demo Reviewer');
    final after = n.state[ModKey.projects]!;
    expect(after.firstWhere((r) => r.id == 'P2').status, 'Published');
    for (final r in after.where((r) => r.id != 'P2')) {
      expect(r.status, before.firstWhere((x) => x.id == r.id).status);
    }
    expect(n.state[ModKey.listings], seedModules()[ModKey.listings], reason: 'other modules untouched');
    expect(logs.single, contains('Qurum Heights'));
    n.setStatus(ModKey.projects, 'P2', 'Published', 'Demo Reviewer');
    expect(logs, hasLength(1), reason: 'no change, no log line');
  });

  test('a new announcement starts as a draft and can be sent (sample)', () {
    final n = AdminModulesNotifier((a, t, g) {});
    n.addAnnouncement('Maintenance window', 'All customers', 'Sample', 'Demo Reviewer');
    final a = n.state[ModKey.announcements]!.first;
    expect(a.status, 'Draft');
    n.setStatus(ModKey.announcements, a.id, 'Sent (sample)', 'Demo Reviewer');
    expect(n.record(ModKey.announcements, a.id)!.status, 'Sent (sample)');
  });

  test('the shared activity log accepts lines from other stores', () {
    final d = AdminDirectory(DateTime(2026, 10, 29));
    final n = d.state.audit.length;
    d.record('Demo Reviewer', 'Approved listing (e-Broker)', 'Sea villa');
    expect(d.state.audit.length, n + 1);
    expect(d.state.audit.first.target, 'Sea villa');
  });
}
