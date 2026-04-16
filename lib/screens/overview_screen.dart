import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/camera_card.dart';
import '../models/camera.dart';
import '../config/locations.dart';
import '../widgets/full_screen_camera_dialog.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../models/incident.dart';
import 'package:intl/intl.dart';

class OverviewScreen extends StatefulWidget {
  final bool isMonitoring;
  final bool isDiscovering;
  final String? discoveryError;
  final Map<String, List<Camera>> camerasByLocation;

  const OverviewScreen({
    super.key,
    required this.isMonitoring,
    required this.isDiscovering,
    required this.camerasByLocation,
    this.discoveryError,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final DateFormat _dayFormat = DateFormat('EEE');
  final DateFormat _monthFormat = DateFormat('MMM');
  final DateFormat _weekFormat = DateFormat('MMM d');

  bool _isLoadingIncidents = false;
  String? _incidentError;
  List<Incident> _incidents = [];

  String _incidentPeriod = 'Day';
  Set<String> selectedBatches = {};

  List<String> get _allLocations {
    final extra =
        widget.camerasByLocation.keys
            .where((k) => !kCameraLocations.contains(k))
            .toList();
    return [...kCameraLocations, ...extra];
  }

  Map<String, int> get batches => {
    for (final loc in _allLocations)
      loc: widget.camerasByLocation[loc]?.length ?? 0,
  };

  int get totalCameras =>
      widget.camerasByLocation.values.fold(0, (sum, list) => sum + list.length);

  void _syncSelections() {
    final keys = batches.keys.toList();
    selectedBatches.removeWhere((k) => !keys.contains(k));
    if (selectedBatches.isEmpty && keys.isNotEmpty) {
      selectedBatches.add(keys.first);
      if (keys.length > 1) {
        selectedBatches.add(keys[1]);
      }
    }
  }

  void _openFullScreen(Camera cam) {
    final streamUrl = ApiConfig.getCameraStreamUrl(cam.id);
    showDialog(
      context: context,
      builder:
          (_) => FullScreenCameraDialog(
            title: '${cam.cameraName} • ${cam.location}',
            streamUrl: streamUrl,
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _syncSelections();
    _loadIncidents();
  }

  @override
  void didUpdateWidget(covariant OverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camerasByLocation != widget.camerasByLocation) {
      _syncSelections();
    }
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoadingIncidents = true;
      _incidentError = null;
    });
    try {
      final incidents = await ApiService.getIncidents();
      if (!mounted) return;
      setState(() {
        _incidents = incidents;
        _isLoadingIncidents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _incidentError = 'Failed to load incidents.';
        _isLoadingIncidents = false;
      });
    }
  }

  List<DateTime> _lastNDays(int count) {
    final today = DateTime.now();
    return List.generate(count, (i) {
      final day = today.subtract(Duration(days: count - 1 - i));
      return DateTime(day.year, day.month, day.day);
    });
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  List<DateTime> _lastNWeeks(int count) {
    final start = _startOfWeek(DateTime.now());
    return List.generate(count, (i) {
      final weekStart = start.subtract(Duration(days: (count - 1 - i) * 7));
      return DateTime(weekStart.year, weekStart.month, weekStart.day);
    });
  }

  List<DateTime> _lastNMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final month = DateTime(now.year, now.month - (count - 1 - i), 1);
      return DateTime(month.year, month.month, 1);
    });
  }

  List<FlSpot> _buildAccuracyData() {
    final days = _lastNDays(7);
    final data = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final matches = _incidents.where((incident) {
        final created = incident.createdAt;
        return created.year == day.year &&
            created.month == day.month &&
            created.day == day.day &&
            incident.hasConfidence;
      }).toList();

      final avg = matches.isEmpty
          ? 0.0
          : matches
                  .map((e) => e.confidenceScore * 100)
                  .reduce((a, b) => a + b) /
              matches.length;
      data.add(FlSpot(i.toDouble(), avg));
    }
    return data;
  }

  List<double> _buildIncidentCounts(String period) {
    if (period == 'Day') {
      final days = _lastNDays(7);
      return days.map((day) {
        return _incidents.where((incident) {
          final created = incident.createdAt;
          return created.year == day.year &&
              created.month == day.month &&
              created.day == day.day;
        }).length.toDouble();
      }).toList();
    }
    if (period == 'Week') {
      final weeks = _lastNWeeks(7);
      return weeks.map((weekStart) {
        final weekEnd = weekStart.add(const Duration(days: 7));
        return _incidents.where((incident) {
          final created = incident.createdAt;
          return !created.isBefore(weekStart) && created.isBefore(weekEnd);
        }).length.toDouble();
      }).toList();
    }

    final months = _lastNMonths(7);
    return months.map((monthStart) {
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
      return _incidents.where((incident) {
        final created = incident.createdAt;
        return !created.isBefore(monthStart) && created.isBefore(monthEnd);
      }).length.toDouble();
    }).toList();
  }

  List<String> _buildIncidentLabels(String period) {
    if (period == 'Day') {
      return _lastNDays(7).map((d) => _dayFormat.format(d)).toList();
    }
    if (period == 'Week') {
      return _lastNWeeks(7).map((w) => _weekFormat.format(w)).toList();
    }
    return _lastNMonths(7).map((m) => _monthFormat.format(m)).toList();
  }

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
                value:
                    widget.isMonitoring
                        ? '$totalCameras/$totalCameras'
                        : '0/$totalCameras',
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
                        trailing:
                            _isLoadingIncidents
                                ? const Text(
                                  'Loading...',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                )
                                : const Text(
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
                      if (_incidentError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _incidentError!,
                          style: const TextStyle(
                            color: AppColors.alertHigh,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
                if (widget.isDiscovering) ...[
                  Row(
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Discovering cameras...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ] else if (widget.discoveryError != null) ...[
                  Text(
                    widget.discoveryError!,
                    style: const TextStyle(
                      color: AppColors.alertHigh,
                      fontSize: 13,
                    ),
                  ),
                ],
                const Text(
                  'Select Camera Locations to Display',
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
                ...selectedBatches.map((batchName) {
                  final cameras = widget.camerasByLocation[batchName] ?? [];
                  final showPlaceholders =
                      !widget.isMonitoring || cameras.isEmpty;
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
                        itemCount: showPlaceholders ? 4 : cameras.length,
                        itemBuilder: (context, index) {
                          if (showPlaceholders) {
                            return CameraCard(
                              name: 'Unavailable',
                              isMonitoring: false,
                              statusLabel: 'UNAVAILABLE',
                            );
                          }
                          final cam = cameras[index];
                          final streamUrl = ApiConfig.getCameraStreamUrl(
                            cam.id,
                          );
                          return CameraCard(
                            name: cam.cameraName,
                            isMonitoring: widget.isMonitoring,
                            streamUrl: streamUrl,
                            onOpenFullScreen: () => _openFullScreen(cam),
                          );
                        },
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
    final accuracyData = _buildAccuracyData();
    final dayLabels = _buildIncidentLabels('Day');
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
                if (i < 0 || i >= dayLabels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dayLabels[i],
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
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: accuracyData,
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
    final data = _buildIncidentCounts(_incidentPeriod);
    final labels = _buildIncidentLabels(_incidentPeriod);
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
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
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
                    toY: (data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b) * 1.2),
                    color: AppColors.surface,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }
}


