import 'package:flutter/material.dart';
import '../../../../widgets/adaptive_content_frame.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.termsAndConditions,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
              'CivicNet Terms of Service',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: November 28, 2026',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing or using the CivicNet mobile application, you agree to be bound by these Terms of Service. If you do not agree to all of these terms, do not use the application.',
              isDark,
            ),
            _buildSection(
              context,
              '2. User Responsibilities',
              'You are responsible for your use of the application and for any content you provide. You must provide accurate and complete information when creating an account.',
              isDark,
            ),
            _buildSection(
              context,
              '3. Community Conduct',
              'CivicNet is a platform for community help and connection. You agree not to engage in harassment, spam, or any illegal activities. We reserve the right to suspend or terminate accounts that violate these guidelines.',
              isDark,
            ),
            _buildSection(
              context,
              '4. Liability',
              'CivicNet facilitates connections between community members but is not responsible for the actions of its users. Use caution when meeting with people offline.',
              isDark,
            ),
            _buildSection(
              context,
              '5. Emergency SOS',
              'The Emergency SOS feature alerts neighbors who are near you. It is not an emergency service, and nobody is guaranteed to see or answer an alert. If you are in danger, call your local emergency number first. You can send a limited number of SOS alerts (one every 10 minutes and three per day). We may limit SOS or suspend an account that misuses it, for example by sending false alarms.',
              isDark,
            ),
            _buildSection(
              context,
              '6. Subscriptions (CivicNet Pro)',
              'CivicNet is free to use with a monthly allowance of AI actions. CivicNet Pro is an optional paid subscription that removes that limit. Prices, billing period (monthly or yearly) and any free trial are shown on the subscription screen before you confirm. Payment is charged to your Apple ID or Google Play account when you confirm the purchase, or when a free trial ends. Your subscription renews automatically for the same period unless you cancel at least 24 hours before the end of the current period. You can manage or cancel it at any time in your Apple ID or Google Play subscription settings; cancelling stops future renewals and you keep Pro until the end of the paid period. A free trial is offered once per Apple ID or Google account, and any unused part of it is forfeited when you buy a subscription. Refunds are handled by Apple or Google under their policies; we cannot issue them directly. If your subscription ends, your account stays active and returns to the free AI allowance. We may change prices or plans with notice, and a price change applies only from your next renewal.',
              isDark,
            ),
            _buildSection(
              context,
              '7. Modifications',
              'We reserve the right to modify or replace these terms at any time. We will notify users of any significant changes via the application.',
              isDark,
            ),
            _buildSection(
              context,
              '8. Contact Information',
              'For any questions regarding these terms, please contact us at civicnet.app@gmail.com.',
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
