import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/service_health_service.dart';
import '../services/toast_service.dart';
import '../theme/app_theme.dart';
import '../widgets/haptic_buttons.dart';

class ServiceStatusSheet extends StatefulWidget {
  const ServiceStatusSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const ServiceStatusSheet(),
    );
  }

  @override
  State<ServiceStatusSheet> createState() => _ServiceStatusSheetState();
}

class _ServiceStatusSheetState extends State<ServiceStatusSheet> {
  bool _isRunningDiagnostics = false;

  Future<void> _handleRunDiagnostics() async {
    setState(() {
      _isRunningDiagnostics = true;
    });

    AppHaptic.mediumImpact();
    final result = await ServiceHealthService().runDiagnostics();

    if (mounted) {
      setState(() {
        _isRunningDiagnostics = false;
      });

      if (result.isHealthy) {
        ToastService.showSuccess(context, 'Diagnostics passed: ${result.message}');
      } else {
        ToastService.showError(context, 'Diagnostics detected an issue: ${result.message}');
      }
    }
  }

  void _openSupport() {
    AppHaptic.lightImpact();
    Navigator.of(context).pop();
    context.push('/support');
  }

  String _formatOperationName(String? rawOp) {
    if (rawOp == null || rawOp.isEmpty) return 'General service sync';
    final lower = rawOp.toLowerCase();
    if (lower.contains('help_requests') || lower.contains('requests')) {
      if (lower.contains('post')) return 'Posting help request';
      if (lower.contains('update')) return 'Updating request status';
      return 'Loading community requests feed';
    }
    if (lower.contains('announcement') || lower.contains('news')) {
      return 'Community announcements feed';
    }
    if (lower.contains('event')) {
      return 'Community events & RSVP';
    }
    if (lower.contains('profile')) {
      return 'Member profile updates';
    }
    if (lower.contains('chat') || lower.contains('message')) {
      return 'Neighbor messaging';
    }
    if (lower.contains('ping') || lower.contains('diagnostic')) {
      return 'Network connection probe';
    }
    return rawOp;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;
    final safeBottom = math.max(mq.padding.bottom, mq.viewPadding.bottom);
    final effectiveBottomPadding = math.max(safeBottom, 20.0) + bottomInset + 12.0;

    final sheetBg = isDark
        ? const Color(0xFF13111F).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return ListenableBuilder(
      listenable: ServiceHealthService(),
      builder: (context, _) {
        final health = ServiceHealthService();
        final incident = health.activeIncident;
        final isOperational = health.status == ServiceStatus.operational;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: mq.size.height * 0.72,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: borderColor, width: 1.5),
                  left: BorderSide(color: borderColor, width: 1),
                  right: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(18, 10, 18, effectiveBottomPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pull Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sheet Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: isOperational
                                ? const LinearGradient(
                                    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFFFF9F43), Color(0xFFFF6B6B)],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isOperational ? Icons.check_circle_outline_rounded : Icons.sensors_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System Status & Diagnostics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                'Live community service status & health',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Primary Status Banner Card
                    _buildPrimaryStatusCard(context, isDark, isOperational, incident),
                    const SizedBox(height: 12),

                    // Subsystem Telemetry Breakdown
                    _buildSubsystemList(context, isDark, health),
                    const SizedBox(height: 14),

                    // Action: Run Live Diagnostics
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isRunningDiagnostics ? null : _handleRunDiagnostics,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isRunningDiagnostics
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 19),
                        label: Text(
                          _isRunningDiagnostics
                              ? 'Testing Connection...'
                              : (health.lastPingLatencyMs > 0
                                  ? 'Run Live Diagnostics (${health.lastPingLatencyMs}ms)'
                                  : 'Run Live Diagnostics'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Action: In-App Support Chat & Assistance
                    SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _openSupport,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.15),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.help_outline_rounded, size: 18),
                        label: const Text(
                          'Contact Community Support',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),

                    if (!isOperational && health.shouldShowBanner) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            AppHaptic.lightImpact();
                            health.dismissBanner();
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            minimumSize: const Size(0, 44),
                          ),
                          child: Text(
                            'Dismiss banner for this session',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryStatusCard(
    BuildContext context,
    bool isDark,
    bool isOperational,
    ServiceIncident? incident,
  ) {
    final cardBg = isOperational
        ? (isDark ? const Color(0xFF0F261E) : const Color(0xFFEAFBF3))
        : (isDark ? const Color(0xFF2C190D) : const Color(0xFFFFF4E5));

    final cardBorder = isOperational
        ? const Color(0xFF00B894).withValues(alpha: 0.4)
        : const Color(0xFFFF9F43).withValues(alpha: 0.5);

    final statusText = isOperational
        ? 'All Systems Operational'
        : (incident?.title ?? 'We are investigating a technical issue');

    final statusDesc = isOperational
        ? 'All neighborhood feeds, smart matching, and messaging services are running smoothly.'
        : (incident?.description ?? 'Services are currently degraded. Our engineering monitors are tracking the issue.');

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOperational ? const Color(0xFF00B894) : const Color(0xFFFF9F43),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isOperational ? const Color(0xFF00B894) : const Color(0xFFFF9F43))
                          .withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isOperational
                        ? (isDark ? const Color(0xFF55EFC4) : const Color(0xFF00875A))
                        : (isDark ? const Color(0xFFFFBE76) : const Color(0xFFC05621)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusDesc,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.35,
            ),
          ),
          if (incident?.lastFailedOperation != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: isDark ? const Color(0xFFFFBE76) : const Color(0xFFC05621),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Affected feature: ${_formatOperationName(incident!.lastFailedOperation)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFFFBE76) : const Color(0xFFC05621),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubsystemList(
    BuildContext context,
    bool isDark,
    ServiceHealthService health,
  ) {
    final isOperational = health.status == ServiceStatus.operational;
    final pingLatency = health.lastPingLatencyMs > 0 ? '${health.lastPingLatencyMs}ms' : 'Ready';

    return Column(
      children: [
        _buildSubsystemItem(
          isDark: isDark,
          icon: Icons.volunteer_activism_rounded,
          title: 'Community Feed & Requests',
          subtitle: 'Browsing, posting, and searching neighborhood needs',
          statusLabel: isOperational ? 'Operational' : 'Degraded',
          isOperational: isOperational,
          metric: pingLatency == 'Ready' ? 'Optimal' : pingLatency,
        ),
        const SizedBox(height: 8),
        _buildSubsystemItem(
          isDark: isDark,
          icon: Icons.auto_awesome_rounded,
          title: 'Aura AI & Smart Matching',
          subtitle: 'Personalized neighborhood recommendations & assistant',
          statusLabel: 'Operational',
          isOperational: true,
          metric: 'Active',
        ),
        const SizedBox(height: 8),
        _buildSubsystemItem(
          isDark: isDark,
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Direct Messaging & Alerts',
          subtitle: 'Live neighbor conversations & match notifications',
          statusLabel: 'Operational',
          isOperational: true,
          metric: 'Active',
        ),
      ],
    );
  }

  Widget _buildSubsystemItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusLabel,
    required bool isOperational,
    required String metric,
  }) {
    final itemBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isOperational ? AppColors.primaryLight : const Color(0xFFFF9F43),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isOperational ? const Color(0xFF00B894) : const Color(0xFFFF9F43))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOperational ? const Color(0xFF00B894) : const Color(0xFFFF9F43),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
