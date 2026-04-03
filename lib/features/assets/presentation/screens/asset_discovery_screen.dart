import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodels/assets_viewmodel.dart';
import '../../widgets/asset_card.dart';
import '../../../../components/app_loader.dart';
import '../../../../models/models.dart';

class AssetDiscoveryScreen extends StatefulWidget {
  const AssetDiscoveryScreen({super.key});

  @override
  State<AssetDiscoveryScreen> createState() => _AssetDiscoveryScreenState();
}

class _AssetDiscoveryScreenState extends State<AssetDiscoveryScreen> {
  AssetCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AssetsViewModel>().loadPublicAssets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<AssetsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Assets'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category Filter
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: AssetCategory.values.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(null, 'All');
                }
                final category = AssetCategory.values[index - 1];
                return _buildCategoryChip(category, category.name);
              },
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.publicAssets.isEmpty) {
                return const Center(child: AppLoader());
              }

              if (controller.publicAssets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      const Text('No assets found in this category'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadPublicAssets(category: _selectedCategory),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: controller.publicAssets.length,
                  itemBuilder: (context, index) {
                    final asset = controller.publicAssets[index];
                    return AssetCard(
                      asset: asset,
                      onTap: () => _showBorrowDialog(context, asset),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(AssetCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          Get.find<AssetsViewModel>().loadPublicAssets(category: _selectedCategory);
        },
      ),
    );
  }

  void _showBorrowDialog(BuildContext context, CommunityAsset asset) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Borrow ${asset.title}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(asset.description),
            const SizedBox(height: 16),
            const Text('Note: This will open a chat with the owner to arrange the lending details.', 
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to chat with owner
              Get.snackbar('Chat Initialized', 'Opening chat with owner...');
            },
            child: const Text('Connect to Borrow'),
          ),
        ],
      ),
    );
  }
}
