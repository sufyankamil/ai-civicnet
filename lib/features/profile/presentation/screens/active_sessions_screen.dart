import 'package:flutter/material.dart';
import '../../../../services/supabase_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/models.dart';
import '../../../../components/app_loader.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../services/toast_service.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  late Future<List<UserSession>> _sessionsFuture;
  bool _isRevokingAll = false;

  @override
  void initState() {
    super.initState();
    _refreshSessions();
  }

  void _refreshSessions() {
    setState(() {
      _sessionsFuture = SupabaseService().getUserSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<UserSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text('Failed to load sessions', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      snapshot.error.toString(), 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _refreshSessions, child: const Text('Retry')),
                ],
              ),
            );
          }

          final allSessions = snapshot.data ?? [];
          if (allSessions.isEmpty) {
            return const Center(
              child: Text('No active sessions found.', style: TextStyle(color: Colors.grey)),
            );
          }

          // Rely definitively on the locally parsed JWT session ID
          final localCurrentSessionId = SupabaseService().currentSessionId;
          final currentSessionIds = <String>{};
          
          if (localCurrentSessionId != null) {
            currentSessionIds.add(localCurrentSessionId);
          }

          // Deduplicate sessions: Keep only the most recent per device name, always keep current
          final sessions = <UserSession>[];
          final seenDevices = <String>{};

          for (final session in allSessions) {
            final isActuallyCurrent = currentSessionIds.contains(session.id);
            if (isActuallyCurrent) {
              sessions.add(session);
              seenDevices.add(session.deviceName);
            }
          }

          for (final session in allSessions) {
            final isActuallyCurrent = currentSessionIds.contains(session.id);
            // Force legacy sessions to show correctly even if hot restart hasn't happened
            final safeDeviceName = session.deviceName.contains('dart') || session.deviceName.contains('io') 
                ? 'Mobile Device' : session.deviceName;
                
            if (!isActuallyCurrent && !seenDevices.contains(safeDeviceName)) {
              sessions.add(session);
              seenDevices.add(safeDeviceName);
            }
          }

          final otherSessionsCount = sessions.where((s) => !currentSessionIds.contains(s.id)).length;

          return Column(
            children: [
              if (otherSessionsCount > 0)
                _buildLogOutAllHeader(otherSessionsCount),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                  itemCount: sessions.length,
                  separatorBuilder: (context, index) => const Divider(indent: 72),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isCurrent = currentSessionIds.contains(session.id);

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isCurrent ? AppColors.primaryLight : Colors.grey).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          session.isMobile ? Icons.phone_android_rounded : Icons.computer_rounded,
                          color: isCurrent ? AppColors.primaryLight : Colors.grey,
                        ),
                      ),
                      title: Text(
                        session.deviceName.toLowerCase().contains('dart') || session.deviceName.toLowerCase().contains('io') 
                            ? 'Mobile Device' : session.deviceName, 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCurrent)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 4),
                              child: Text(
                                'Current Device',
                                style: TextStyle(
                                  color: Colors.green.shade600, 
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          Text(
                            'Last active: ${timeago.format(session.lastActiveAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'IP: ${session.ipAddress}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      trailing: isCurrent 
                        ? null 
                        : IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => _confirmRevocation(session),
                          ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogOutAllHeader(int count) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unrecognized Devices?', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                Text(
                  'Log out from $count other sessions.',
                  style: TextStyle(fontSize: 12, color: Colors.redAccent.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isRevokingAll ? null : _confirmRevokeAllOthers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isRevokingAll 
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Log Out All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRevokeAllOthers() async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Secure Account?'),
        content: const Text('This will log out all other devices except this one. You will stay logged in here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isRevokingAll = true);
      try {
        await SupabaseService().revokeAllOtherSessions();
        // Give Supabase a moment to commit the delete transaction before we fetch again
        await Future.delayed(const Duration(milliseconds: 500));
        _refreshSessions();
        if (mounted) {
          ToastService.showSuccess(context, 'All other sessions revoked successfully.');
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Failed to revoke sessions. Please try again.');
        }
      } finally {
        if (mounted) setState(() => _isRevokingAll = false);
      }
    }
  }

  Future<void> _confirmRevocation(UserSession session) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Log out of device?'),
        content: Text('Are you sure you want to log out of ${session.deviceName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService().revokeSession(session.id);
        // Give Supabase a moment to commit the delete transaction before we fetch again
        await Future.delayed(const Duration(milliseconds: 500));
        _refreshSessions();
        if (mounted) {
          final safeName = session.deviceName.toLowerCase().contains('dart') || session.deviceName.toLowerCase().contains('io') 
              ? 'Mobile Device' : session.deviceName;
          ToastService.showSuccess(context, 'Logged out of $safeName');
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Failed to revoke session. Please try again.');
        }
      }
    }
  }
}
