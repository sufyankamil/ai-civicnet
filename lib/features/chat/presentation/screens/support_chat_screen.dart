import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../l10n/app_localizations.dart';
import '../../../../models/models.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../viewmodels/support_view_model.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final SupportViewModel _viewModel = Get.put(SupportViewModel());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (_viewModel.conversationId.isEmpty) {
      _viewModel.startNewSession();
    }

    // Listen for session completion to auto-redirect
    ever(_viewModel.isSessionFinished, (isFinished) {
      if (isFinished && mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
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

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _viewModel.isTyping.value) return;

    AppHaptic.mediumImpact();
    _messageController.clear();
    _viewModel.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          if (_viewModel.isFeedbackState.value) {
            navigator.pop();
          } else {
            _viewModel.prepareFeedbackSession();
          }
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(isDark),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Obx(() {
                    if (_viewModel.isLoading.value &&
                        _viewModel.messages.isEmpty) {
                      return _buildInitialLoadingState(isDark);
                    }

                    if (_viewModel.errorMessage.isNotEmpty &&
                        _viewModel.messages.isEmpty) {
                      return _buildErrorState(isDark);
                    }

                    // Auto-scroll when new messages or typing state changes
                    _scrollToBottom();

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount:
                          _viewModel.messages.length +
                          (_viewModel.isTyping.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _viewModel.messages.length) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _AiTypingIndicator(),
                          );
                        }

                        final message = _viewModel.messages[index];
                        final isMe =
                            message.senderType == SupportSenderType.user;
                        final isLast = index == _viewModel.messages.length - 1;

                        return Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            _buildMessageBubble(message, isMe, isDark),
                            if (!isMe &&
                                message.options != null &&
                                message.options!.isNotEmpty &&
                                isLast &&
                                !_viewModel.isTyping.value)
                              _buildOptions(message.options!, isDark),
                          ],
                        );
                      },
                    );
                  }),
                ),

                // Liquid Glass Input Bar (Always accessible)
                _buildLiquidGlassInputBar(isDark),
              ],
            ),

            // Redirection / Finished Overlay
            Obx(() {
              if (_viewModel.isSessionFinished.value) {
                return _buildFinishedOverlay(isDark);
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: AppHaptic(
        onTap: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Icon(
          Icons.chevron_left_rounded,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
          size: 30,
        ),
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
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CivicNet Assistant',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981), // Emerald online dot
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AI Guide • Online',
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
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Start Fresh Session',
          icon: Icon(
            Icons.refresh_rounded,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            size: 22,
          ),
          onPressed: () => _confirmResetSession(isDark),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildInitialLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primaryLight,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Connecting to CivicNet AI Guide...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                AppHaptic.mediumImpact();
                _viewModel.startNewSession();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message, bool isMe, bool isDark) {
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
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                gradient: AppColors.auraGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.auraPrimary.withValues(alpha: 0.3),
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
                          ? AppColors.surfaceDark.withValues(alpha: 0.9)
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
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildFormattedContent(message.content, isMe, isDark),
                  const SizedBox(height: 6),
                  Text(
                    timeago.format(message.createdAt, locale: 'en_short'),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : (isDark
                                ? const Color(0xFFA09BB8)
                                : Colors.grey[500]),
                      fontSize: 10,
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

  /// Parses simple bold tags `**bold**` into formatted TextSpans for rich AI readability
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
            style: TextStyle(color: baseColor, fontSize: 14, height: 1.45),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: baseColor,
            fontWeight: FontWeight.w700,
            fontSize: 14,
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
          style: TextStyle(color: baseColor, fontSize: 14, height: 1.45),
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }

  Widget _buildOptions(List<String> options, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 38, bottom: 16, top: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          return AppHaptic(
            onTap: () {
              if (option == 'Exit') {
                _handleExitOption();
              } else {
                _viewModel.selectOption(option);
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryLight.withValues(alpha: 0.16)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.45),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLiquidGlassInputBar(bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark.withValues(alpha: 0.6)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)?.typeMessageHint ??
                            'Ask anything about CivicNet...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFFA09BB8)
                              : Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() {
                  final isTyping = _viewModel.isTyping.value;
                  return AppHaptic(
                    onTap: isTyping ? null : _handleSendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isTyping
                            ? LinearGradient(
                                colors: [Colors.grey[600]!, Colors.grey[700]!],
                              )
                            : AppColors.auraGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!isTyping)
                            BoxShadow(
                              color: AppColors.auraPrimary.withValues(
                                alpha: 0.35,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildFinishedOverlay(bool isDark) {
    return Container(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.auraGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Thank you for using CivicNet Support!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Redirecting you...',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFA09BB8) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExitOption() async {
    final navigator = Navigator.of(context);
    final shouldPop = await _onWillPop();
    if (shouldPop) {
      if (_viewModel.isFeedbackState.value) {
        navigator.pop();
      } else {
        _viewModel.prepareFeedbackSession();
      }
    }
  }

  Future<void> _confirmResetSession(bool isDark) async {
    AppHaptic.mediumImpact();
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Start New Chat?'),
        content: const Text(
          'This will archive your current support session and start a fresh conversation with the AI assistant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Start Fresh',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _viewModel.startNewSession(forceNew: true);
    }
  }

  Future<bool> _onWillPop() async {
    AppHaptic.lightImpact();
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Exit Support?'),
        content: const Text(
          'Do you want to close this session? Your conversation history remains securely saved in your account.',
        ),
        actions: [
          if (Theme.of(context).platform == TargetPlatform.iOS) ...[
            CupertinoDialogAction(
              child: const Text('Stay'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                _viewModel.closeSession();
                Navigator.of(context).pop(true);
              },
              child: const Text('Exit'),
            ),
          ] else ...[
            TextButton(
              child: const Text('Stay'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              onPressed: () {
                _viewModel.closeSession();
                Navigator.of(context).pop(true);
              },
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
    return result ?? false;
  }
}

/// Animated 3-dot pulsating indicator with subtle Liquid Glass aura
class _AiTypingIndicator extends StatefulWidget {
  const _AiTypingIndicator();

  @override
  State<_AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<_AiTypingIndicator>
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: 8, top: 2),
          decoration: BoxDecoration(
            gradient: AppColors.auraGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 15,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.9)
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
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
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7 * scale,
                    height: 7 * scale,
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
