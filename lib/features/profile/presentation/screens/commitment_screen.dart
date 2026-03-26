import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class CommitmentScreen extends StatelessWidget {
  const CommitmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Our Commitment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(context),
            const SizedBox(height: 32),
            _buildCommitmentSection(isDark),
            const SizedBox(height: 24),
            _buildSafetyGuidelines(isDark),
            const SizedBox(height: 24),
            _buildPersonalGestureNote(isDark),
            const SizedBox(height: 48),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            'Built for Community',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We are committed to delivering the best to help our community in a better way.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentSection(bool isDark) {
    return _buildSection(
      title: 'Our Core Values',
      icon: Icons.verified_user_rounded,
      iconColor: Colors.blue,
      content: 'At CivicNet, our mission is to empower local communities through selfless help and connection. We believe in the power of neighbors helping neighbors without barriers.',
      isDark: isDark,
    );
  }

  Widget _buildSafetyGuidelines(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Text(
                'Safety Awareness',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSafetyPoint(
            'Be aware of people with wrong mindsets. Always verify who you are connecting with.',
          ),
          const SizedBox(height: 12),
          _buildSafetyPoint(
            'CivicNet will NEVER ask you for money to host an event or to post a help request.',
          ),
          const SizedBox(height: 12),
          _buildSafetyPoint(
            'Report any suspicious activity or financial requests immediately through the app.',
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: Colors.red),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalGestureNote(bool isDark) {
    return _buildSection(
      title: 'Personal Gestures',
      icon: Icons.volunteer_activism_rounded,
      iconColor: Colors.orange,
      content: 'If users choose to exchange money or gifts as a personal gesture of thanks, it is strictly between those individuals. CivicNet is not responsible for any transactions or issues arising after such gestures.',
      isDark: isDark,
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient(Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Committed to a safer community.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
