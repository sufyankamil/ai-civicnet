import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../../../models/models.dart';

class PollCard extends StatelessWidget {
  final Poll poll;
  final Function(String optionId) onVote;
  final VoidCallback? onDelete;
  final bool isCreator;

  const PollCard({
    super.key,
    required this.poll,
    required this.onVote,
    this.onDelete,
    this.isCreator = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.userVoteOptionId != null;
    final totalVotes = poll.options.fold<int>(0, (sum, opt) => sum + opt.voteCount);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)!.communityPollLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const Spacer(),
              if (isCreator)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                const Icon(Icons.poll_rounded, color: AppColors.primaryLight, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            poll.question,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (poll.description != null && poll.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              poll.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...poll.options.map((option) {
            final isSelected = poll.userVoteOptionId == option.id;
            final percentage = totalVotes == 0 ? 0.0 : (option.voteCount / totalVotes);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppHaptic(
                onTap: (hasVoted || poll.isExpired) ? null : () => onVote(option.id),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                        ? AppColors.primaryLight 
                        : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (hasVoted)
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                ? AppColors.primaryLight.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  option.optionText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primaryLight : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasVoted)
                                Text(
                                  '${(percentage * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.primaryLight : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            '${AppLocalizations.of(context)!.votesCountSummary(totalVotes)} • ${poll.isExpired ? AppLocalizations.of(context)!.ended : AppLocalizations.of(context)!.daysLeft(poll.daysLeft)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
