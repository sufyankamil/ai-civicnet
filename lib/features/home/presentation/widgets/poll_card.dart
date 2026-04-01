import 'dart:ui';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.poll_rounded, color: AppColors.primaryLight, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.communityPollLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (isCreator)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                poll.question,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              if (poll.description != null && poll.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  poll.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ...poll.options.map((option) {
                final isSelected = poll.userVoteOptionId == option.id;
                final percentage = totalVotes == 0 ? 0.0 : (option.voteCount / totalVotes);
    
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppHaptic(
                    onTap: (hasVoted || poll.isExpired) ? null : () => onVote(option.id),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isSelected 
                            ? AppColors.primaryLight.withValues(alpha: 0.1)
                            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                        border: Border.all(
                          color: isSelected 
                            ? AppColors.primaryLight.withValues(alpha: 0.3) 
                            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (hasVoted)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: FractionallySizedBox(
                                widthFactor: percentage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSelected 
                                        ? [AppColors.primaryLight.withValues(alpha: 0.3), AppColors.primaryLight.withValues(alpha: 0.1)]
                                        : [Colors.grey.withValues(alpha: 0.1), Colors.grey.withValues(alpha: 0.05)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      option.optionText,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppColors.primaryLight : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (hasVoted)
                                    Text(
                                      '${(percentage * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? AppColors.primaryLight : Colors.grey[500],
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    '${AppLocalizations.of(context)!.votesCountSummary(totalVotes)} • ${poll.isExpired ? AppLocalizations.of(context)!.ended : AppLocalizations.of(context)!.daysLeft(poll.daysLeft)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
