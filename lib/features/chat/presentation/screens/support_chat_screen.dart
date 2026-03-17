import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:civic_net/features/chat/viewmodels/support_view_model.dart';
import '../../../../models/models.dart';
import '../../../../theme/app_theme.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final SupportViewModel _viewModel = Get.put(SupportViewModel());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.startNewSession();
    // Listen for session completion to auto-redirect
    ever(_viewModel.isSessionFinished, (isFinished) {
      if (isFinished && mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        backgroundColor: isDark ? const Color(0xFF0F1117) : Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Support Chat',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              size: 28,
            ),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Obx(() {
                    if (_viewModel.isLoading.value && _viewModel.messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator.adaptive());
                    }

                    if (_viewModel.errorMessage.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                _viewModel.errorMessage.value,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(color: isDark ? Colors.white70 : Colors.black54),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => _viewModel.startNewSession(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryLight,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_viewModel.messages.isEmpty && !_viewModel.isTyping.value) {
                      return Center(
                        child: Text(
                          'Connecting to support...',
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }

                    // Auto-scroll to bottom
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: _viewModel.messages.length + (_viewModel.isTyping.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _viewModel.messages.length) {
                          return _buildTypingIndicator(isDark);
                        }

                        final message = _viewModel.messages[index];
                        final isMe = message.senderType == SupportSenderType.user;
                        final isLast = index == _viewModel.messages.length - 1;

                        return Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            _buildMessageBubble(message, isMe, isDark),
                            if (!isMe &&
                                message.options != null &&
                                isLast &&
                                !_viewModel.isTyping.value)
                              _buildOptions(message.options!, isDark),
                          ],
                        );
                      },
                    );
                  }),
                ),
                Obx(() {
                  if (_viewModel.isWaitingForInput.value) {
                    return _buildInputField(isDark);
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
            // Redirection Overlay
            Obx(() {
              if (_viewModel.isSessionFinished.value) {
                return Container(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator.adaptive(),
                        const SizedBox(height: 16),
                        Text(
                          'Redirecting you...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryLight
              : (isDark ? const Color(0xFF1E222D) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            if (!isMe)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(message.createdAt, locale: 'en_short'),
              style: GoogleFonts.poppins(
                color: isMe
                    ? Colors.white70
                    : (isDark ? Colors.white54 : Colors.grey[500]),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(List<String> options, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 20, top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          return InkWell(
            onTap: () async {
              if (option == 'Exit') {
                final navigator = Navigator.of(context);
                final shouldPop = await _onWillPop();
                if (shouldPop) {
                  if (_viewModel.isFeedbackState.value) {
                    navigator.pop();
                  } else {
                    _viewModel.prepareFeedbackSession();
                  }
                }
              } else {
                _viewModel.selectOption(option);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primaryLight.withValues(alpha: 0.15) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                option,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.primaryLight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222D) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.white30 : Colors.grey[300],
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Exit Support?'),
        content: const Text(
            'Once you exit, you will need to re-initiate the chat for any further help.'),
        actions: [
          if (Theme.of(context).platform == TargetPlatform.iOS) ...[
            CupertinoDialogAction(
              child: const Text('Cancel'),
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
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              onPressed: () {
                _viewModel.closeSession();
                Navigator.of(context).pop(true);
              },
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ]
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildInputField(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1117) : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222D) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[300]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.typeMessageHint,
                    hintStyle: GoogleFonts.poppins(
                      color: isDark ? Colors.white38 : Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                final text = _messageController.text.trim();
                if (text.isNotEmpty) {
                  if (_viewModel.isFeedbackState.value) {
                    _viewModel.submitExitFeedback(text);
                  } else {
                    _viewModel.sendFreeTextMessage(text);
                  }
                  _messageController.clear();
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primaryLight.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
