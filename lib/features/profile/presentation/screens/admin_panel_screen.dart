import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/models.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../widgets/haptic_buttons.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Future<List<VerificationRequest>>? _requestsFuture;

  @override
  void initState() {
    super.initState();
    _refreshRequests();
  }

  void _refreshRequests() {
    setState(() {
      _requestsFuture = SupabaseService().getPendingVerificationRequests();
    });
  }

  Future<void> _handleResolution(VerificationRequest request, bool approved) async {
    try {
      if (approved) {
        // Update role FIRST. If this fails (RLS), we don't mark as approved yet.
        await SupabaseService().updateUserRole(request.userId, 'admin');
        await SupabaseService().updateVerificationStatus(request.id, 'approved');
        if (mounted) ToastService.showSuccess(context, '${request.userName} is now an Admin!');
      } else {
        await SupabaseService().updateVerificationStatus(request.id, 'rejected');
        if (mounted) ToastService.showInfo(context, 'Request rejected');
      }
      
      _refreshRequests();
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Control Panel', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<VerificationRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          
          final requests = snapshot.data ?? [];
          
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('All caught up!', style: GoogleFonts.poppins(color: Colors.grey)),
                  Text('No pending verification requests.', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: (request.userAvatarUrl != null && request.userAvatarUrl!.isNotEmpty)
                                ? NetworkImage(request.userAvatarUrl!)
                                : null,
                            child: (request.userAvatarUrl == null || request.userAvatarUrl!.isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(request.userName ?? 'Unknown User', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                Text('Applied for Leader status', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          request.reason,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppTextButton(
                            onPressed: () => _handleResolution(request, false),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          AppElevatedButton(
                            onPressed: () => _handleResolution(request, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
