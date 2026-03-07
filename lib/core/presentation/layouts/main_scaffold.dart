import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../../../theme/app_theme.dart';

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
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) { _selectedIndex = 0; }
    else if (location.startsWith('/discover')) { _selectedIndex = 1; }
    else if (location.startsWith('/activity')) { _selectedIndex = 3; }
    else if (location.startsWith('/chat')) { _selectedIndex = 4; }
    
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
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
               _buildNavItem(Icons.explore_rounded, 1, '/discover'),
               _buildFabItem(),
               _buildNavItem(Icons.local_activity_rounded, 3, '/activity'),
               _buildNavItem(Icons.chat_bubble_rounded, 4, '/chat'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String route) {
    final isSelected = _selectedIndex == index;
    
    Widget iconWidget = Icon(
      icon,
      color: isSelected 
          ? Theme.of(context).primaryColor 
          : Colors.grey,
    );

    // Apply badge only to the Chat tab (index 4)
    if (index == 4) {
      if (Get.isRegistered<ChatViewModel>()) {
        final chatVM = Get.find<ChatViewModel>();
        iconWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget,
            Obx(() {
              final count = chatVM.totalUnreadCount;
              if (count > 0) {
                return Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      }
    }

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
        child: iconWidget,
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
