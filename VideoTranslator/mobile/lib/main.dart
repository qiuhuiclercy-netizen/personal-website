import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const VideoDubApp());
}

class VideoDubApp extends StatelessWidget {
  const VideoDubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VideoDub AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0F1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C6AFF),
          secondary: Color(0xFFFF6AAD),
          surface: Color(0xFF161827),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
