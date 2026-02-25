import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DetectionCardData {
  final String type;
  final String date;
  final String location;
  final String cameraId;
  final int confidence;
  final bool isConfirmed;
  final String duration;

  const DetectionCardData({
    required this.type,
    required this.date,
    required this.location,
    required this.cameraId,
    required this.confidence,
    required this.isConfirmed,
    required this.duration,
  });
}

class DetectionCard extends StatelessWidget {
  final DetectionCardData data;
  final VoidCallback? onView;

  const DetectionCard({super.key, required this.data, this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Left side - detection info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.type,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppColors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.date,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.location,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      data.cameraId,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right side - confidence, badge, duration, view
          Row(
            children: [
              Text(
                '${data.confidence}% confidence',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color:
                      data.isConfirmed
                          ? AppColors.confirmedGreen.withValues(alpha: 0.2)
                          : AppColors.falsePositiveRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        data.isConfirmed
                            ? AppColors.confirmedGreen
                            : AppColors.falsePositiveRed,
                    width: 1,
                  ),
                ),
                child: Text(
                  data.isConfirmed ? 'confirmed' : 'false positive',
                  style: TextStyle(
                    color:
                        data.isConfirmed
                            ? AppColors.confirmedGreen
                            : AppColors.falsePositiveRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                data.duration,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onView,
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'View',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
