import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../../../models/models.dart';

class GuildCard extends StatelessWidget {
  final Guild guild;
  final VoidCallback onToggleJoin;

  const GuildCard({
    super.key,
    required this.guild,
    required this.onToggleJoin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: AppColors.auraGradient,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        backgroundImage: guild.avatarUrl != null ? NetworkImage(guild.avatarUrl!) : null,
                        child: guild.avatarUrl == null 
                          ? const Icon(Icons.groups_rounded, color: AppColors.primaryLight, size: 20) 
                          : null,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        guild.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  guild.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  guild.description ?? AppLocalizations.of(context)!.noDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.primaryLight),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.membersCount(guild.memberCount),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    AppHaptic(
                      onTap: onToggleJoin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: guild.isUserMember 
                            ? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
                            : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: guild.isUserMember ? null : [
                            BoxShadow(
                              color: AppColors.primaryLight.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Text(
                          guild.isUserMember ? AppLocalizations.of(context)!.joined : AppLocalizations.of(context)!.join,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: guild.isUserMember ? Colors.grey[500] : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
