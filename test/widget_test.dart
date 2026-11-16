import 'package:flutter_test/flutter_test.dart';
import 'package:lick_it/main.dart';

void main() {
  testWidgets('App starts on the splash screen', (tester) async {
    await tester.pumpWidget(const LickItApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Get started'), findsOneWidget);
  });
}
