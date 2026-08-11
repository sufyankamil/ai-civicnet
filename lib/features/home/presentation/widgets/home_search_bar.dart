import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final TabController tabController;
  final Function(String) onSearchChanged;

  /// Must match [_PinnedHeaderDelegate] extents.
  static const double headerExtent = 120;

  const HomeSearchBar({
    super.key,
    required this.searchController,
    required this.tabController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedHeaderDelegate(
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: _buildAuraSearch(context, l10n),
                  ),
                  Expanded(child: _buildFloatingTabs(context, l10n)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuraSearch(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1);
    final fillColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05);

    return SizedBox(
      height: 42,
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: tabController.index == 0 ? l10n.searchHelp : l10n.searchNews,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 42,
          ),
          filled: true,
          fillColor: fillColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingTabs(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black)
              .withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TabBar(
          controller: tabController,
          indicator: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          labelPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: l10n.homeTitle, height: 36),
            Tab(text: l10n.communityTitle, height: 36),
          ],
        ),
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PinnedHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Child must be exactly this tall or SliverGeometry asserts.
    return SizedBox(
      height: maxExtent,
      width: double.infinity,
      child: child,
    );
  }

  @override
  double get maxExtent => HomeSearchBar.headerExtent;

  @override
  double get minExtent => HomeSearchBar.headerExtent;

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}
