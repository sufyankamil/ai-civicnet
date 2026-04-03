import 'package:flutter/material.dart';

import '../../../../components/app_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).primaryColor != Colors.blue 
        ? Theme.of(context).primaryColor 
        : const Color(0xFF6750A4);
        
    final centerColor = baseColor.withValues(alpha: 0.8);
    final edgeColor = baseColor.withValues(alpha: 1.0);

    return Scaffold(
      backgroundColor: edgeColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.1),
            radius: 1.0,
            colors: [
              centerColor,
              edgeColor,
            ],
            stops: const [0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Subtle glowing effect behind the icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.handshake_rounded, 
                  size: 90, 
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Civic Net',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'COMMUNITY IN ACTION',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 80),
              // Loader styled to fit the premium aesthetic
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const AppLoader(
                  size: 30, 
                  color: Colors.white, 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
