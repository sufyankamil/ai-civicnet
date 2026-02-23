import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    try {
      final userProfile = await SupabaseService().getCurrentUserProfile();
      
      if (!mounted) return;

      if (userProfile != null) {
        // If the user hasn't set up any skills, we assume their profile is incomplete
        if (userProfile.skills.isEmpty) {
          context.go('/complete-profile');
        } else {
          context.go('/home');
        }
      } else {
        // Fallback if profile fails entirely
        context.go('/home');
      }
    } catch (e) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
