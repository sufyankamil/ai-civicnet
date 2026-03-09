import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:get/get.dart';

import '../viewmodels/chat_viewmodel.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/toast_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatViewModel viewModel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    viewModel = Get.find<ChatViewModel>();
    viewModel.fetchConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Premium Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Text(
                    'Messages',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    if (viewModel.totalUnreadCount == 0) return const SizedBox.shrink();
                    return PopupMenuButton<String>(
                      elevation: 10,
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert),
                      ),
                      onSelected: (value) async {
                        if (value == 'mark_all_read') {
                          final success = await viewModel.markAllMessagesAsRead();
                          if (success && context.mounted) {
                            ToastService.showSuccess(context, 'All messages marked as read');
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'mark_all_read',
                          child: Row(
                            children: [
                              const Icon(Icons.done_all, color: AppColors.primaryLight, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Mark all as read',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // --- Modern Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryLight, size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --- Conversations List ---
            Expanded(
              child: Obx(() {
                if (viewModel.isLoading && viewModel.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }

                var filteredChats = viewModel.conversations;
                if (_searchQuery.isNotEmpty) {
                  filteredChats = filteredChats.where((c) => 
                    c.otherUserName.toLowerCase().contains(_searchQuery) || 
                    c.lastMessage.toLowerCase().contains(_searchQuery)
                  ).toList().obs;
                }

                if (filteredChats.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return RefreshIndicator(
                  onRefresh: () async => viewModel.fetchConversations(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return _buildConversationCard(context, chat, isDark);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, ChatConversationEntity chat, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/chat-detail?id=${chat.id}&name=${chat.otherUserName}&uid=${chat.otherUserId}&avatar=${Uri.encodeComponent(chat.otherUserAvatar)}').then((_) {
              viewModel.fetchConversations();
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with online status (if available, mockup for now)
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: chat.otherUserAvatar.isNotEmpty 
                          ? NetworkImage(chat.otherUserAvatar) 
                          : null,
                      child: chat.otherUserAvatar.isEmpty 
                          ? const Icon(Icons.person, size: 32, color: Colors.white) 
                          : null,
                    ),
                    if (chat.unreadCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? AppColors.surfaceDark : Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chat.otherUserName,
                            style: GoogleFonts.poppins(
                              fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            timeago.format(chat.lastMessageTime, locale: 'en_short'),
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: chat.unreadCount > 0 
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.grey[600],
                                fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (chat.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your messages with community helpers will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
