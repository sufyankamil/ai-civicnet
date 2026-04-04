import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';

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
    final filters = ['All', 'Recommended', 'Emergency', 'Tech Support', 'Household'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
            final isSelected = selectedFilter == filter;
            final color = _getFilterColor(filter);
            return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppHaptic(
              onTap: () => onFilterSelected(filter),
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 90,
                  decoration: BoxDecoration(
                    color: isSelected ? color : (isDark ? Colors.white.withValues(alpha: 0.05) : color.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : (isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1)), 
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getFilterIcon(filter), 
                          color: isSelected ? Colors.white : (isDark ? color.withValues(alpha: 0.7) : color), 
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getFilterLabel(filter, l10n), 
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, 
                          color: isSelected ? Colors.white : (isDark ? color.withValues(alpha: 0.8) : color),
                        ), 
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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
    if (f == 'Recommended') return Colors.purple;
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
