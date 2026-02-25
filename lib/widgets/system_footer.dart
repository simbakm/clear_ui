import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SystemFooter extends StatelessWidget {
  const SystemFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    return Container(
      height: 36,
      color: isDark ? AppColors.surface : AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _metric(Icons.circle, '25/25 Cameras Online', AppColors.activeGreen),
          _divider(),
          _metric(Icons.timer_outlined, 'Uptime: 99.8%', AppColors.brandBlue),
          _divider(),
          _metric(
            Icons.analytics_outlined,
            'Accuracy: 94.2%',
            AppColors.statPurple,
          ),
          _divider(),
          _metric(
            Icons.warning_amber_rounded,
            '3 Pending Alerts',
            AppColors.warningOrange,
          ),
          _divider(),
          _metric(
            Icons.access_time,
            'Last Detection: 2 min ago',
            AppColors.textMuted,
          ),
          const Spacer(),
          Text(
            'CLEAR Monitoring System v1.0',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      width: 1,
      height: 14,
      color:
          themeNotifier.value == ThemeMode.dark
              ? AppColors.cardBorder
              : AppColors.borderLight,
    );
  }
}
