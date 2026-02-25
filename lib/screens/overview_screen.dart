import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/camera_card.dart';

class OverviewScreen extends StatefulWidget {
  final bool isMonitoring;
  const OverviewScreen({super.key, required this.isMonitoring});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String _incidentPeriod = 'Day';

  // Mock data
  final List<FlSpot> _accuracyData = const [
    FlSpot(0, 89.5),
    FlSpot(1, 91.2),
    FlSpot(2, 90.8),
    FlSpot(3, 93.1),
    FlSpot(4, 92.4),
    FlSpot(5, 94.7),
    FlSpot(6, 94.2),
  ];

  final Map<String, List<double>> _incidentData = {
    'Day': [3, 7, 2, 5, 8, 4, 6],
    'Week': [18, 24, 15, 31, 22, 28, 19],
    'Month': [72, 95, 88, 110, 84, 97, 103],
  };

  final List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  Set<String> selectedBatches = {'Maingate'};
  final Map<String, int> batches = {
    'N-block pavements': 6,
    'Maingate': 4,
    'Admin block': 5,
    'S-Block Entrance': 2,
    'Multipurpose-hall': 3,
    'Small-gate': 2,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat Cards ──────────────────────────────────────────────────
          Row(
            children: [
              StatCard(
                label: 'Active Cameras',
                value: widget.isMonitoring ? '25/25' : '0/25',
                icon: Icons.videocam,
                accentColor: AppColors.statBlue,
              ),
              const SizedBox(width: 12),
              StatCard(
                label: 'Suspicious Activities',
                value: widget.isMonitoring ? '4' : '0',
                icon: Icons.warning_amber_rounded,
                accentColor: AppColors.statOrange,
              ),
              const SizedBox(width: 12),
              StatCard(
                label: 'Proper Disposals',
                value: widget.isMonitoring ? '12' : '0',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.statGreen,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Charts Row ───────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accuracy Trend
              Expanded(
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _chartHeader(
                        Icons.analytics_outlined,
                        'Accuracy Trend',
                        AppColors.brandBlue,
                        trailing: const Text(
                          'Last 7 days',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: LineChart(_buildAccuracyChart()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Incident Graph
              Expanded(
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _chartHeader(
                        Icons.bar_chart,
                        'Incidents',
                        AppColors.alertHigh,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              ['Day', 'Week', 'Month'].map((p) {
                                final selected = _incidentPeriod == p;
                                return GestureDetector(
                                  onTap:
                                      () => setState(() => _incidentPeriod = p),
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selected
                                              ? AppColors.brandBlue
                                              : AppColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p,
                                      style: TextStyle(
                                        color:
                                            selected
                                                ? Colors.white
                                                : AppColors.textMuted,
                                        fontSize: 11,
                                        fontWeight:
                                            selected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: BarChart(_buildIncidentChart()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Camera Feeds ─────────────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.videocam_outlined,
                      color: AppColors.brandBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Camera Feeds',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            widget.isMonitoring
                                ? AppColors.activeGreen
                                : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isMonitoring ? 'Live' : 'Idle',
                      style: TextStyle(
                        color:
                            widget.isMonitoring
                                ? AppColors.activeGreen
                                : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Batch selector
                const Text(
                  'Select Camera Batches to Display',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children:
                      batches.entries.map((entry) {
                        final isSelected = selectedBatches.contains(entry.key);
                        return InkWell(
                          onTap:
                              () => setState(() {
                                if (isSelected) {
                                  selectedBatches.remove(entry.key);
                                } else if (selectedBatches.length < 2) {
                                  selectedBatches.add(entry.key);
                                }
                              }),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppColors.brandBlue
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.brandBlue
                                            : AppColors.textMuted,
                                    width: 1.5,
                                  ),
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entry.key} (${entry.value})',
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                // Camera grids
                ...selectedBatches.map((batchName) {
                  final cameraCount = batches[batchName] ?? 0;
                  final displayCount = cameraCount > 4 ? 4 : cameraCount;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batchName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.6,
                            ),
                        itemCount: displayCount,
                        itemBuilder:
                            (context, index) => CameraCard(
                              name: '$batchName Cam ${index + 1}',
                              isMonitoring: widget.isMonitoring,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }

  Widget _chartHeader(
    IconData icon,
    String title,
    Color color, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  LineChartData _buildAccuracyChart() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine:
            (_) => FlLine(color: AppColors.cardBorder, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final i = value.toInt();
              if (i < 0 || i >= _dayLabels.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _dayLabels[i],
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget:
                (value, _) => Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: 80,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: _accuracyData,
          isCurved: true,
          color: AppColors.brandBlue,
          barWidth: 2.5,
          dotData: FlDotData(
            getDotPainter:
                (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.brandBlue,
                  strokeWidth: 2,
                  strokeColor: AppColors.cardBackground,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.brandBlue.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  BarChartData _buildIncidentChart() {
    final data = _incidentData[_incidentPeriod]!;
    return BarChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine:
            (_) => FlLine(color: AppColors.cardBorder, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final i = value.toInt();
              if (i < 0 || i >= _dayLabels.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _dayLabels[i],
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget:
                (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups:
          data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: AppColors.alertHigh,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (data.reduce((a, b) => a > b ? a : b) * 1.2),
                    color: AppColors.surface,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }
}
