import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../viewmodels/ai_assistant_viewmodel.dart';

/// Modern Liquid Glass Bottom Sheet for quick Aura AI interactions from the Home Screen.
class AuraAiSheet extends StatefulWidget {
  const AuraAiSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => const AuraAiSheet(),
    );
  }

  @override
  State<AuraAiSheet> createState() => _AuraAiSheetState();
}

class _AuraAiSheetState extends State<AuraAiSheet> {
  final AiAssistantViewModel _viewModel = Get.put(AiAssistantViewModel());
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const List<String> _suggestedPrompts = [
    '🚨 Urgent requests near me',
    '🛠️ Borrow tools & items',
    '🎉 Upcoming community events',
    '💡 How does AI matching work?',
    '🤝 How do I earn Karma points?',
  ];

  @override
  void dispose() {
    _textController.dispose();
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

  void _handleSend([String? presetText]) {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _viewModel.isLoading.value) return;

    AppHaptic.mediumImpact();
    if (presetText == null) {
      _textController.clear();
    }
    _viewModel.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.95)
        : Colors.white;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: screenHeight * 0.75,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.auraPrimary.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                _buildHeader(context, isDark),

                const Divider(height: 1, thickness: 0.8),

                // Suggested Prompts Carousel
                _buildSuggestedPrompts(isDark),

                // Messages List
                Expanded(
                  child: Obx(() {
                    _scrollToBottom();

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount:
                          _viewModel.messages.length +
                          (_viewModel.isLoading.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _viewModel.messages.length) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _AuraTypingIndicator(),
                          );
                        }

                        final message = _viewModel.messages[index];
                        return _buildMessageBubble(message, isDark);
                      },
                    );
                  }),
                ),

                // Single unified Capsule Input Bar
                _buildInputBar(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.auraGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.auraPrimary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                        letterSpacing: -0.2,
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimaryLight,
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
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expand to full-screen action
          IconButton(
            tooltip: 'Expand full screen',
            icon: Icon(
              Icons.open_in_full_rounded,
              size: 20,
              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            ),
            onPressed: () {
              AppHaptic.lightImpact();
              Navigator.pop(context);
              context.push('/ai-assistant');
            },
          ),

          // Clear chat action
          IconButton(
            tooltip: 'Clear conversation',
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            ),
            onPressed: () {
              AppHaptic.lightImpact();
              _viewModel.clearChat();
            },
          ),

          // Close modal action
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 22,
              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            ),
            onPressed: () {
              AppHaptic.lightImpact();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts(bool isDark) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedPrompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _suggestedPrompts[index];
          return AppHaptic(
            onTap: () => _handleSend(prompt),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryLight.withValues(alpha: 0.14)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(
                    alpha: isDark ? 0.35 : 0.25,
                  ),
                ),
              ),
              child: Text(
                prompt,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage message, bool isDark) {
    final isMe = message.isUser;
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                gradient: AppColors.auraGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? AppColors.auraGradient : null,
                color: isMe
                    ? null
                    : (isDark
                          ? AppColors.surfaceVariantDark.withValues(alpha: 0.9)
                          : Colors.grey[100]),
                borderRadius: bubbleRadius,
                border: Border.all(
                  color: isMe
                      ? Colors.transparent
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey[300]!),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? AppColors.auraPrimary.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildFormattedContent(message.text, isMe, isDark),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(message.timestamp, locale: 'en_short'),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : (isDark
                                ? const Color(0xFFA09BB8)
                                : Colors.grey[500]),
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
        : (isDark ? Colors.white : AppColors.textPrimaryLight);

    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: content.substring(lastMatchEnd, match.start),
            style: TextStyle(color: baseColor, fontSize: 13.5, height: 1.4),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: baseColor,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(lastMatchEnd),
          style: TextStyle(color: baseColor, fontSize: 13.5, height: 1.4),
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }

  Widget _buildInputBar(bool isDark) {
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
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 3,
                minLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: 'Ask Aura AI anything about your area...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFFA09BB8)
                        : const Color(0xFF9CA3AF),
                    fontSize: 13.5,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceVariantDark.withValues(alpha: 0.8)
                      : const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(
                      color: AppColors.primaryLight,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Obx(() {
              final isLoading = _viewModel.isLoading.value;
              return AppHaptic(
                onTap: isLoading ? null : () => _handleSend(),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isLoading
                        ? LinearGradient(
                            colors: [Colors.grey[600]!, Colors.grey[700]!],
                          )
                        : AppColors.auraGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!isLoading)
                        BoxShadow(
                          color: AppColors.auraPrimary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AuraTypingIndicator extends StatefulWidget {
  const _AuraTypingIndicator();

  @override
  State<_AuraTypingIndicator> createState() => _AuraTypingIndicatorState();
}

class _AuraTypingIndicatorState extends State<_AuraTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: AppColors.auraGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 13,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDark.withValues(alpha: 0.9)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey[300]!,
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final progress = (_controller.value + delay) % 1.0;
                  final scale = 0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2));
                  final opacity =
                      0.3 + (0.7 * (1 - (progress - 0.5).abs() * 2));

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 6 * scale,
                    height: 6 * scale,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(
                        alpha: opacity.clamp(0.2, 1.0),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}
