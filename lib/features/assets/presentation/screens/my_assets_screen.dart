import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodels/assets_viewmodel.dart';
import '../../widgets/asset_card.dart';
import '../../../../components/app_loader.dart';
import '../../../../components/primary_button.dart';
import '../../../../models/models.dart';
import 'add_asset_sheet.dart';

class MyAssetsScreen extends GetView<AssetsViewModel> {
  const MyAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Community Assets'),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading && controller.myAssets.isEmpty) {
          return const Center(child: AppLoader());
        }

        if (controller.myAssets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Asset Library is empty',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share tools, equipment, or transport with your neighbors to build community trust and earn Karma.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    onPressed: () => _showAddAssetSheet(context),
                    text: 'Add Your First Asset',
                    icon: Icons.add,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadMyAssets(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: controller.myAssets.length,
            itemBuilder: (context, index) {
              final asset = controller.myAssets[index];
              return AssetCard(
                asset: asset,
                onTap: () => _showAssetActions(context, asset),
              );
            },
          ),
        );
      }),
      floatingActionButton: Obx(() => controller.myAssets.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAssetSheet(context),
              label: const Text('Add Asset'),
              icon: const Icon(Icons.add),
            )
          : const SizedBox.shrink()),
    );
  }

  void _showAddAssetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAssetSheet(),
    );
  }

  void _showAssetActions(BuildContext context, CommunityAsset asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(_getCategoryIcon(asset.category)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          asset.category.name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Asset'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddAssetSheet(asset: asset),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Asset', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, asset);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CommunityAsset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset?'),
        content: Text('Are you sure you want to remove "${asset.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteAsset(asset.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(AssetCategory category) {
    switch (category) {
      case AssetCategory.tools: return Icons.build_outlined;
      case AssetCategory.garden: return Icons.yard_outlined;
      case AssetCategory.transport: return Icons.directions_car_outlined;
      case AssetCategory.electronics: return Icons.electrical_services_outlined;
      case AssetCategory.household: return Icons.home_repair_service_outlined;
      case AssetCategory.other: return Icons.reorder_outlined;
    }
  }
}
