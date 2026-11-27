import 'package:flutter/material.dart';
import '../../../../widgets/adaptive_content_frame.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/legal_links.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: HideOnSideStrip(
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Civic Net',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: November 26, 2026',
              style: TextStyle(color: Colors.grey, fontSize: 14),
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
              'We do not sell your personal information. We share it with service providers (Supabase, Firebase, Google Maps, Google Gemini and RevenueCat) only as needed to run the app, as described in this policy. Your profile information (name, avatar, skills) is visible to other users of the app.',
            ),
            _buildSection(
              context,
              '4. Subscriptions and Purchases',
              'If you subscribe to CivicNet Pro, your purchase is processed by Apple or Google; we do not store or see your card or payment details. We keep your subscription status so we can unlock Pro features.',
            ),
            _buildSection(
              context,
              '5. AI Features',
              'AI features (the Aura assistant, voice requests, request categorization, search, support replies and the community briefing) send the text you provide, such as your request or message and the transcript of a voice request, through our secure server to Google Gemini to generate a response. We record how many AI actions you use each month to apply the free allowance.',
            ),
            _buildSection(
              context,
              '6. Data Security',
              'We take reasonable measures to help protect information about you from loss, theft, misuse and unauthorized access, disclosure, alteration and destruction.',
            ),
            _buildSection(
              context,
              '7. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at civicnet.app@gmail.com.',
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(
                LegalLinks.privacy,
                mode: LaunchMode.externalApplication,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.open_in_browser_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View Full Policy Online',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'civicnet.app/privacy',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
