import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/ai_assistant_viewmodel.dart';
import '../../../../theme/app_theme.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final AiAssistantViewModel _viewModel = Get.put(AiAssistantViewModel());
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Community AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'BETA', 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _viewModel.clearChat(),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primaryLight.withValues(alpha: 0.8),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Expanded(
              child: Obx(() {
                _scrollToBottom();
                if (_viewModel.messages.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _viewModel.messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Community AI is in beta and may show inaccurate info.',
                                    style: TextStyle(
                                      fontSize: 11, 
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    final message = _viewModel.messages[index - 1];
                    return _buildMessageBubble(message);
                  },
                );
              }),
            ),
            Obx(() => _viewModel.isLoading.value 
              ? _buildTypingIndicator() 
              : const SizedBox.shrink()),
            _buildSuggestions(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage message) {
    final isMe = message.isUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe 
                  ? (Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white.withValues(alpha: 0.15) 
                      : Colors.black.withValues(alpha: 0.05))
                  : AppColors.primaryLight.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'CivicNet AI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : AppColors.textPrimaryLight,
                      fontSize: 15, 
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 60, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 20),
          const Text(
            'How can I help you today?',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Ask me about help requests, events, or news.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withValues(alpha: 0.6) 
                  : AppColors.textSecondaryLight, 
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'Upcoming events? 📅',
      'Who needs help? 🤝',
      'Community news 📰',
      'Find elder care 👵',
      'Tech support 💻',
      'Pet sitting 🐕',
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              label: Text(suggestions[index]),
              labelStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.primaryLight, 
                fontSize: 13, 
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withValues(alpha: 0.15) 
                  : AppColors.primaryLight.withValues(alpha: 0.1),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                _viewModel.sendMessage(suggestions[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white.withValues(alpha: 0.2) 
                            : AppColors.primaryLight.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask about your community...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white54 
                              : AppColors.textSecondaryLight,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false, // Prevents "2 colors" look from Theme
                      ),
                      onSubmitted: (val) {
                        _viewModel.sendMessage(val);
                        _controller.clear();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Obx(() => GestureDetector(
              onTap: _viewModel.isLoading.value 
                ? null 
                : () {
                    _viewModel.sendMessage(_controller.text);
                    _controller.clear();
                  },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient(Theme.of(context).brightness),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _viewModel.isLoading.value
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
            ),
            const SizedBox(width: 8),
            Text(
              'AI is thinking...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryLight.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
