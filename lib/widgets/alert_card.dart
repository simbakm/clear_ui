import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AlertSeverity { high, medium, low }

class AlertCardData {
  final String title;
  final AlertSeverity severity;
  final int confidence;
  final String description;
  final String camera;
  final String timeAgo;
  final bool showAcknowledge;

  const AlertCardData({
    required this.title,
    required this.severity,
    required this.confidence,
    required this.description,
    required this.camera,
    required this.timeAgo,
    this.showAcknowledge = false,
  });
}

class AlertCard extends StatelessWidget {
  final AlertCardData data;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final VoidCallback? onDismiss;

  const AlertCard({
    super.key,
    required this.data,
    this.onAcknowledge,
    this.onResolve,
    this.onDismiss,
  });

  Color get _severityColor {
    switch (data.severity) {
      case AlertSeverity.high:
        return AppColors.alertHigh;
      case AlertSeverity.medium:
        return AppColors.alertMedium;
      case AlertSeverity.low:
        return AppColors.alertLow;
    }
  }

  String get _severityLabel {
    switch (data.severity) {
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.medium:
        return 'MEDIUM';
      case AlertSeverity.low:
        return 'LOW';
    }
  }

  IconData get _severityIcon {
    switch (data.severity) {
      case AlertSeverity.high:
        return Icons.warning_rounded;
      case AlertSeverity.medium:
        return Icons.access_time_rounded;
      case AlertSeverity.low:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _severityColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _severityColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(_severityIcon, color: _severityColor, size: 20),
              const SizedBox(width: 8),
              Text(
                data.title,
                style: TextStyle(
                  color: _severityColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _severityLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${data.confidence}% confidence',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              // Action buttons
              if (data.showAcknowledge) ...[
                OutlinedButton(
                  onPressed: onAcknowledge,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.activeGreen,
                    side: const BorderSide(color: AppColors.activeGreen),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Acknowledge',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton(
                onPressed: onResolve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.activeGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Resolve', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            data.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          // Meta info
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.textMuted,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                data.camera,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                data.timeAgo,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
