import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

class DescriptionSection extends StatelessWidget {
  final String description;

  const DescriptionSection({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.description.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.5,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
