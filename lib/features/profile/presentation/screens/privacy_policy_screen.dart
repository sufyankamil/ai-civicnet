import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Civic Net',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: March 02, 2026',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Information We Collect',
              'We collect information you provide directly to us, such as when you create an account, update your profile, request help, or communicate with other users. This may include your name, email address, location, and photos.',
            ),
            _buildSection(
              context,
              '2. How We Use Your Information',
              'We use the information we collect to provide, maintain, and improve our services, facilitate connections between users, and ensure community safety. Your location data is used to show relevant help requests nearby.',
            ),
            _buildSection(
              context,
              '3. Sharing of Information',
              'We do not share your personal information with third parties except as described in this policy. Your profile information (name, avatar, skills) is visible to other users of the app.',
            ),
            _buildSection(
              context,
              '4. Data Security',
              'We take reasonable measures to help protect information about you from loss, theft, misuse and unauthorized access, disclosure, alteration and destruction.',
            ),
            _buildSection(
              context,
              '5. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at civicnet.app@gmail.com.',
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse('https://privacypolicy-ruddy.vercel.app/'),
                mode: LaunchMode.externalApplication,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser_rounded, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('View Full Policy Online',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('privacypolicy-ruddy.vercel.app',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}
