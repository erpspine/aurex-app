import 'package:flutter/material.dart';

import 'login.dart';

void main() {
  runApp(const AurexApp());
}

class AurexApp extends StatelessWidget {
  const AurexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AurexLoginScreen.gold,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AurexLoginScreen(),
    );
  }
}
