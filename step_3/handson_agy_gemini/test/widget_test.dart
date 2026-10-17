import 'package:flutter_test/flutter_test.dart';
import 'package:handson_2026_breakout/main.dart';

void main() {
  testWidgets('Breakout game smoke test', (WidgetTester tester) async {
    // アプリをビルドしてフレームをトリガー
    await tester.pumpWidget(const MyApp());

    // ゲームタイトルやボタンが表示されていることを確認
    expect(find.text('BLOCK BREAKER'), findsOneWidget);
    expect(find.text('GAME START'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
  });
}
