import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/camera_card.dart';

class CameraFeedsScreen extends StatefulWidget {
  final bool isMonitoring;

  const CameraFeedsScreen({super.key, required this.isMonitoring});

  @override
  State<CameraFeedsScreen> createState() => _CameraFeedsScreenState();
}

class _CameraFeedsScreenState extends State<CameraFeedsScreen> {
  Set<String> selectedBatches = {'Backyard'};

  final Map<String, int> batches = {
    'Backyard': 5,
    'Central Park': 10,
    'Main Entrance': 3,
    'Parking Lot': 7,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
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
                label: 'Active Detections',
                value: '0',
                icon: Icons.visibility,
                accentColor: AppColors.statPurple,
              ),
              const SizedBox(width: 12),
              StatCard(
                label: 'Littering Incidents',
                value: '0',
                icon: Icons.warning_amber_rounded,
                accentColor: AppColors.statRed,
              ),
              const SizedBox(width: 12),
              StatCard(
                label: 'Proper Disposals',
                value: '0',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.statGreen,
              ),
              const SizedBox(width: 12),
              StatCard(
                label: 'Suspicious Actions',
                value: '0',
                icon: Icons.warning_amber_rounded,
                accentColor: AppColors.statOrange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Camera batch selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Camera Batches to Display',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Select up to 2 batches • All cameras are active when monitoring',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  children:
                      batches.entries.map((entry) {
                        final isSelected = selectedBatches.contains(entry.key);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedBatches.remove(entry.key);
                              } else if (selectedBatches.length < 2) {
                                selectedBatches.add(entry.key);
                              }
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
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
                                          size: 14,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
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
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${entry.value} cameras',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Camera grid for each selected batch
          ...selectedBatches.map((batchName) {
            final cameraCount = batches[batchName] ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      batchName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$cameraCount cameras',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: cameraCount > 4 ? 4 : cameraCount,
                  itemBuilder: (context, index) {
                    return CameraCard(
                      name: 'Camera ${index + 1}',
                      isMonitoring: widget.isMonitoring,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }
}
