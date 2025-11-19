import 'package:flutter/material.dart';
import 'package:setor_mobil/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // ignore: library_private_types_in_public_api
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Your exact Brand Blue
  static const Color _brandBlue = Color(0xFF0066FF);

  // NEW: A "Slate" dark background.
  // Instead of pure black, this is a very dark blue-grey.
  // It absorbs the neon blue better than black does.
  static const Color _darkBackground = Color(0xFF1A1D21);
  static const Color _darkSurface = Color(
    0xFF24272D,
  ); // Slightly lighter for cards

  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Setor Mobil',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // === LIGHT THEME (Unchanged) ===
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: _brandBlue,
          primary: _brandBlue,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ),

      // === NEW SOFTER DARK THEME ===
      darkTheme: ThemeData(
        useMaterial3: true,
        // We explicitly set the scaffold background color here
        scaffoldBackgroundColor: _darkBackground,

        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: _brandBlue,

          // 1. Keep your brand blue
          primary: _brandBlue,
          onPrimary: Colors.white,

          // 2. Change the "Surface" (Card backgrounds, etc) to the lighter Slate
          surface: _darkSurface,
          onSurface: const Color(
            0xFFEEEEEE,
          ), // Off-white text is softer than pure white
          // 3. Change the "Background" (The space behind cards) to the darker Slate
          surfaceBright: _darkBackground,
          onSurfaceVariant: const Color(0xFFEEEEEE),

          // Optional: Tweak the outline color so borders aren't too harsh
          outline: Colors.grey.shade700,
        ),

        // Fix the AppBar to match the new background so it looks seamless
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBackground, // seamless look
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ),

      // Changed from HomeScreen to SplashScreen
      home: const SplashScreen(),
    );
  }
}
