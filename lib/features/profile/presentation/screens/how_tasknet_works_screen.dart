import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

// ─── Data Model ─────────────────────────────────────────────────────────────

class _FlowNode {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final List<String> nextIds;

  const _FlowNode({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.nextIds = const [],
  });
}

const _nodes = <_FlowNode>[
  _FlowNode(
    id: 'post',
    emoji: '📝',
    title: 'Post a Task',
    subtitle: 'User describes what they need — skill, location & urgency.',
    color: Color(0xFF4A90E2),
    nextIds: ['match'],
  ),
  _FlowNode(
    id: 'match',
    emoji: '🔍',
    title: 'Smart Matching',
    subtitle: 'CivicNet ranks nearby helpers by skill, rating & availability.',
    color: Color(0xFF7B61FF),
    nextIds: ['notify'],
  ),
  _FlowNode(
    id: 'notify',
    emoji: '🔔',
    title: 'Helpers Notified',
    subtitle: 'Push notifications ping eligible helpers in real time.',
    color: Color(0xFFFF9500),
    nextIds: ['offer'],
  ),
  _FlowNode(
    id: 'offer',
    emoji: '🤝',
    title: 'Offer & Accept',
    subtitle: 'A helper taps "I can help". Requester reviews & accepts.',
    color: Color(0xFF50E3C2),
    nextIds: ['fulfill'],
  ),
  _FlowNode(
    id: 'fulfill',
    emoji: '✅',
    title: 'Task Fulfilled',
    subtitle: 'Task is marked done. Both parties rate each other.',
    color: Color(0xFF34C759),
    nextIds: ['reward'],
  ),
  _FlowNode(
    id: 'reward',
    emoji: '⭐',
    title: 'Points & Trust',
    subtitle: 'Helper earns points & boosts their community trust score.',
    color: Color(0xFFFF6B6B),
    nextIds: [],
  ),
];

// ─── Screen ─────────────────────────────────────────────────────────────────

class HowTaskNetWorksScreen extends StatefulWidget {
  const HowTaskNetWorksScreen({super.key});

  @override
  State<HowTaskNetWorksScreen> createState() => _HowTaskNetWorksScreenState();
}

class _HowTaskNetWorksScreenState extends State<HowTaskNetWorksScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _flowController;
  late final List<AnimationController> _nodeControllers;
  late final List<Animation<double>> _nodeAnimations;

  int _activeNodeIndex = -1; // –1 = none selected

  @override
  void initState() {
    super.initState();

    // Continuous pulse on connector lines
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Packet travelling along the flow
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Staggered entrance for each node
    _nodeControllers = List.generate(
      _nodes.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _nodeAnimations = _nodeControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.elasticOut);
    }).toList();

    _startStaggeredEntrance();
  }

  Future<void> _startStaggeredEntrance() async {
    for (var i = 0; i < _nodeControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 120 * i));
      if (mounted) _nodeControllers[i].forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flowController.dispose();
    for (final c in _nodeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onNodeTap(int index) {
    setState(() {
      _activeNodeIndex = _activeNodeIndex == index ? -1 : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeroHeader(isDark),
                _buildFlowCanvas(isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'How CivicNet Works',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'v1.1',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Hero Header ──────────────────────────────────────────────────────────

  Widget _buildHeroHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF7B61FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  'The Journey of a Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'From posting to fulfillment — see\nhow your request flows through\nthe CivicNet ecosystem.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildAnimatedOrb(),
        ],
      ),
    );
  }

  Widget _buildAnimatedOrb() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = (0.5 + 0.5 * _pulseController.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 70 * pulse,
              height: 70 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08 * (2 - pulse)),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Center(
                child: Text('🚀', style: TextStyle(fontSize: 26)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Flow Canvas ──────────────────────────────────────────────────────────

  Widget _buildFlowCanvas(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('⚡ Interactive Flow', isDark),
          const SizedBox(height: 4),
          Text(
            'Tap any step to learn more',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_nodes.length, (i) {
            return _buildNodeWithConnector(i, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildNodeWithConnector(int index, bool isDark) {
    final node = _nodes[index];
    final isLast = index == _nodes.length - 1;
    final isActive = _activeNodeIndex == index;

    return Column(
      children: [
        ScaleTransition(
          scale: _nodeAnimations[index],
          child: GestureDetector(
            onTap: () => _onNodeTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive
                    ? node.color.withValues(alpha: isDark ? 0.25 : 0.12)
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? node.color : node.color.withValues(alpha: 0.2),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? node.color.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: isActive ? 16 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Step Badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [node.color, node.color.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: node.color.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        node.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Step ${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: node.color,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Spacer(),
                            AnimatedRotation(
                              turns: isActive ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: node.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          node.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: isActive
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox(height: 0),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              node.subtitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast) _buildConnectorLine(node.color, _nodes[index + 1].color),
      ],
    );
  }

  Widget _buildConnectorLine(Color fromColor, Color toColor) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 42), // align with node icon center
          AnimatedBuilder(
            animation: _flowController,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(8, 44),
                painter: _ConnectorPainter(
                  fromColor: fromColor,
                  toColor: toColor,
                  progress: _flowController.value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ─── Custom Painter ──────────────────────────────────────────────────────────

class _ConnectorPainter extends CustomPainter {
  final Color fromColor;
  final Color toColor;
  final double progress;

  const _ConnectorPainter({
    required this.fromColor,
    required this.toColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dashed gradient line
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [fromColor, toColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dashHeight = 6.0;
    const dashSpace = 5.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }

    // Animated data-packet dot travelling down
    final packetY = progress * size.height;
    final packetPaint = Paint()
      ..color = Color.lerp(fromColor, toColor, progress)!
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Color.lerp(fromColor, toColor, progress)!.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, packetY), 7, glowPaint);
    canvas.drawCircle(Offset(size.width / 2, packetY), 4, packetPaint);
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.progress != progress || old.fromColor != fromColor || old.toColor != toColor;
}
