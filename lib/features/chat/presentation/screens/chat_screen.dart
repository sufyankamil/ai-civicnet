import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:get/get.dart';


import '../viewmodels/chat_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatViewModel viewModel;

  @override
  void initState() {
    super.initState();
    // Controller is provided via ChatBinding
    viewModel = Get.find<ChatViewModel>();
    // Re-fetch every time this tab becomes visible
    viewModel.fetchConversations();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (viewModel.isLoading && viewModel.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (viewModel.conversations.isEmpty) {
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

        final chats = viewModel.conversations;
        
        return RefreshIndicator(
          onRefresh: () async => viewModel.fetchConversations(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return GestureDetector(
                onTap: () async {
                  await context.push('/chat-detail?id=${chat.id}&name=${chat.otherUserName}&uid=${chat.otherUserId}');
                  viewModel.fetchConversations();
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
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 28, color: Colors.white),
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
      }),
    );
  }
}
