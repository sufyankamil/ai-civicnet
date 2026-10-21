import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../../../services/ai_service.dart';
import '../../../../../services/toast_service.dart';
import '../../../../../widgets/haptic_buttons.dart';

/// Modal bottom sheet providing one-tap voice recognition and Gemini auto-categorization.
class VoiceTaskSheet extends StatefulWidget {
  const VoiceTaskSheet({super.key});

  static Future<ParsedVoiceTask?> show(BuildContext context) {
    return showModalBottomSheet<ParsedVoiceTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceTaskSheet(),
    );
  }

  @override
  State<VoiceTaskSheet> createState() => _VoiceTaskSheetState();
}

class _VoiceTaskSheetState extends State<VoiceTaskSheet>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late final AnimationController _pulseController;

  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isAnalyzing = false;
  String _recognizedWords = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initSpeechAndStart();
  }

  Future<void> _initSpeechAndStart() async {
    final micStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();

    if (!micStatus.isGranted) {
      if (mounted) {
        if (micStatus.isPermanentlyDenied) {
          ToastService.showInfo(
            context,
            'Microphone access is disabled. Please enable it in Settings.',
          );
          await openAppSettings();
        } else {
          ToastService.showInfo(
            context,
            'Microphone permission is needed for voice-to-task',
          );
        }
      }
      return;
    }

    if (!speechStatus.isGranted && !speechStatus.isLimited) {
      if (mounted) {
        if (speechStatus.isPermanentlyDenied) {
          ToastService.showInfo(
            context,
            'Speech recognition is disabled. Please enable it in Settings.',
          );
          await openAppSettings();
        } else {
          ToastService.showInfo(
            context,
            'Speech recognition permission is needed for voice-to-task',
          );
        }
      }
      return;
    }

    try {
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
              setState(() => _isListening = false);
            }
          }
        },
      );

      if (_speechEnabled && mounted) {
        _startListening();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _speechEnabled = false);
      }
    }
  }

  Future<void> _startListening() async {
    // If not initialized yet, attempt initialization
    if (!_speechEnabled || !_speech.isAvailable) {
      try {
        _speechEnabled = await _speech.initialize(
          onError: (error) {
            if (mounted) setState(() => _isListening = false);
          },
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted && _isListening) {
                setState(() => _isListening = false);
              }
            }
          },
        );
      } catch (_) {
        _speechEnabled = false;
      }
    }

    if (!_speechEnabled || !_speech.isAvailable) {
      if (mounted) {
        setState(() => _isListening = false);
        ToastService.showInfo(
          context,
          'Speech recognition is unavailable on this simulator/device. Tap "Insert sample voice prompt" below to test!',
        );
      }
      return;
    }

    AppHaptic.mediumImpact();
    setState(() {
      _isListening = true;
      _recognizedWords = '';
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _recognizedWords = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        ToastService.showInfo(context, 'Unable to listen: $e');
      }
    }
  }

  void _stopListening() {
    AppHaptic.lightImpact();
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _processTranscript() async {
    final text = _recognizedWords.trim();
    if (text.isEmpty) {
      ToastService.showInfo(context, 'Please speak your request first');
      return;
    }

    _stopListening();
    setState(() => _isAnalyzing = true);

    try {
      final aiService = AiService();
      final parsed = await aiService.parseVoiceTask(text);
      if (!mounted) return;
      AppHaptic.mediumImpact();
      Navigator.of(context).pop(parsed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ToastService.showError(context, 'Could not analyze voice note');
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryAccent = Color(0xFF7B61FF);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF131124).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.94),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: primaryAccent.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryAccent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: primaryAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Voice Assistant',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                          ),
                          Text(
                            'Speak naturally. AI will auto-fill your request.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pulsing Mic Button
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _isListening
                        ? 1.0 + (_pulseController.value * 0.12)
                        : 1.0;
                    final glowRadius = _isListening
                        ? 20.0 + (_pulseController.value * 20.0)
                        : 8.0;

                    return GestureDetector(
                      onTap: _isAnalyzing
                          ? null
                          : () {
                              if (_isListening) {
                                _stopListening();
                              } else if (!_speechEnabled) {
                                _initSpeechAndStart();
                              } else {
                                _startListening();
                              }
                            },
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B61FF), Color(0xFF9D4EDD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryAccent.withValues(
                                alpha: _isListening ? 0.6 : 0.25,
                              ),
                              blurRadius: glowRadius,
                              spreadRadius: _isListening ? 4 : 1,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: scale,
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Listening Status Text
                Text(
                  _isAnalyzing
                      ? 'Analyzing with Gemini AI...'
                      : _isListening
                      ? 'Listening... Speak now'
                      : _recognizedWords.isNotEmpty
                      ? 'Tap to re-record or Auto-Fill below'
                      : 'Tap microphone to speak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isListening
                        ? primaryAccent
                        : isDark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),

                // Transcript Box
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 80,
                    maxHeight: 150,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isListening
                          ? primaryAccent.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _recognizedWords.isEmpty
                          ? (_isListening
                                ? 'Say something like: "My kitchen pipe is leaking water everywhere, I need an urgent plumber with a wrench..."'
                                : 'Your spoken words will appear here in real time.')
                          : _recognizedWords,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: _recognizedWords.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: _recognizedWords.isEmpty
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : (isDark ? Colors.white : Colors.black87),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Helper prompt button for simulator testing / quick demo
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () {
                            AppHaptic.selectionClick();
                            setState(() {
                              _recognizedWords =
                                  'My kitchen sink pipe is leaking water all over the floor, need urgent plumbing help with a wrench!';
                            });
                          },
                    icon: const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: primaryAccent,
                    ),
                    label: Text(
                      'Insert demo prompt',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryAccent.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_recognizedWords.trim().isEmpty || _isAnalyzing)
                            ? null
                            : _processTranscript,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                          _isAnalyzing ? 'Processing...' : 'Auto-Fill Request',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
