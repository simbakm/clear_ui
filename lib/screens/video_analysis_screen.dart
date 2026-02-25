import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Shared incident model used by Video Analysis, Detection History, and Alerts
class IncidentModel {
  final String id;
  final String type;
  final String date;
  final String time;
  final String location;
  final String cameraId;
  final String cameraName;
  final int confidence;
  final String status; // 'pending', 'confirmed', 'false_positive', 'resolved'
  final String? offenderName;
  final String duration;
  final String? argumentMessage;

  const IncidentModel({
    required this.id,
    required this.type,
    required this.date,
    required this.time,
    required this.location,
    required this.cameraId,
    required this.cameraName,
    required this.confidence,
    required this.status,
    this.offenderName,
    required this.duration,
    this.argumentMessage,
  });
}

final List<IncidentModel> mockIncidents = [
  const IncidentModel(
    id: 'INC-001',
    type: 'Littering',
    date: '2026-02-25',
    time: '14:32:15',
    location: 'S-Block Entrance',
    cameraId: 'CAM-S01',
    cameraName: 'S-Block Entrance Cam 1',
    confidence: 94,
    status: 'confirmed',
    offenderName: 'Simbarashe Sandi',
    duration: '00:00:12',
    argumentMessage: '"This was unintentional as the trash bin was full."',
  ),
  const IncidentModel(
    id: 'INC-002',
    type: 'Illegal Dumping',
    date: '2026-02-25',
    time: '13:45:22',
    location: 'Maingate',
    cameraId: 'CAM-MG1',
    cameraName: 'Maingate Camera 1',
    confidence: 87,
    status: 'confirmed',
    offenderName: 'John Mudemo',
    duration: '00:02:34',
    argumentMessage:
        '"I was clearing some debris but will dispose of it properly next time."',
  ),
  const IncidentModel(
    id: 'INC-003',
    type: 'Littering',
    date: '2026-02-25',
    time: '12:18:09',
    location: 'N-Block',
    cameraId: 'CAM-N01',
    cameraName: 'N-Block Camera 1',
    confidence: 76,
    status: 'confirmed',
    offenderName: 'Sandra Mbudzi',
    duration: '00:00:08',
    argumentMessage:
        '"I accidentally dropped my wrapper while rushing to class."',
  ),
  const IncidentModel(
    id: 'INC-004',
    type: 'Littering',
    date: '2026-02-24',
    time: '09:05:44',
    location: 'Multipurpose-hall',
    cameraId: 'CAM-MPH1',
    cameraName: 'Multipurpose-hall Cam 1',
    confidence: 91,
    status: 'confirmed',
    offenderName: 'Blessing Musoni',
    duration: '00:00:19',
    argumentMessage:
        '"Noticed others littering and assumed it was okay, I apologize."',
  ),
];

class VideoAnalysisScreen extends StatefulWidget {
  final IncidentModel? preSelectedIncident;
  const VideoAnalysisScreen({super.key, this.preSelectedIncident});

