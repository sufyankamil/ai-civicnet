import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/request/domain/entities/request_enums.dart';
import 'package:go_router/go_router.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discoverTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.categories,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: HelpCategory.values.length,
                itemBuilder: (context, index) {
                  final category = HelpCategory.values[index];
                  return _buildCategoryCard(
                    context,
                    title: _getCategoryTitle(l10n, category),
                    icon: _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                    category: category,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required HelpCategory category,
  }) {
    return InkWell(
      onTap: () {
        context.go('/home?filter=$title');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryTitle(AppLocalizations l10n, HelpCategory category) {
    switch (category) {
      case HelpCategory.techSupport:
        return l10n.techSupport;
      case HelpCategory.household:
        return l10n.household;
      case HelpCategory.emergency:
        return l10n.emergency;
      case HelpCategory.education:
        return l10n.education;
      case HelpCategory.health:
        return l10n.health;
      case HelpCategory.other:
        return l10n.other;
      case HelpCategory.errands:
        return 'Errands';
      case HelpCategory.transport:
        return 'Transport';
    }
  }

  IconData _getCategoryIcon(HelpCategory category) {
    switch (category) {
      case HelpCategory.techSupport:
        return Icons.computer_rounded;
      case HelpCategory.household:
        return Icons.home_repair_service_rounded;
      case HelpCategory.emergency:
        return Icons.warning_rounded;
      case HelpCategory.education:
        return Icons.school_rounded;
      case HelpCategory.health:
        return Icons.medical_services_rounded;
      case HelpCategory.other:
        return Icons.category_rounded;
      case HelpCategory.errands:
        return Icons.shopping_bag_rounded;
      case HelpCategory.transport:
        return Icons.directions_car_rounded;
    }
  }

  Color _getCategoryColor(HelpCategory category) {
    switch (category) {
      case HelpCategory.techSupport:
        return Colors.blue;
      case HelpCategory.household:
        return Colors.orange;
      case HelpCategory.emergency:
        return Colors.red;
      case HelpCategory.education:
        return Colors.green;
      case HelpCategory.health:
        return Colors.pink;
      case HelpCategory.other:
        return Colors.purple;
      case HelpCategory.errands:
        return Colors.brown;
      case HelpCategory.transport:
        return Colors.teal;
    }
  }
}
