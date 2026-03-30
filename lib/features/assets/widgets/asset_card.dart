import 'package:flutter/material.dart';
import '../../../components/glass_card.dart';
import '../../../components/animated_glow_border.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';

class AssetCard extends StatelessWidget {
  final CommunityAsset asset;
  final VoidCallback? onTap;
  final bool showGlow;

  const AssetCard({
    super.key,
    required this.asset,
    this.onTap,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset Image or Category Icon
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            clipBehavior: Clip.antiAlias,
            child: asset.imageUrl != null
                ? Image.network(
                    asset.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      _getCategoryIcon(asset.category),
                      size: 48,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        asset.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(context),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  asset.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      asset.category.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const Spacer(),
                    if (asset.similarity != null)
                      _buildMatchScore(context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (showGlow || (asset.similarity != null && asset.similarity! > 0.7)) {
      cardContent = AnimatedGlowBorder(
        borderRadius: 16,
        isActive: true,
        child: cardContent,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: cardContent,
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    switch (asset.status) {
      case AssetStatus.available:
        color = Colors.green;
        break;
      case AssetStatus.lent:
        color = Colors.orange;
        break;
      case AssetStatus.private:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        asset.status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMatchScore(BuildContext context) {
    final score = (asset.similarity! * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$score% MATCH',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(AssetCategory category) {
    switch (category) {
      case AssetCategory.tools:
        return Icons.build_outlined;
      case AssetCategory.garden:
        return Icons.yard_outlined;
      case AssetCategory.transport:
        return Icons.directions_car_outlined;
      case AssetCategory.electronics:
        return Icons.electrical_services_outlined;
      case AssetCategory.household:
        return Icons.home_repair_service_outlined;
      case AssetCategory.other:
        return Icons.reorder_outlined;
    }
  }
}
