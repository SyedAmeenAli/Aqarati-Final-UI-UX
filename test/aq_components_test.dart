import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqarati_app/core/aq/aq_forms.dart';
import 'package:aqarati_app/core/aq/aq_primitives.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));

void main() {
  testWidgets('primary button: disabled has no tap, enabled fires once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(AQPrimaryButton(label: 'Go', onPressed: null)));
    await tester.tap(find.text('Go'));
    expect(taps, 0);
    await tester.pumpWidget(_host(AQPrimaryButton(label: 'Go', onPressed: () => taps++)));
    await tester.tap(find.text('Go'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
  });

  testWidgets('primary button: loading blocks taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(AQPrimaryButton(label: 'Go', loading: true, onPressed: () => taps++)));
    await tester.tap(find.byType(AQPrimaryButton));
    expect(taps, 0);
  });

  testWidgets('text field shows its error message', (tester) async {
    final c = TextEditingController();
    await tester.pumpWidget(_host(AQTextField(label: 'Email', controller: c, error: 'Enter a valid email address.')));
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('otp field completes at six digits', (tester) async {
    String? done;
    await tester.pumpWidget(_host(AQOtpField(label: 'Code', state: AQOtpState.idle, enabled: true, onCompleted: (v) => done = v)));
    await tester.enterText(find.byType(TextField), '12345');
    expect(done, isNull);
    await tester.enterText(find.byType(TextField), '123456');
    expect(done, '123456');
  });

  testWidgets('segmented control reports selection', (tester) async {
    String? picked;
    await tester.pumpWidget(_host(AQSegmented<String>(options: const [(value: 'a', label: 'A'), (value: 'b', label: 'B')], selected: null, onChanged: (v) => picked = v)));
    await tester.tap(find.text('B'));
    expect(picked, 'b');
  });
}
