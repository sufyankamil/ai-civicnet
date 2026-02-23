import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<List<ChatConversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshConversations();
  }

  void _refreshConversations() {
    setState(() {
      _conversationsFuture = SupabaseService().getConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<ChatConversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text('No messages yet', style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          final chats = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async => _refreshConversations(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return GestureDetector(
                  onTap: () async {
                    await context.push('/chat-detail?id=${chat.id}&name=${chat.otherUserName}&uid=${chat.otherUserId}');
                    _refreshConversations();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                          backgroundImage: chat.otherUserAvatar.isNotEmpty 
                             ? NetworkImage(chat.otherUserAvatar) 
                             : null,
                          child: chat.otherUserAvatar.isEmpty 
                             ? Text(chat.otherUserName[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)) 
                             : null,
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
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                  Text(
                                    timeago.format(chat.lastMessageTime, locale: 'en_short'),
                                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chat.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
