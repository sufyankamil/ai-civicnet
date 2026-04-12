import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../features/assets/widgets/asset_card.dart';
import '../../../../../features/assets/models/asset.dart' as asset_models;

class SuggestedToolsSection extends StatelessWidget {
  final List<asset_models.CommunityAsset> matchedAssets;
  final bool isLoading;
  final Function(asset_models.CommunityAsset) onAssetTap;

  const SuggestedToolsSection({
    super.key,
    required this.matchedAssets,
    required this.isLoading,
    required this.onAssetTap,
  });

  Widget _buildToolsShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.construction_rounded, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 8),
            Container(width: 150, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildToolsShimmer(context);
    if (matchedAssets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.construction_rounded, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'SUGGESTED TOOLS',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0, color: Colors.grey[500]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'BETA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueAccent,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: matchedAssets.length,
            itemBuilder: (context, index) {
              final asset = matchedAssets[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                child: AssetCard(
                  asset: asset,
                  onTap: () => onAssetTap(asset),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
