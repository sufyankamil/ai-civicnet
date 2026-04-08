import 'package:flutter/material.dart';
import '../../../../../services/supabase_service.dart';
import '../../../domain/entities/help_request_entity.dart';
import '../../../domain/entities/request_enums.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';

class RequestInfoSection extends StatelessWidget {
  final HelpRequestEntity request;
  final ValueChanged<RequestStatusEnum> onStatusChange;

  const RequestInfoSection({
    super.key,
    required this.request,
    required this.onStatusChange,
  });

  Color _statusColor(RequestStatusEnum status) {
    switch (status) {
      case RequestStatusEnum.open:
        return Colors.green;
      case RequestStatusEnum.inProgress:
        return Colors.blue;
      case RequestStatusEnum.completed:
        return Colors.purple;
      case RequestStatusEnum.closed:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String category) {
    if (category == 'Emergency') return Colors.redAccent;
    if (category == 'Household') return Colors.orangeAccent;
    if (category == 'Tech Support') return Colors.blueAccent;
    if (category == 'Food') return Colors.greenAccent;
    return AppColors.secondaryLight;
  }

  String _getLocalizedCategory(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category.toLowerCase()) {
      case 'emergency': return l10n.categoryEmergency;
      case 'tech support': return l10n.categoryTechSupport;
      case 'household': return l10n.categoryHousehold;
      case 'education': return l10n.categoryEducation;
      case 'general': return l10n.categoryGeneral;
      default: return category;
    }
  }

  Widget _buildPremiumChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatusChipContent(BuildContext context, RequestStatusEnum status, Color color, bool isInteractive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? color : (
      color == Colors.green ? Colors.green[700]! :
      color == Colors.blue ? Colors.blue[700]! :
      color == Colors.purple ? Colors.purple[700]! :
      color == Colors.grey ? Colors.grey[800]! : color
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.toString().split('.').last.toUpperCase(),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          if (isInteractive) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: textColor, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final status = request.status;
    final color = _statusColor(status);
    final isOwner = SupabaseService().currentUserId == request.requesterId;

    if (isOwner) {
      return PopupMenuButton<RequestStatusEnum>(
        initialValue: status,
        onSelected: onStatusChange,
        child: _buildStatusChipContent(context, status, color, true),
        itemBuilder: (context) => RequestStatusEnum.values
            .map(
              (s) => PopupMenuItem(
                value: s,
                child: Text(
                  s.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: _statusColor(s), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            )
            .toList(),
      );
    }

    return _buildStatusChipContent(context, status, color, false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPremiumChip(
                    _getLocalizedCategory(context, request.category.name),
                    _getCategoryColor(request.category.name),
                  ),
                  if (request.distance.isNotEmpty && request.distance.toLowerCase() != 'unknown') ...[
                    const SizedBox(width: 8),
                    Text(
                      request.distance,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        _buildStatusIndicator(context),
      ],
    );
  }
}
