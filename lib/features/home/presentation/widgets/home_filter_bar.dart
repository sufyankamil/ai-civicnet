import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';

/// Compact horizontal category chips for the home feed.
class HomeFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const HomeFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      'All',
      'Recommended',
      'Emergency',
      'Tech Support',
      'Household',
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          final color = _getFilterColor(filter);

          // GestureDetector (not InkWell) — avoids the dark press/hold overlay.
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              onFilterSelected(filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.08)),
                  width: 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  else if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFilterIcon(filter),
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? color.withValues(alpha: 0.9) : color),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getFilterLabel(filter, l10n),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textPrimaryLight),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getFilterColor(String f) {
    if (f == 'Emergency') return Colors.red;
    if (f == 'Household') return Colors.orange;
    if (f == 'Tech Support') return Colors.blue;
    if (f == 'Recommended') return const Color(0xFF8B5CF6);
    return AppColors.primaryLight;
  }

  IconData _getFilterIcon(String f) {
    if (f == 'All') return Icons.grid_view_rounded;
    if (f == 'Recommended') return Icons.auto_awesome_rounded;
    if (f == 'Emergency') return Icons.bolt_rounded;
    if (f == 'Tech Support') return Icons.biotech_rounded;
    if (f == 'Household') return Icons.home_rounded;
    return Icons.category_rounded;
  }

  String _getFilterLabel(String k, AppLocalizations l) {
    if (k == 'All') return l.categoryAll;
    if (k == 'Recommended') return l.categoryRecommended;
    if (k == 'Emergency') return l.categoryEmergency;
    if (k == 'Tech Support') return l.categoryTechSupport;
    if (k == 'Household') return l.categoryHousehold;
    return k;
  }
}
