import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'video_analysis_screen.dart';

class DetectionHistoryScreen extends StatelessWidget {
  /// Called when user taps "View" — navigates to Video Analysis with that incident
  final void Function(IncidentModel)? onOpenIncident;

  const DetectionHistoryScreen({super.key, this.onOpenIncident});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.history, color: AppColors.brandBlue, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Detection History',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Filter chips
                _filterChip('All', true),
                const SizedBox(width: 6),
                _filterChip('Confirmed', false),
                const SizedBox(width: 6),
                _filterChip('False Positive', false),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Click any incident to view full evidence and details in Video Analysis.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Column headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  _th('Incident ID', flex: 1),
                  _th('Type', flex: 2),
                  _th('Date / Time', flex: 2),
                  _th('Camera', flex: 3),
                  _th('Confidence', flex: 2),
                  _th('Duration', flex: 1),
                  _th('Status', flex: 2),
                  _th('', flex: 1),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Rows
            ...mockIncidents.map(
              (inc) => _IncidentRow(
                incident: inc,
                onView: () => onOpenIncident?.call(inc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? AppColors.brandBlue : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? AppColors.brandBlue : AppColors.cardBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _IncidentRow extends StatefulWidget {
  final IncidentModel incident;
  final VoidCallback? onView;
  const _IncidentRow({required this.incident, this.onView});

  @override
  State<_IncidentRow> createState() => _IncidentRowState();
}

class _IncidentRowState extends State<_IncidentRow> {
  bool _hovered = false;

  Color get _statusColor {
    switch (widget.incident.status) {
      case 'confirmed':
        return AppColors.activeGreen;
      case 'false_positive':
        return AppColors.alertHigh;
      default:
        return AppColors.warningOrange;
    }
  }

  String get _statusLabel {
    switch (widget.incident.status) {
      case 'confirmed':
        return 'Confirmed';
      case 'false_positive':
        return 'False Positive';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              _hovered
                  ? AppColors.brandBlue.withValues(alpha: 0.06)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border(
            bottom: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                widget.incident.id,
                style: const TextStyle(
                  color: AppColors.brandBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.incident.type,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${widget.incident.date}\n${widget.incident.time}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.incident.cameraName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    '${widget.incident.confidence}%',
                    style: TextStyle(
                      color:
                          widget.incident.confidence >= 80
                              ? AppColors.activeGreen
                              : AppColors.warningOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.incident.duration,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _statusColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: widget.onView,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: AppColors.brandBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'View',
                      style: TextStyle(
                        color: AppColors.brandBlue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
