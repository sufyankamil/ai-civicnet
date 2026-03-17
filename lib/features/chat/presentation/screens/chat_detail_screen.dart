import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

import '../../domain/entities/message_entity.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../../../../services/supabase_service.dart'; // Temporarily for currentUserId if needed, or via viewmodel

import '../../../../services/toast_service.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../theme/app_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;
  final String? otherUserAvatar;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
    this.otherUserAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  final ChatViewModel _viewModel = Get.find<ChatViewModel>();

  bool _showSafetyWarning = true;
  bool _isListening = false;
  bool _speechEnabled = false;
  int _previousMessageCount = 0;

  // Blocking State
  bool _isBlockedByMe = false;
  List<String> _blockedUserIds = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _checkBlockStatus();
    _viewModel.markConversationAsRead(widget.conversationId);
  }

  Future<void> _checkBlockStatus() async {
    if (widget.otherUserId.isEmpty) return;
    
    final blocked = await _viewModel.isUserBlocked(widget.otherUserId);
    final blockedIds = await _viewModel.getBlockedUserIds();
    
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
        if (mounted) ToastService.showInfo(context, 'Microphone permission denied');
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
    // Current user can be abstracted, assuming SupabaseService().currentUserId for convenience
    final currentUserId = SupabaseService().currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showBlockOptions,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                backgroundImage: (widget.otherUserAvatar != null && widget.otherUserAvatar!.isNotEmpty) 
                    ? NetworkImage(widget.otherUserAvatar!) 
                    : null,
                child: (widget.otherUserAvatar == null || widget.otherUserAvatar!.isEmpty) 
                    ? const Icon(Icons.person, size: 16, color: Colors.white) 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(widget.otherUserName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
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
            child: StreamBuilder<List<MessageEntity>>(
              initialData: const [],
              stream: _viewModel.getMessagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    (snapshot.data == null || snapshot.data!.isEmpty)) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No messages yet', style: GoogleFonts.poppins(color: Colors.grey)));
                }

                final messages = snapshot.data!.where((m) => !_blockedUserIds.contains(m.senderId)).toList();
                
                if (messages.isEmpty) {
                   return Center(child: Text(AppLocalizations.of(context)!.noMessagesYet, style: GoogleFonts.poppins(color: Colors.grey)));
                }

                // Only auto-scroll when a new message actually arrives
                if (messages.length > _previousMessageCount) {
                  _previousMessageCount = messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                    // Mark any newly arrived messages as read
                    _viewModel.markConversationAsRead(widget.conversationId);
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    
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
                      key: ValueKey(message.id),
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
          
          if (_isBlockedByMe)
            SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  children: [
                     Text(AppLocalizations.of(context)!.blockedUserMessage, style: GoogleFonts.poppins(color: Colors.grey[600])),
                     TextButton(
                       onPressed: _unblockUser,
                       child: Text(AppLocalizations.of(context)!.unblockToChat),
                     ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : Colors.grey,
                        ),
                        onPressed: _listen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: _isListening ? 'Listening...' : 'Type a message...',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                            ),
                            filled: true,
                            fillColor: _isListening
                                ? Colors.red.withValues(alpha: 0.1)
                                : Theme.of(context).cardColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() => IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: _viewModel.isSending 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                          : const Icon(Icons.send, color: AppColors.primaryLight),
                        onPressed: _viewModel.isSending ? null : _sendMessage,
                      )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    final success = await _viewModel.sendMessage(widget.conversationId, content);
    if (success) {
      _messageController.clear();
    } else {
      if (mounted) ToastService.showError(context, 'Failed to send message.');
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
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (widget.otherUserAvatar != null && widget.otherUserAvatar!.isNotEmpty) 
                      ? NetworkImage(widget.otherUserAvatar!) 
                      : null,
                  child: (widget.otherUserAvatar == null || widget.otherUserAvatar!.isEmpty) 
                      ? const Icon(Icons.person, color: Colors.white) 
                      : null,
                ),
                title: Text(widget.otherUserName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text(AppLocalizations.of(context)!.userProfile, style: GoogleFonts.poppins(fontSize: 12)),
              ),
              const Divider(),
              if (!_isBlockedByMe) ...[
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.blockUser, style: GoogleFonts.poppins(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmBlock();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: Text(AppLocalizations.of(context)!.blockAndReport, style: GoogleFonts.poppins(color: Colors.orange)),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog();
                  },
                ),
              ] else 
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(AppLocalizations.of(context)!.unblockUser, style: GoogleFonts.poppins(color: Colors.green)),
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
     showAdaptiveDialog(
      context: context, 
      builder: (context) => AlertDialog.adaptive(
        title: Text(AppLocalizations.of(context)!.blockUserConfirm),
        content: Text('You will no longer receive messages from ${widget.otherUserName}. They will not be notified.'),
        actions: [
          if (Theme.of(context).platform == TargetPlatform.iOS) ...[
            CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _blockUser();
              }, 
              child: const Text('Block'),
            ),
          ] else ...[
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _blockUser();
              }, 
              child: const Text('Block', style: TextStyle(color: Colors.red)),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    final success = await _viewModel.blockUser(widget.otherUserId);
    if (success) {
      await _checkBlockStatus();
      if (mounted) ToastService.showInfo(context, 'User blocked');
    } else {
      if (mounted) ToastService.showError(context, 'Failed to block user.');
    }
  }

  Future<void> _unblockUser() async {
    final success = await _viewModel.unblockUser(widget.otherUserId);
    if (success) {
        await _checkBlockStatus();
        if (mounted) ToastService.showSuccess(context, 'User unblocked');
    } else {
        if (mounted) ToastService.showError(context, 'Failed to unblock user.');
    }
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Why are you reporting ${widget.otherUserName}?', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.reportHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
        actions: [
          if (Theme.of(context).platform == TargetPlatform.iOS) ...[
             CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
             CupertinoDialogAction(
               isDestructiveAction: true,
               onPressed: () {
                 Navigator.pop(context);
                 _reportUser(reasonController.text.trim());
               }, 
               child: const Text('Report & Block'),
             ),
          ] else ...[
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _reportUser(reasonController.text.trim());
              }, 
              child: const Text('Report & Block', style: TextStyle(color: Colors.white)),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _reportUser(String reason) async {
    if (reason.isEmpty) reason = 'No reason provided';
    final success = await _viewModel.reportUser(widget.otherUserId, reason);
    if (success) {
      await _checkBlockStatus();
      if (mounted) ToastService.showInfo(context, 'User reported and blocked');
    } else {
      if (mounted) ToastService.showError(context, 'Failed to report user.');
    }
  }
}