  @override
  State<VideoAnalysisScreen> createState() => _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends State<VideoAnalysisScreen> {
  IncidentModel? _selectedIncident;
  final Map<String, String> _incidentStatus = {};
  final Map<String, bool> _facialRecogDone = {};

  @override
  void initState() {
    super.initState();
    _selectedIncident = widget.preSelectedIncident;
    for (final inc in mockIncidents) {
      _incidentStatus[inc.id] = inc.status;
    }
  }

  @override
  void didUpdateWidget(VideoAnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preSelectedIncident != null &&
        widget.preSelectedIncident != oldWidget.preSelectedIncident) {
      setState(() => _selectedIncident = widget.preSelectedIncident);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.activeGreen;
      case 'false_positive':
        return AppColors.alertHigh;
      default:
        return AppColors.warningOrange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'false_positive':
        return 'False Positive';
      default:
        return 'Pending Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Incident List ──────────────────────────────────────
          SizedBox(
            width: 340,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          color: AppColors.brandBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Littering Incidents',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${mockIncidents.length}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: mockIncidents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final inc = mockIncidents[i];
                        final status = _incidentStatus[inc.id] ?? inc.status;
                        final isSelected = _selectedIncident?.id == inc.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedIncident = inc),
                          borderRadius: BorderRadius.circular(6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.brandBlue.withValues(
                                        alpha: 0.12,
                                      )
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.brandBlue.withValues(
                                          alpha: 0.4,
                                        )
                                        : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        inc.type,
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? AppColors.brandBlue
                                                  : AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _statusBadge(status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${inc.date} ${inc.time}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${inc.cameraName} · ${inc.confidence}% confidence',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── Right: Detail Panel ──────────────────────────────────────
          Expanded(
            child:
                _selectedIncident == null
                    ? _buildEmptyState()
                    : _buildDetailPanel(_selectedIncident!),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.4),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select an incident to review',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Click any incident from the list on the left',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel(IncidentModel inc) {
    final status = _incidentStatus[inc.id] ?? inc.status;
    final facialDone = _facialRecogDone[inc.id] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${inc.type} — ${inc.id}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${inc.date}  ${inc.time}  ·  ${inc.cameraName}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _statusBadge(status, large: true),
              ],
            ),
            const SizedBox(height: 20),

            // Metadata grid
            _metadataGrid(inc, status),
            const SizedBox(height: 20),

            // Video player
            _videoPlayer(),
            const SizedBox(height: 20),

            // Action buttons
            _actionButtons(inc, status, facialDone),
          ],
        ),
      ),
    );
  }

  Widget _metadataGrid(IncidentModel inc, String status) {
    final items = [
      ['Incident ID', inc.id],
      ['Type', inc.type],
      ['Date', inc.date],
      ['Time', inc.time],
      ['Camera', inc.cameraName],
      ['Location', inc.location],
      ['Confidence', '${inc.confidence}%'],
      ['Duration', inc.duration],
      ['Status', _statusLabel(status)],
      ['Alleged Offender', inc.offenderName ?? 'Unknown / Not Detected'],
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.brandBlue, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Incident Details',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items.map((item) {
                  return SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item[0],
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item[1],
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
          if (inc.argumentMessage != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.cardBorder),
            const SizedBox(height: 8),
            const Text(
              'Offender Argument',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              inc.argumentMessage!,
              style: const TextStyle(
                color: AppColors.warningOrange,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _videoPlayer() {
    return Container(
      height: 260,
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
                size: 64,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      trackHeight: 3,
                      activeTrackColor: AppColors.brandBlue,
                      inactiveTrackColor: AppColors.textMuted.withValues(
                        alpha: 0.3,
                      ),
                      thumbColor: AppColors.brandBlue,
                    ),
                    child: Slider(value: 0, onChanged: (_) {}),
                  ),
                  Row(
                    children: const [
                      Icon(
                        Icons.play_arrow,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '0:00 / 0:12',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.volume_up_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.crop_free,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '● REC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(IncidentModel inc, String status, bool facialDone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (status == 'pending') ...[
          Row(
            children: [
              _actionBtn(
                label: 'Confirm Littering',
                icon: Icons.check_circle_outline,
                color: AppColors.activeGreen,
                onTap:
                    () => setState(() => _incidentStatus[inc.id] = 'confirmed'),
              ),
              const SizedBox(width: 10),
              _actionBtn(
                label: 'Mark as False Positive',
                icon: Icons.cancel_outlined,
                color: AppColors.alertHigh,
                onTap:
                    () => setState(
                      () => _incidentStatus[inc.id] = 'false_positive',
                    ),
              ),
            ],
          ),
        ] else if (status == 'confirmed') ...[
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.activeGreen, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Littering Confirmed',
                style: TextStyle(
                  color: AppColors.activeGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionBtn(
                label:
                    facialDone
                        ? 'Facial Recognition Re-run'
                        : 'Rerun Facial Recognition',
                icon: Icons.face_outlined,
                color: AppColors.brandBlue,
                onTap: () => setState(() => _facialRecogDone[inc.id] = true),
              ),
            ],
          ),
          if (facialDone) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _actionBtn(
                  label: 'Send Email Again',
                  icon: Icons.email_outlined,
                  color: AppColors.statPurple,
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  label: 'Ignore & Delete Incident',
                  icon: Icons.delete_outline,
                  color: AppColors.alertHigh,
                  onTap: () {
                    setState(() {
                      mockIncidents.removeWhere((item) => item.id == inc.id);
                      _selectedIncident = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ] else if (status == 'false_positive') ...[
          Row(
            children: [
              Icon(Icons.cancel, color: AppColors.alertHigh, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Marked as False Positive',
                style: TextStyle(
                  color: AppColors.alertHigh,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _actionBtn(
            label: 'Restore and Confirm',
            icon: Icons.history,
            color: AppColors.textMuted,
            onTap: () => setState(() => _incidentStatus[inc.id] = 'confirmed'),
          ),
        ],
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              onTap != null ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                onTap != null
                    ? color.withValues(alpha: 0.4)
                    : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onTap != null ? color : AppColors.textMuted,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? color : AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, {bool large = false}) {
    final color = _statusColor(status);
    final label = _statusLabel(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: large ? 12 : 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
