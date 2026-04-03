import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
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
  bool _isDragging = false;
  double _dragX = 0;
  int _lastHapticIndex = -1;
  bool _isBottomNavVisible = true;

  final List<NavConfig> _navItems = [
    NavConfig(Icons.home_rounded, '/home', 0),
    NavConfig(Icons.explore_rounded, '/discover', 1),
    NavConfig(null, '', -1), // Spacer for FAB
    NavConfig(Icons.event_note_rounded, '/events', 2),
    NavConfig(Icons.chat_bubble_rounded, '/chat', 3),
  ];

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) { _selectedIndex = 0; }
    else if (location.startsWith('/discover')) { _selectedIndex = 1; }
    else if (location.startsWith('/events')) { _selectedIndex = 2; }
    else if (location.startsWith('/chat')) { _selectedIndex = 3; }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.forward) {
                if (!_isBottomNavVisible) setState(() => _isBottomNavVisible = true);
              } else if (notification.direction == ScrollDirection.reverse) {
                if (_isBottomNavVisible) setState(() => _isBottomNavVisible = false);
              }
              return true;
            },
            child: widget.child,
          ),
          
          // Floating Bottom Navigation Bar Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1.2),
              child: _buildGlassBottomNav(),
            ),
          ),

          // Floating Action Button Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0, // Align exactly to edge so SafeArea handles the notch
            child: SafeArea(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 2.8),
                child: Padding(
                  // 4 (nav bottom margin) + 35 (half nav height) - 28 (half FAB height) = 11
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Center(child: _buildFab()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBottomNav() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth - 48;
          final itemWidth = barWidth / _navItems.length;

          double targetX;
          if (_isDragging) {
            targetX = (_dragX - 24 - (itemWidth / 2)).clamp(0, barWidth - itemWidth);
          } else {
            // Current logical index position (mapping 0-5 index to 0-6 position)
            int posIndex = _navItems.indexWhere((n) => n.index == _selectedIndex);
            targetX = posIndex * itemWidth;
          }

          return Container(
            margin: const EdgeInsets.only(left: 24, right: 24, bottom: 4, top: 20),
            height: 70,
            child: Stack(
              children: [
                // 1. Glass Background
                ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: (Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white).withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Sliding Highlight
                AnimatedPositioned(
                  duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  left: targetX,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Icons and Gestures
                GestureDetector(
                  onHorizontalDragStart: (details) {
                    setState(() {
                      _isDragging = true;
                      _dragX = details.globalPosition.dx;
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragX = details.globalPosition.dx;
                      
                      // Identify current hover index for haptics
                      final localX = details.localPosition.dx;
                      final hoverPos = (localX / itemWidth).floor().clamp(0, _navItems.length - 1);
                      final navItem = _navItems[hoverPos];
                      
                      if (navItem.index != -1 && navItem.index != _lastHapticIndex) {
                        HapticFeedback.lightImpact();
                        _lastHapticIndex = navItem.index;
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final localX = renderBox.globalToLocal(Offset(_dragX, 0)).dx - 24;
                    final finalPos = (localX / itemWidth).floor().clamp(0, _navItems.length - 1);
                    final navItem = _navItems[finalPos];

                    setState(() {
                      _isDragging = false;
                      _lastHapticIndex = -1;
                    });

                    if (navItem.index != -1 && navItem.index != _selectedIndex) {
                      context.go(navItem.route);
                      setState(() => _selectedIndex = navItem.index);
                    }
                  },
                  child: Row(
                    children: _navItems.map((item) {
                      return Expanded(
                        child: item.index == -1 
                          ? const SizedBox.shrink() 
                          : _buildNavItemWidget(item),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItemWidget(NavConfig item) {
    final isSelected = _selectedIndex == item.index;
    final Color color = isSelected 
        ? Theme.of(context).primaryColor 
        : Colors.grey.withValues(alpha: 0.8);

    Widget iconWidget = Icon(item.icon, color: color, size: 24);

    if (item.index == 5 && Get.isRegistered<ChatViewModel>()) {
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
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        context.go(item.route);
        setState(() => _selectedIndex = item.index);
      },
      child: Container(
        height: double.infinity,
        color: Colors.transparent, // Expand tap area
        child: Center(child: iconWidget),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
        onTap: () {
          if (_selectedIndex == 1) { // Discover
            context.push('/create-event');
          } else {
            context.push('/create-request');
          }
        },
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient(Theme.of(context).brightness),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                blurRadius: 10, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      );
  }
}

class NavConfig {
  final IconData? icon;
  final String route;
  final int index;

  NavConfig(this.icon, this.route, this.index);
}
