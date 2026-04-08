import 'package:flutter/material.dart';
import '../../../domain/entities/help_request_entity.dart';
import '../../../domain/entities/request_enums.dart';
import '../../../../../components/primary_button.dart';

class RequestActionBottomBar extends StatelessWidget {
  final HelpRequestEntity request;
  final String? currentUserId;
  final bool hasRated;
  final int ratingGiven;
  final VoidCallback onRate;

  const RequestActionBottomBar({
    super.key,
    required this.request,
    required this.currentUserId,
    required this.hasRated,
    required this.ratingGiven,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    if (request.status != RequestStatusEnum.completed) {
      return const SizedBox.shrink();
    }

    final isOwner = request.requesterId == currentUserId;
    final isHelper = request.helperId == currentUserId;

    if (hasRated) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            border: const Border(top: BorderSide(color: Colors.amber, width: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR RATING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.amber, letterSpacing: 1.0)),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(i < ratingGiven ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Text('$ratingGiven / 5', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.amber)),
            ],
          ),
        ),
      );
    }

    if (isOwner || isHelper) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
          ),
          child: PrimaryButton(
            text: 'SUBMIT RATING',
            onPressed: onRate,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
