import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/request/domain/entities/help_request_entity.dart';
import '../../../../features/request/domain/entities/request_enums.dart';
import '../../../../features/request/models/help_request.dart' as model;

import '../../../../services/supabase_service.dart';
import '../../../../components/request_card_skeleton.dart';
import '../../../../features/home/presentation/widgets/opportunity_card.dart';
import 'package:go_router/go_router.dart';


class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<model.HelpRequest>? _recommendedRequests;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final requests = await SupabaseService().getRecommendedHelpRequests();
      if (mounted) {
        setState(() {
          _recommendedRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discoverTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadRecommendations();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecommendations,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Categories ---
                _buildSectionHeader(context, title: l10n.categories),
                const SizedBox(height: 12),
                _buildHorizontalCategories(l10n),
                const SizedBox(height: 24),

                // --- True AI Recommendations ---
                _buildSectionHeader(
                  context, 
                  title: 'True AI: For You', 
                  subtitle: 'Semantic matches based on your skills'
                ),
                const SizedBox(height: 12),
                _buildAiRecommendations(),
                const SizedBox(height: 12),
                
                // --- Community Asset Library ---
                _buildSectionHeader(
                  context, 
                  title: 'Community Assets', 
                  subtitle: 'Borrow resources from neighbors'
                ),
                const SizedBox(height: 12),
                _buildAssetLibraryBanner(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCategories(AppLocalizations l10n) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: HelpCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = HelpCategory.values[index];
          return _buildCategoryChip(
            context,
            title: _getCategoryTitle(l10n, category),
            icon: _getCategoryIcon(category),
            color: _getCategoryColor(category),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, {required String title, required IconData icon, required Color color}) {
    return InkWell(
      onTap: () => context.push('/home?filter=$title'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
          ),
      ],
    );
  }

  Widget _buildAiRecommendations() {
    if (_isLoading) {
      return SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => const SizedBox(
            width: 300,
            child: RequestCardSkeleton(),
          ),
        ),
      );
    }

    if (_recommendedRequests == null || _recommendedRequests!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 40, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No semantic matches yet.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              'Try updating your skills in profile!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendedRequests!.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final request = _recommendedRequests![index];
          // Convert Model to Entity for the RequestCard
          final entity = HelpRequestEntity(
            id: request.id,
            requesterId: request.requesterId,
            requesterName: request.requesterName,
            requesterAvatarUrl: request.requesterAvatarUrl,
            title: request.title,
            description: request.description,
            category: request.category,
            urgency: UrgencyLevel.values.firstWhere(
              (e) => e.toString().split('.').last == request.urgency.toString().split('.').last,
              orElse: () => UrgencyLevel.medium,
            ),
            postedAt: request.postedAt,
            distance: request.distance,
            aiRelevanceScore: request.aiRelevanceScore,
            locationName: request.locationName,
            lat: request.lat,
            lng: request.lng,
            status: RequestStatusEnum.values.firstWhere(
              (e) => e.toString().split('.').last == request.status.toString().split('.').last,
              orElse: () => RequestStatusEnum.open,
            ),
            helperId: request.helperId,
          );
          
          return OpportunityCard(
            request: entity,
            width: 320,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == _recommendedRequests!.length - 1 ? 0 : 8,
              bottom: 0,
            ),
          );

        },
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

  Widget _buildAssetLibraryBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/asset-library'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Community Asset Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Borrow tools, transport, and equipment from your neighbors.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Explore Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}

