import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CuradorEstoicoApp());
}

class CuradorEstoicoApp extends StatelessWidget {
  const CuradorEstoicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curador Estoico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4A053),
          secondary: Color(0xFF8B7355),
          surface: Color(0xFF1A1A2E),
        ),
        fontFamily: 'Georgia',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4A053),
            letterSpacing: 1.5,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: Color(0xFFE8E0D4),
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFFB0A899),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
