import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../widgets/haptic_buttons.dart';
import '../../../../../services/supabase_service.dart';
import '../../../domain/entities/help_request_entity.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';

class RequesterSection extends StatelessWidget {
  final HelpRequestEntity request;
  final bool isStartingChat;
  final VoidCallback onChat;

  const RequesterSection({
    super.key,
    required this.request,
    required this.isStartingChat,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: 'avatar-${request.id}',
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
            ),
            child: request.requesterAvatarUrl.isNotEmpty && (request.requesterAvatarUrl.startsWith('http'))
                ? CachedNetworkImage(
                    imageUrl: request.requesterAvatarUrl,
                    imageBuilder: (context, imageProvider) => CircleAvatar(radius: 20, backgroundImage: imageProvider),
                    errorWidget: (context, url, error) => const CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                  )
                : const CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.requesterName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(AppLocalizations.of(context)!.requester, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
        const Spacer(),
        if (SupabaseService().currentUserId != request.requesterId)
          AppHaptic(
            onTap: onChat,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: isStartingChat
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                  : const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryLight, size: 18),
            ),
          ),
      ],
    );
  }
}
