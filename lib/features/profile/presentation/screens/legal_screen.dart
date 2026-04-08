import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(l10n.privacyPolicy),
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blueAccent),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.termsAndConditions),
            leading: const Icon(Icons.gavel_rounded, color: Colors.indigoAccent),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/terms-of-service'),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.communityCommitment),
            leading: const Icon(Icons.volunteer_activism_rounded, color: Colors.pinkAccent),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/commitment'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'CivicNet is committed to transparency and community empowerment. Your data is handled with the utmost care as outlined in our policies.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
