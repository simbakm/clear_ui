import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'mjpeg_view.dart';

class CameraCard extends StatelessWidget {
  final String name;
  final bool isMonitoring;
  final String? streamUrl;
  final String? statusLabel;
  final VoidCallback? onOpenFullScreen;

  const CameraCard({
    super.key,
    required this.name,
    required this.isMonitoring,
    this.streamUrl,
    this.statusLabel,
    this.onOpenFullScreen,
  });

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
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.videocam_outlined,
                      color:
                          isMonitoring
                              ? AppColors.brandBlue.withValues(alpha: 0.7)
                              : AppColors.textMuted.withValues(alpha: 0.3),
                      size: 28,
                    ),
                  ),
                  if (isMonitoring &&
                      streamUrl != null &&
                      streamUrl!.isNotEmpty)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        child: MjpegView(url: streamUrl!),
                      ),
                    ),
                  if (isMonitoring &&
                      streamUrl != null &&
                      streamUrl!.isNotEmpty &&
                      onOpenFullScreen != null)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: InkWell(
                        onTap: onOpenFullScreen,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
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
                  statusLabel ?? (isMonitoring ? 'LIVE' : 'OFF'),
                  style: TextStyle(
                    color:
                        statusLabel == 'UNAVAILABLE'
                            ? AppColors.alertHigh
                            : isMonitoring
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
