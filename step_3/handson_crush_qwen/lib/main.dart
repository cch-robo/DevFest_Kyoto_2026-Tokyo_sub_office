import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/breakout_game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const BreakoutGameScreen(),
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
    );
  }
}
