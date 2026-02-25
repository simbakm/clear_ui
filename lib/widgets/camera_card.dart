import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CameraCard extends StatelessWidget {
  final String name;
  final bool isMonitoring;

  const CameraCard({super.key, required this.name, required this.isMonitoring});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feed area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.videocam_outlined,
                  color:
                      isMonitoring
                          ? AppColors.brandBlue.withValues(alpha: 0.7)
                          : AppColors.textMuted.withValues(alpha: 0.3),
                  size: 28,
                ),
              ),
            ),
          ),
          // Label row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        isMonitoring
                            ? AppColors.activeGreen
                            : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  isMonitoring ? 'LIVE' : 'OFF',
                  style: TextStyle(
                    color:
                        isMonitoring
                            ? AppColors.activeGreen
                            : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
