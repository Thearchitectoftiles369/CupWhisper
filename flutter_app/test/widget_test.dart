import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupwhisper/app/app.dart';

void main() {
  testWidgets('CupWhisperApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CupWhisperApp(),
      ),
    );

    expect(find.text('CupWhisper'), findsOneWidget);
  });
}
