
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../components/primary_button.dart';
import '../../../../services/pending_toast_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Flow step data (self-contained so no import needed) ────────────────────

class _Step {
  final String emoji;
  final String title;
  final String desc;
  final Color color;
  const _Step(this.emoji, this.title, this.desc, this.color);
}

const _flowSteps = [
  _Step('📝', 'Post a Task',
      'Describe what you need — skill, location & urgency.',
      Color(0xFF4A90E2)),
  _Step('🔍', 'Smart Matching',
      'CivicNet ranks nearby helpers by skill, rating & availability.',
      Color(0xFF7B61FF)),
  _Step('🔔', 'Helpers Notified',
      'Push notifications ping eligible helpers in real time.',
      Color(0xFFFF9500)),
  _Step('🤝', 'Offer & Accept',
      'A helper taps "I can help". Requester reviews & accepts.',
      Color(0xFF50E3C2)),
  _Step('✅', 'Task Fulfilled',
      'Task marked done. Both parties rate each other.',
      Color(0xFF34C759)),
  _Step('⭐', 'Points & Trust',
      'Helper earns points & boosts their community trust score.',
      Color(0xFFFF6B6B)),
];

// ─── Main Screen ─────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Canvas animation controllers (only active on page 3)
  late final AnimationController _flowController;
  late final List<AnimationController> _nodeControllers;
  late final List<Animation<double>> _nodeAnims;
  bool _canvasAnimated = false;

  static const _infoPages = [
    (
      icon: Icons.handshake_rounded,
      title: 'Request Help Nearby',
      desc:
          'Post a request for any task — errands, repairs, or emergencies. Your neighbours are here to help.',
    ),
    (
      icon: Icons.volunteer_activism_rounded,
      title: 'Lend a Helping Hand',
      desc:
          'Browse local requests and assist your community. Earn trust and build a reputation as a top helper.',
    ),
    (
      icon: Icons.psychology_alt_rounded,
      title: 'AI-Powered Matching',
      desc:
          'Our smart AI connects you with the best helpers based on skills, location, and availability.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Consume any pending toast (e.g. account deletion success queued before auth redirect)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msg = PendingToastService().consumeSuccess();
      if (msg != null && mounted) {
        ToastService.showSuccess(context, msg);
      }
    });

    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _nodeControllers = List.generate(
      _flowSteps.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );
    _nodeAnims = _nodeControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.elasticOut))
        .toList();
  }

  void _triggerCanvasAnimation() {
    if (_canvasAnimated) return;
    _canvasAnimated = true;
    Future.microtask(() async {
      for (var i = 0; i < _nodeControllers.length; i++) {
        await Future.delayed(Duration(milliseconds: 100 * i));
        if (mounted) _nodeControllers[i].forward();
      }
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    for (final c in _nodeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _totalPages => _infoPages.length + 1; // 3 info + 1 canvas

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('has_seen_onboarding', true);
                  if (context.mounted) context.go('/login');
                },
                child: Text(
                  'Skip',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  if (index == _infoPages.length) _triggerCanvasAnimation();
                },
                itemBuilder: (context, index) {
                  if (index < _infoPages.length) {
                    return _buildInfoPage(index, isDark);
                  }
                  return _buildCanvasPage(isDark);
                },
              ),
            ),

            // Dots + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == i ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: _currentPage == _totalPages - 1
                        ? 'Get Started 🚀'
                        : 'Next',
                    onPressed: () async {
                      if (_currentPage < _totalPages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_seen_onboarding', true);
                        if (context.mounted) context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Info page ─────────────────────────────────────────────────────────────

  Widget _buildInfoPage(int index, bool isDark) {
    final page = _infoPages[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.1),
                  AppColors.secondaryLight.withValues(alpha: isDark ? 0.25 : 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              page.icon,
              size: 90,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Canvas page ───────────────────────────────────────────────────────────

  Widget _buildCanvasPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF7B61FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How CivicNet Works',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "A task's journey from post\nto fulfilment - step by step.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text('🚀', style: TextStyle(fontSize: 36)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Animated flow nodes
          ...List.generate(_flowSteps.length, (i) {
            final step = _flowSteps[i];
            final isLast = i == _flowSteps.length - 1;
            return Column(
              children: [
                ScaleTransition(
                  scale: _nodeAnims[i],
                  child: _buildStepCard(step, i, isDark),
                ),
                if (!isLast)
                  _buildConnector(
                    step.color,
                    _flowSteps[i + 1].color,
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStepCard(_Step step, int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: step.color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: step.color.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [step.color, step.color.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: step.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(step.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: step.color,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  step.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  step.desc,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(Color from, Color to) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          const SizedBox(width: 39),
          AnimatedBuilder(
            animation: _flowController,
            builder: (_, __) => CustomPaint(
              size: const Size(8, 32),
              painter: _PacketPainter(
                from: from,
                to: to,
                progress: _flowController.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Connector Painter ────────────────────────────────────────────────────────

class _PacketPainter extends CustomPainter {
  final Color from, to;
  final double progress;
  const _PacketPainter(
      {required this.from, required this.to, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..shader = LinearGradient(colors: [from, to]).createShader(
          Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dashes
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, (y + 5).clamp(0.0, size.height)), linePaint);
      y += 10;
    }

    // Animated packet
    final packetY = progress * size.height;
    final c = Color.lerp(from, to, progress)!;
    canvas.drawCircle(
        Offset(size.width / 2, packetY),
        6,
        Paint()
          ..color = c.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(
        Offset(size.width / 2, packetY), 3.5, Paint()..color = c);
  }

  @override
  bool shouldRepaint(_PacketPainter old) => old.progress != progress;
}
