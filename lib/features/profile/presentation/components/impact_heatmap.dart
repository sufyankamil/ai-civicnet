import 'package:flutter/material.dart';
import 'package:civic_net/theme/app_theme.dart';
import 'dart:math';

class HeatmapDay {
  final DateTime date;
  final int count;

  HeatmapDay(this.date, this.count);
}

class ImpactHeatmap extends StatelessWidget {
  final bool isDark;

  const ImpactHeatmap({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = _generateMockData();
    // Group into weeks (7 days each)
    final weeks = _groupIntoWeeks(data);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Community Presence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Show most recent weeks first
            child: Row(
              children: weeks.map((week) => _buildWeekColumn(context, week)).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildWeekColumn(BuildContext context, List<HeatmapDay> week) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        children: week.map((day) => _buildDaySquare(context, day)).toList(),
      ),
    );
  }

  Widget _buildDaySquare(BuildContext context, HeatmapDay day) {
    final color = _getColorForCount(day.count, isDark);
    
    return GestureDetector(
      onTap: () => _showDayTooltip(context, day),
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          boxShadow: day.count >= 5 ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            )
          ] : null,
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Less',
          style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[600]),
        ),
        const SizedBox(width: 4),
        ...[0, 2, 5, 8].map((count) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _getColorForCount(count, isDark),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        const SizedBox(width: 4),
        Text(
          'More',
          style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getColorForCount(int count, bool isDark) {
    if (count == 0) return isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!;
    if (count < 3) return const Color(0xFF7B61FF).withValues(alpha: 0.3);
    if (count < 6) return const Color(0xFF7B61FF).withValues(alpha: 0.6);
    return const Color(0xFF7B61FF); // High intensity
  }

  void _showDayTooltip(BuildContext context, HeatmapDay day) {
    final dateStr = '${day.date.day}/${day.date.month}';
    final msg = day.count == 0 
        ? 'No activities on $dateStr' 
        : '${day.count} neighbors helped on $dateStr';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 220,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<HeatmapDay> _generateMockData() {
    final List<HeatmapDay> data = [];
    final now = DateTime.now();
    final random = Random();

    // Generate last 6 months (approx 180 days)
    for (int i = 182; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // Randomly assign help counts (0-9)
      // More likely to have 0 or 1 on many days
      int count = 0;
      double roll = random.nextDouble();
      if (roll > 0.8) count = random.nextInt(4) + 1; // 1-4
      if (roll > 0.95) count = random.nextInt(5) + 5; // 5-9
      
      data.add(HeatmapDay(date, count));
    }
    return data;
  }

  List<List<HeatmapDay>> _groupIntoWeeks(List<HeatmapDay> data) {
    final List<List<HeatmapDay>> weeks = [];
    List<HeatmapDay> currentWeek = [];

    for (var day in data) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }
    // Add remaining days if any
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return weeks;
  }
}
