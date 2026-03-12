import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/request/domain/entities/request_enums.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/supabase_service.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discover', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/activity'),
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey),
          ),
          FutureBuilder(
            future: SupabaseService().getCurrentUserProfile(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final hasAvatar = user?.avatarUrl != null && user!.avatarUrl.isNotEmpty;
              
              return InkWell(
                onTap: () => context.push('/profile'), 
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl) : null,
                    child: hasAvatar ? null : const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                ),
              );
            }
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categories',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildCategoryCard(
                    context,
                    title: 'Tech Support',
                    icon: Icons.computer_rounded,
                    color: Colors.blue,
                    category: HelpCategory.techSupport,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Household',
                    icon: Icons.home_repair_service_rounded,
                    color: Colors.orange,
                    category: HelpCategory.household,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Emergency',
                    icon: Icons.warning_rounded,
                    color: Colors.red,
                    category: HelpCategory.emergency,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Education',
                    icon: Icons.school_rounded,
                    color: Colors.green,
                    category: HelpCategory.education,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Health',
                    icon: Icons.medical_services_rounded,
                    color: Colors.pink,
                    category: HelpCategory.health,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Other',
                    icon: Icons.category_rounded,
                    color: Colors.purple,
                    category: HelpCategory.other,
                  ),
                ],
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
        // Navigate back to home and set the filter via query parameter
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
}
