import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AlertCategory { manualReview, faceNotDetected, emailNotSent }

class AlertItem {
  final String id;
  final String incidentRef;
  final String title;
  final String description;
  final String camera;
  final String timeAgo;
  final int confidence;
  final AlertCategory category;
  bool isDismissed;

  AlertItem({
    required this.id,
    required this.incidentRef,
    required this.title,
    required this.description,
    required this.camera,
    required this.timeAgo,
    required this.confidence,
    required this.category,
    this.isDismissed = false,
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late List<AlertItem> _alerts;
  final Set<String> _expanded = {'manual', 'face', 'email'};

  @override
  void initState() {
    super.initState();
    _alerts = [
      AlertItem(
        id: 'ALT-001',
        incidentRef: 'INC-003',
        title: 'Low Confidence Detection',
        description:
            'Littering event detected but confidence is below threshold. Manual review required.',
        camera: 'Camera 12 - Park Entrance',
        timeAgo: '18 min ago',
        confidence: 62,
        category: AlertCategory.manualReview,
      ),
      AlertItem(
        id: 'ALT-002',
        incidentRef: 'INC-005',
        title: 'Possible Illegal Dumping',
        description:
            'Suspicious behaviour detected near dumpster at 68% confidence.',
        camera: 'Camera 3 - Main Street',
        timeAgo: '42 min ago',
        confidence: 68,
        category: AlertCategory.manualReview,
      ),
      AlertItem(
        id: 'ALT-003',
        incidentRef: 'INC-006',
        title: 'Face Not Detected',
        description:
            'Littering confirmed but offender face could not be detected.\nFacial recognition unavailable.',
        camera: 'Camera 5 - South Gate',
        timeAgo: '1 hr ago',
        confidence: 91,
        category: AlertCategory.faceNotDetected,
      ),
      AlertItem(
        id: 'ALT-004',
        incidentRef: 'INC-007',
        title: 'Face Not Detected',
        description:
            'Offender wore face covering. Incident confirmed but identity unknown.',
        camera: 'Camera 9 - Parking Lot B',
        timeAgo: '2 hr ago',
        confidence: 85,
        category: AlertCategory.faceNotDetected,
      ),
      AlertItem(
        id: 'ALT-005',
        incidentRef: 'INC-008',
        title: 'Email Delivery Failed',
        description:
            'Offender identified but not in the system database. Fine notification could not be sent.',
        camera: 'Camera 7 - Central Park East',
        timeAgo: '3 hr ago',
        confidence: 93,
        category: AlertCategory.emailNotSent,
      ),
      AlertItem(
        id: 'ALT-006',
        incidentRef: 'INC-009',
        title: 'Email Delivery Failed',
        description: 'Email bounce — offender address invalid or mailbox full.',
        camera: 'Camera 2 - Main Entrance',
        timeAgo: '5 hr ago',
        confidence: 88,
        category: AlertCategory.emailNotSent,
      ),
    ];
  }

  List<AlertItem> _filtered(AlertCategory cat) =>
      _alerts.where((a) => a.category == cat && !a.isDismissed).toList();

  String _catLabel(AlertCategory c) {
    switch (c) {
      case AlertCategory.manualReview:
        return 'Needs Manual Review';
      case AlertCategory.faceNotDetected:
        return 'Face Not Detected';
      case AlertCategory.emailNotSent:
        return 'Email Not Sent';
    }
  }

  String _catKey(AlertCategory c) {
    switch (c) {
      case AlertCategory.manualReview:
        return 'manual';
      case AlertCategory.faceNotDetected:
        return 'face';
      case AlertCategory.emailNotSent:
        return 'email';
    }
  }

  Color _catColor(AlertCategory c) {
    switch (c) {
      case AlertCategory.manualReview:
        return AppColors.warningOrange;
      case AlertCategory.faceNotDetected:
        return AppColors.statPurple;
      case AlertCategory.emailNotSent:
        return AppColors.alertHigh;
    }
  }

  IconData _catIcon(AlertCategory c) {
    switch (c) {
      case AlertCategory.manualReview:
        return Icons.fact_check_outlined;
      case AlertCategory.faceNotDetected:
        return Icons.face_retouching_off;
      case AlertCategory.emailNotSent:
        return Icons.email_outlined;
    }
  }

  void _openReviewDialog(AlertItem alert) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder:
          (_) => _ReviewDialog(
            alert: alert,
            onIgnore: () {
              setState(() => alert.isDismissed = true);
              Navigator.of(context).pop();
            },
            onConfirm: () {
              setState(() => alert.isDismissed = true);
              Navigator.of(context).pop();
            },
            onFalsePositive: () {
              setState(() => alert.isDismissed = true);
              Navigator.of(context).pop();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalActive = _alerts.where((a) => !a.isDismissed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warningOrange,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'Alerts',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              if (totalActive > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.alertHigh.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.alertHigh.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '$totalActive active',
                    style: const TextStyle(
                      color: AppColors.alertHigh,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Sections
          for (final cat in AlertCategory.values) ...[
            _buildSection(cat),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(AlertCategory cat) {
    final items = _filtered(cat);
    final key = _catKey(cat);
    final color = _catColor(cat);
    final isExpanded = _expanded.contains(key);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Section header
          InkWell(
            onTap:
                () => setState(() {
                  if (isExpanded) {
                    _expanded.remove(key);
                  } else {
                    _expanded.add(key);
                  }
                }),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(_catIcon(cat), color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _catLabel(cat),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          items.isEmpty
                              ? AppColors.surface
                              : color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items.length}',
                      style: TextStyle(
                        color: items.isEmpty ? AppColors.textMuted : color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Section body
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No alerts in this category',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ...items.map((alert) => _buildAlertRow(alert, color)),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertRow(AlertItem alert, Color catColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent
          Container(
            width: 3,
            height: 50,
            decoration: BoxDecoration(
              color: catColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            alert.confidence >= 80
                                ? AppColors.surface
                                : AppColors.warningOrange.withValues(
                                  alpha: 0.1,
                                ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              alert.confidence >= 80
                                  ? AppColors.cardBorder
                                  : AppColors.warningOrange.withValues(
                                    alpha: 0.4,
                                  ),
                        ),
                      ),
                      child: Text(
                        '${alert.confidence}% conf.',
                        style: TextStyle(
                          color:
                              alert.confidence >= 80
                                  ? AppColors.textMuted
                                  : AppColors.warningOrange,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alert.id,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  alert.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.videocam_outlined,
                      color: AppColors.textMuted,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.camera,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      color: AppColors.textMuted,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.timeAgo,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Review button
          ElevatedButton.icon(
            onPressed: () => _openReviewDialog(alert),
            icon: const Icon(Icons.play_circle_outline, size: 15),
            label: const Text('Review', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: catColor.withValues(alpha: 0.15),
              foregroundColor: catColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: catColor.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full-screen review dialog ─────────────────────────────────────────────────
class _ReviewDialog extends StatefulWidget {
  final AlertItem alert;
  final VoidCallback onIgnore;
  final VoidCallback onConfirm;
  final VoidCallback onFalsePositive;

  const _ReviewDialog({
    required this.alert,
    required this.onIgnore,
    required this.onConfirm,
    required this.onFalsePositive,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
            ),
          ],
        ),
        child: Column(
          children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: AppColors.brandBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Review Incident — ${widget.alert.id}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.warningOrange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Awaiting Review',
                      style: TextStyle(
                        color: AppColors.warningOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: video + metadata
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Metadata
                          _metaRow('Alert ID', widget.alert.id),
                          _metaRow('Camera', widget.alert.camera),
                          _metaRow('Confidence', '${widget.alert.confidence}%'),
                          _metaRow('Time', widget.alert.timeAgo),
                          _metaRow('Description', widget.alert.description),
                          const SizedBox(height: 16),
                          // Video player
                          _videoWidget(),
                        ],
                      ),
                    ),
                  ),
                  // Vertical divider
                  const VerticalDivider(width: 1, color: AppColors.cardBorder),
                  // Right: action panel
                  SizedBox(
                    width: 260,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Review Actions',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Select the outcome for this alert after reviewing the evidence.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Mark as Resolved
                          _dialogActionBtn(
                            label: 'Mark as Resolved',
                            sublabel: 'Close this alert — incident handled',
                            icon: Icons.check_circle_outline,
                            color: AppColors.activeGreen,
                            onTap: widget.onConfirm,
                          ),
                          const SizedBox(height: 10),

                          // Mark False Positive
                          _dialogActionBtn(
                            label: 'Mark as False Positive',
                            sublabel:
                                'Dismiss — incident was\nnot actual littering',
                            icon: Icons.cancel_outlined,
                            color: AppColors.alertHigh,
                            onTap: widget.onFalsePositive,
                          ),
                          const SizedBox(height: 10),

                          // Ignore
                          _dialogActionBtn(
                            label: 'Ignore & Delete',
                            sublabel:
                                'Remove this alert from\nthe review queue',
                            icon: Icons.delete_outline,
                            color: AppColors.textMuted,
                            onTap: widget.onIgnore,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoWidget() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.play_circle_outline,
                color: AppColors.textMuted.withValues(alpha: 0.5),
                size: 56,
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '● EVIDENCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.play_arrow,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '0:00',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.crop_free,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogActionBtn({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              onTap != null ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                onTap != null
                    ? color.withValues(alpha: 0.3)
                    : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: onTap != null ? color : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: onTap != null ? color : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
