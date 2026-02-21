import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Determine the current index based on the route location
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) { _selectedIndex = 0; }
    else if (location.startsWith('/map')) { _selectedIndex = 1; }
    else if (location.startsWith('/chat')) { _selectedIndex = 3; }
    else if (location.startsWith('/profile')) { _selectedIndex = 4; }
    
    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(24),
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
             _buildNavItem(Icons.home_rounded, 0, '/home'),
             _buildNavItem(Icons.map_rounded, 1, '/map'),
             _buildFabItem(),
             _buildNavItem(Icons.chat_bubble_rounded, 3, '/chat'),
             _buildNavItem(Icons.person_rounded, 4, '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String route) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        context.go(route);
        setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildFabItem() {
    return GestureDetector(
      onTap: () => context.push('/create-request'),
      child: Container(
        width: 56,
        height: 56,
        transform: Matrix4.translationValues(0, -20, 0),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
