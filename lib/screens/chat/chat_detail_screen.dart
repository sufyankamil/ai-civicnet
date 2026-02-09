import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isSending = false;
  bool _showSafetyWarning = true;
  bool _isListening = false;
  bool _speechEnabled = false;
  
  // Blocking State
  bool _isBlockedByMe = false;
  List<String> _blockedUserIds = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _checkBlockStatus();
  }

  Future<void> _checkBlockStatus() async {
    if (widget.otherUserId.isEmpty) return;
    
    final blocked = await SupabaseService().isUserBlocked(widget.otherUserId);
    final blockedIds = await SupabaseService().getBlockedUserIds();
    
    if (mounted) {
      setState(() {
        _isBlockedByMe = blocked;
        _blockedUserIds = blockedIds;
      });
    }
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (val) {},
        onStatus: (val) {},
      );
      if (mounted) setState(() {});
    } catch (e) {
      // Handle error silently
    }
  }

  void _listen() async {
    if (!_speechEnabled) {
      bool permission = await Permission.microphone.request().isGranted;
      if (!permission) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
        return;
      }
      _initSpeech(); // Retry init
    }

    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _messageController.text = val.recognizedWords;
              // If listening stops automatically (final result), update state
              if (val.finalResult) {
                _isListening = false;
              }
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseService().currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showBlockOptions,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.otherUserName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: Column(
        children: [
          if (_showSafetyWarning)
            Container(
              width: double.infinity,
              color: Colors.amber[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                   const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'Please respect community guidelines. Do not share personal details. Report users if needed.',
                       style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                     ),
                   ),
                   IconButton(
                     icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                     onPressed: () => setState(() => _showSafetyWarning = false),
                     padding: EdgeInsets.zero,
                     constraints: const BoxConstraints(),
                   ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: SupabaseService().getMessagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No messages yet', style: GoogleFonts.poppins(color: Colors.grey)));
                }

                // Filter messages from blocked users
                final messages = snapshot.data!.where((m) => !_blockedUserIds.contains(m.senderId)).toList();
                
                if (messages.isEmpty) {
                   return Center(child: Text('No messages yet', style: GoogleFonts.poppins(color: Colors.grey)));
                }
                
                // Auto-scroll to bottom on new message
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    
                    // Date Header Logic
                    bool showDateHeader = false;
                    if (index == 0) {
                      showDateHeader = true;
                    } else {
                      final prevMessage = messages[index - 1];
                      final prevDate = DateTime(prevMessage.createdAt.year, prevMessage.createdAt.month, prevMessage.createdAt.day);
                      final currDate = DateTime(message.createdAt.year, message.createdAt.month, message.createdAt.day);
                      if (currDate.isAfter(prevDate)) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  DateFormat('MMMM d, y').format(message.createdAt),
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primaryLight : Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  message.content,
                                  style: GoogleFonts.poppins(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeago.format(message.createdAt, locale: 'en_short'),
                                  style: GoogleFonts.poppins(
                                    color: isMe ? Colors.white70 : Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          // Input Area
          if (_isBlockedByMe)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                   Text('You have blocked this user.', style: GoogleFonts.poppins(color: Colors.grey[600])),
                   TextButton(
                     onPressed: _unblockUser,
                     child: const Text('Unblock to chat'),
                   ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.grey,
                    ),
                    onPressed: _listen,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening...' : 'Type a message...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: _isListening ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppColors.primaryLight),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    // Stop listening if sending
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() => _isSending = true);
    try {
      await SupabaseService().sendMessage(widget.conversationId, content);
      _messageController.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showBlockOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${widget.otherUserId}'), 
                ),
                title: Text(widget.otherUserName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text('User Profile', style: GoogleFonts.poppins(fontSize: 12)),
              ),
              const Divider(),
              if (!_isBlockedByMe) ...[
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: Text('Block User', style: GoogleFonts.poppins(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmBlock();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: Text('Block and Report', style: GoogleFonts.poppins(color: Colors.orange)),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog();
                  },
                ),
              ] else 
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Unblock User', style: GoogleFonts.poppins(color: Colors.green)),
                  onTap: () {
                    Navigator.pop(context);
                    _unblockUser();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmBlock() {
     showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Block User?'),
        content: Text('You will no longer receive messages from ${widget.otherUserName}. They will not be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser();
            }, 
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    try {
      await SupabaseService().blockUser(widget.otherUserId);
      await _checkBlockStatus();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _unblockUser() async {
    try {
      await SupabaseService().unblockUser(widget.otherUserId);
      await _checkBlockStatus();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User unblocked')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Why are you reporting ${widget.otherUserName}?', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Spam, harassment, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _reportUser(reasonController.text.trim());
            }, 
            child: const Text('Report & Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _reportUser(String reason) async {
    if (reason.isEmpty) reason = 'No reason provided';
    try {
      await SupabaseService().reportUser(widget.otherUserId, reason);
      await _checkBlockStatus();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User reported and blocked')));
      // Requirement: "blocked user id will be saved along with the id of user that have blocked along with a count.. like how many user has reported.."
      // Handled by SupabaseService and Triggers.
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
