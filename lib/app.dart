import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class ChargingClockApp extends StatelessWidget {
  const ChargingClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charging Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0C10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFA8),
          surface: Color(0xFF0A0C10),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
