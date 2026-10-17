import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/breakout_game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 画面の向きを縦向きに固定（一般的なモバイル環境で遊びやすい設定）
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ブロック崩しゲーム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFFF43F5E),
          surface: Color(0xFF0F172A),
        ),
        useMaterial3: true,
      ),
      home: const BreakoutGameScreen(),
    );
  }
}
