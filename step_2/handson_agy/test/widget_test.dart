import 'package:flutter_test/flutter_test.dart';
import 'package:breakout_game/main.dart';

void main() {
  testWidgets('Neon Breakout smoke test - title screen loads and shows start button', (WidgetTester tester) async {
    // Build our app and trigger an initial frame.
    await tester.pumpWidget(const NeonBreakoutApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Verify Title elements exist
    expect(find.text('NEON'), findsOneWidget);
    expect(find.text('BREAKOUT'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);

    // Tap START GAME
    await tester.tap(find.text('START GAME'));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify launch prompt shows up
    expect(find.text('TAP OR PRESS SPACE'), findsOneWidget);
    expect(find.text('TO LAUNCH BALL'), findsOneWidget);
  });
}
