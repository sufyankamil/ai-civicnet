import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../models/models.dart' as legacy;
import '../../../../../components/helper_card.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';

class HelperManagementSection extends StatelessWidget {
  final List<legacy.Helper> potentialHelpers;
  final bool isLoading;

  const HelperManagementSection({
    super.key,
    required this.potentialHelpers,
    required this.isLoading,
  });

  Widget _buildHelpersShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHelpers(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.people_alt_rounded, size: 40, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noHelpersYet,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to help out in your community!',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAllHelpersBottomSheet(BuildContext context, List<legacy.Helper> helpers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.secondaryLight, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'All Community Helpers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: helpers.length,
                  itemBuilder: (context, index) {
                    final helper = helpers[index];
                    return HelperCard(
                      helper: helper,
                      onTap: () {
                        Navigator.pop(context); // close bottom sheet
                        context.push('/profile/${helper.user.id}');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.communityHelpers.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0, color: Colors.grey[500]),
                ),
              ],
            ),
            if (potentialHelpers.length > 3)
              TextButton(
                onPressed: () => _showAllHelpersBottomSheet(context, potentialHelpers),
                child: Text(AppLocalizations.of(context)!.viewAll, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.nearbyMembersHelp,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          _buildHelpersShimmer(context)
        else if (potentialHelpers.isEmpty)
          _buildEmptyHelpers(context)
        else
          ...potentialHelpers.take(3).map((helper) => HelperCard(
                helper: helper,
                onTap: () => context.push('/profile/${helper.user.id}'),
              )),
      ],
    );
  }
}
