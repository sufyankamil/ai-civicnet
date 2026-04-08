import 'package:flutter/material.dart';
import '../../../../../theme/app_theme.dart';

class OwnerActionsSection extends StatelessWidget {
  const OwnerActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: AppColors.primaryLight, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Manage Your Request',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keep an eye on applications from neighbors who want to help.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
