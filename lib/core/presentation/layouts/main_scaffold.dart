import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final List<NavConfig> _navItems = [
    NavConfig(Icons.home_rounded, '/home', 0),
    NavConfig(Icons.explore_rounded, '/discover', 1),
    NavConfig(Icons.map_rounded, '/map', 2),
    NavConfig(null, '', -1), // Spacer for FAB
    NavConfig(Icons.smart_toy_rounded, '/ai-assistant', 3),
    NavConfig(Icons.event_note_rounded, '/events', 4),
    NavConfig(Icons.chat_bubble_rounded, '/chat', 5),
  ];

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) { _selectedIndex = 0; }
    else if (location.startsWith('/discover')) { _selectedIndex = 1; }
    else if (location.startsWith('/map')) { _selectedIndex = 2; }
    else if (location.startsWith('/ai-assistant')) { _selectedIndex = 3; }
    else if (location.startsWith('/events')) { _selectedIndex = 4; }
    else if (location.startsWith('/chat')) { _selectedIndex = 5; }

    return Scaffold(
      extendBody: true, // Allow content to show behind the glass bar
      body: widget.child,
      bottomNavigationBar: _buildGlassBottomNav(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildGlassBottomNav() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth - 48; // 24 padding each side
          final itemWidth = barWidth / _navItems.length;

          // Calculate where the highlight should be
          double targetX;
          if (_isDragging) {
            targetX = (_dragX - 24 - (itemWidth / 2)).clamp(0, barWidth - itemWidth);
          } else {
            // Find current logical index position (mapping 0-5 index to 0-6 position)
            int posIndex = _navItems.indexWhere((n) => n.index == _selectedIndex);
            targetX = posIndex * itemWidth;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            height: 70,
            child: Stack(
              children: [
                // 1. Glass Background
                ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Sliding Highlight
                AnimatedPositioned(
                  duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: targetX,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(
                             color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                             blurRadius: 8,
                             spreadRadius: 0,
                           )
                        ]
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
                      if (item.index == -1) {
                        return const SizedBox(width: 44);
                      }
                      return Expanded(
                        child: _buildNavItemWidget(item),
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
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: GestureDetector(
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
