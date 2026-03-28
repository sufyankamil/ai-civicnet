import 'package:flutter/material.dart';

import '../../../../components/app_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We can use Theme.of(context) because this will be wrapped in a MaterialApp
    final primaryColor = Theme.of(context).primaryColor != Colors.blue 
        ? Theme.of(context).primaryColor 
        : const Color(0xFF6750A4); // Fallback if theme not fully ready or default

    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.handshake_rounded, 
              size: 80, 
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Civic Net',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            const AppLoader(size: 50, color: Colors.white, iconData: Icons.handshake_rounded),
          ],
        ),
      ),
    );
  }
}
