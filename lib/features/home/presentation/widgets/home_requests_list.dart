import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../components/request_card.dart';
import '../../../../components/request_card_skeleton.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeRequestsList extends StatelessWidget {
  final HomeViewModel viewModel;

  const HomeRequestsList({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      if (viewModel.isLoading && viewModel.filteredRequests.isEmpty) {
        return Column(
          children: [
            if (viewModel.isTakingTooLong)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryLight.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Connecting... this is taking a moment',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryLight.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) => const RequestCardSkeleton(),
            ),
          ],
        );
      }
      
      if (viewModel.filteredRequests.isEmpty) {
        final filter = viewModel.selectedFilter;
        final icon = viewModel.fetchError ? Icons.wifi_off_rounded : _getFilterIcon(filter);
        final color = viewModel.fetchError ? Colors.orange : _getFilterColor(filter);
        
        String title = filter == 'All' ? l10n.noRequests : 'No $filter Requests';
        String description = l10n.noRequestsDescription;

        if (viewModel.fetchError) {
          title = 'Connection Issue';
          description = 'We\'re having trouble reaching the server. Please check your internet and try again.';
        } else if (!viewModel.hasFetchedOnce) {
          title = 'Searching for neighbors...';
          description = 'Connecting to your community. This might take a moment if the connection is slow.';
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 60, 40, 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 64, color: color.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900, 
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14, 
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                    height: 1.5,
                  ),
                ),
                if (filter != 'All' || viewModel.fetchError || !viewModel.hasFetchedOnce) ...[
                  const SizedBox(height: 32),
                  AppHaptic(
                    onTap: () {
                      if (viewModel.fetchError || !viewModel.hasFetchedOnce) {
                        viewModel.fetchRequests();
                      } else {
                        viewModel.onFilterSelected('All');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (viewModel.fetchError || !viewModel.hasFetchedOnce) ? Icons.refresh_rounded : Icons.grid_view_rounded, 
                            size: 18, 
                            color: AppColors.primaryLight
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (viewModel.fetchError || !viewModel.hasFetchedOnce) ? 'Try Again' : 'Show All Requests',
                            style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      final list = viewModel.filteredRequests.where((r) => 
        !(viewModel.topRecommendation?.id == r.id && viewModel.topRecommendation!.aiRelevanceScore > 0.6)).toList();

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (context, index) => RequestCard(request: list[index]),
      );
    });
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
}
