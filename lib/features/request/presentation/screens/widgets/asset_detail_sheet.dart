import 'package:flutter/material.dart';
import '../../../../../features/assets/models/asset.dart' as asset_models;
import '../../../../../theme/app_theme.dart';
import '../../../../../components/primary_button.dart';
import 'premium_chip.dart';

class AssetDetailSheet extends StatelessWidget {
  final asset_models.CommunityAsset asset;
  final String? requestTitle;
  final Function(String userId, String userName, {String? initialMessage}) onStartChat;

  const AssetDetailSheet({
    super.key,
    required this.asset,
    this.requestTitle,
    required this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Image / Header section
          Stack(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: asset.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(asset.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: asset.imageUrl == null ? AppColors.auraGradient : null,
                ),
                child: asset.imageUrl == null
                    ? const Icon(Icons.construction_rounded, color: Colors.white, size: 64)
                    : null,
              ),
              Positioned(
                top: 28,
                right: 32,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PremiumChip(
                      label: asset.category.name.toUpperCase(), 
                      color: AppColors.secondaryLight,
                    ),
                    const Spacer(),
                    if (asset.similarity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: AppColors.primaryLight, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${(asset.similarity! * 100).toInt()}% MATCH',
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  asset.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  asset.description,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Owner Info section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_rounded, color: AppColors.primaryLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asset.ownerName ?? 'Neighbor',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Willing to lend this tool',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'I CAN BRING THIS',
                  onPressed: () {
                    Navigator.pop(context);
                    final title = requestTitle ?? 'my request';
                    final msg = 'Hi! I saw your "${asset.title}" and I can bring it to help with "$title".';
                    onStartChat(asset.ownerId, asset.ownerName ?? 'Neighbor', initialMessage: msg);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
