import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../viewmodels/ai_assistant_viewmodel.dart';

/// Full-screen Aura AI Community Intelligence assistant with high-contrast Liquid Glass UI.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final AiAssistantViewModel _viewModel = Get.put(AiAssistantViewModel());
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  void _sendMessage([String? presetText]) {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _viewModel.isLoading.value) return;

    AppHaptic.mediumImpact();
    if (presetText == null) {
      _controller.clear();
    }
    _viewModel.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(context, isDark),
      body: Stack(
        children: [
          // Subtle futuristic ambient aura glow at top
          Positioned(
            top: -120,
            left: -40,
            right: -40,
            height: 320,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.9,
                    colors: [
                      AppColors.auraPrimary.withValues(
                        alpha: isDark ? 0.20 : 0.10,
                      ),
                      AppColors.auraSecondary.withValues(
                        alpha: isDark ? 0.08 : 0.03,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main chat column
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Info beta badge
                _buildBetaDisclaimer(isDark),

                // Messages list
                Expanded(
                  child: Obx(() {
                    _scrollToBottom();
                    if (_viewModel.messages.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount:
                          _viewModel.messages.length +
                          (_viewModel.isLoading.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _viewModel.messages.length) {
                          return _buildTypingIndicator(isDark);
                        }

                        final message = _viewModel.messages[index];
                        return _buildMessageBubble(message, isDark);
                      },
                    );
                  }),
                ),

                // Quick prompt suggestions
                _buildSuggestions(isDark),

                // Modern high-contrast input area
                _buildInputArea(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
          size: 20,
        ),
        onPressed: () {
          AppHaptic.lightImpact();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppColors.auraGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.auraPrimary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Aura AI',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'INTELLIGENCE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981), // Emerald
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Neighborhood Guide • Live',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFA09BB8)
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      actions: [
        IconButton(
          tooltip: 'Clear Chat',
          icon: Icon(
            Icons.refresh_rounded,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            size: 22,
          ),
          onPressed: () {
            AppHaptic.lightImpact();
            _viewModel.clearChat();
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBetaDisclaimer(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10, left: 16, right: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDark.withValues(alpha: 0.75)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Community AI is in beta and may show inaccurate info.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFA09BB8)
                        : AppColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage message, bool isDark) {
    final isMe = message.isUser;
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                gradient: AppColors.auraGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.auraPrimary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe ? AppColors.auraGradient : null,
                color: isMe
                    ? null
                    : (isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.95)
                          : Colors.white),
                borderRadius: bubbleRadius,
                border: Border.all(
                  color: isMe
                      ? Colors.transparent
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? AppColors.auraPrimary.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CivicNet AI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildFormattedContent(message.text, isMe, isDark),
                  const SizedBox(height: 6),
                  Text(
                    timeago.format(message.timestamp, locale: 'en_short'),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : (isDark
                                ? const Color(0xFFA09BB8)
                                : AppColors.textSecondaryLight),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String content, bool isMe, bool isDark) {
    final baseColor = isMe
        ? Colors.white
        : (isDark ? const Color(0xFFF9F9FB) : AppColors.textPrimaryLight);

    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: content.substring(lastMatchEnd, match.start),
            style: TextStyle(color: baseColor, fontSize: 14.5, height: 1.45),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: baseColor,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(lastMatchEnd),
          style: TextStyle(color: baseColor, fontSize: 14.5, height: 1.45),
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.auraGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.auraPrimary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How can I help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me about urgent requests, tools to borrow, upcoming events, or neighborhood assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFA09BB8)
                    : AppColors.textSecondaryLight,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    final suggestions = [
      '🚨 Urgent requests near me',
      '🛠️ Borrow tools & items',
      '🎉 Upcoming community events',
      '👵 Find elder care',
      '💻 Tech support needed',
      '🤝 How to earn Karma?',
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _sendMessage(suggestion),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark.withValues(alpha: 0.85)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppColors.primaryLight.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.04,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.95)
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark.withValues(alpha: 0.8)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask Aura AI about your community...',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: isDark
                          ? const Color(0xFFA09BB8)
                          : const Color(0xFF9CA3AF),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(
              () => GestureDetector(
                onTap: _viewModel.isLoading.value ? null : () => _sendMessage(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.auraGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.auraPrimary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _viewModel.isLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.95)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Aura AI is thinking...',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFA09BB8)
                    : AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
