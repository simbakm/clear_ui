import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/incident.dart';
import '../models/dispute.dart';
import '../widgets/incident_video_player.dart';

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

class VideoAnalysisScreen extends StatefulWidget {
  final IncidentModel? preSelectedIncident;
  const VideoAnalysisScreen({super.key, this.preSelectedIncident});

  @override
  State<VideoAnalysisScreen> createState() => _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends State<VideoAnalysisScreen> {
  static const int _pageSize = 4;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  bool _isLoading = false;
  String? _error;
  int _pageIndex = 0;
  List<Incident> _incidents = [];
  Incident? _selectedIncident;
  int? _pendingSelectId;

  bool _isLoadingDisputes = false;
  List<Dispute> _disputes = [];
  final Map<int, String> _offenderNameCache = {};

  void _showActionToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedIncident != null) {
      final idStr = widget.preSelectedIncident!.id.replaceAll('INC-', '');
      _pendingSelectId = int.tryParse(idStr);
    }
    _loadIncidents();
  }

  @override
  void didUpdateWidget(VideoAnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preSelectedIncident != null &&
        widget.preSelectedIncident != oldWidget.preSelectedIncident) {
      final idStr = widget.preSelectedIncident!.id.replaceAll('INC-', '');
      final id = int.tryParse(idStr);
      if (id != null) {
        _pendingSelectId = id;
        final found = _incidents.where((i) => i.id == id).toList();
        if (found.isNotEmpty) {
          _selectIncident(found.first);
        }
      }
    }
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final incidents = await ApiService.getIncidents();
      if (!mounted) return;
      incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _incidents = incidents;
        _isLoading = false;
        _pageIndex = 0;
        _selectedIncident = null;
        _disputes = [];
        _isLoadingDisputes = false;
      });
      if (_pendingSelectId != null) {
        final found = incidents.where((i) => i.id == _pendingSelectId).toList();
        if (found.isNotEmpty) {
          _selectIncident(found.first);
          return;
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load incidents.';
        _isLoading = false;
      });
    }
  }

  void _selectIncident(Incident inc) {
    setState(() => _selectedIncident = inc);
    _loadDisputes(inc.id);
    _loadOffenderName(inc.offenderId);
  }

  Future<void> _loadOffenderName(int? offenderId) async {
    if (offenderId == null) return;
    if (_offenderNameCache.containsKey(offenderId)) return;
    final offender = await ApiService.getOffender(offenderId);
    if (!mounted) return;
    if (offender != null) {
      setState(() {
        _offenderNameCache[offenderId] = offender.name;
      });
    }
  }

  Future<void> _loadDisputes(int incidentId) async {
    setState(() {
      _isLoadingDisputes = true;
      _disputes = [];
    });
    final disputes = await ApiService.getDisputes(incidentId);
    if (!mounted) return;
    setState(() {
      _disputes = disputes;
      _isLoadingDisputes = false;
    });

    for (final dispute in disputes) {
      final offenderId = dispute.offenderId;
      if (offenderId != null && !_offenderNameCache.containsKey(offenderId)) {
        final offender = await ApiService.getOffender(offenderId);
        if (!mounted) return;
        if (offender != null) {
          setState(() {
            _offenderNameCache[offenderId] = offender.name;
          });
        }
      }
    }
  }

  String _statusOf(Incident incident) {
    final status = incident.status.toUpperCase();
    if (status.isEmpty || status == 'UNKNOWN') return 'PENDING';
    return status;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return AppColors.activeGreen;
      case 'REJECTED':
        return AppColors.alertHigh;
      case 'ESCALATED':
        return AppColors.warningOrange;
      default:
        return AppColors.warningOrange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Confirmed';
      case 'REJECTED':
        return 'Rejected';
      case 'ESCALATED':
        return 'Escalated';
      default:
        return 'Pending Review';
    }
  }

  String _incidentIdLabel(int id) => 'INC-${id.toString().padLeft(3, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = _incidents.length;
    final start = _pageIndex * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    final pageItems = total == 0 ? <Incident>[] : _incidents.sublist(start, end);

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
                            '$total',
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
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : _error != null
                            ? Center(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.alertHigh,
                                  fontSize: 12,
                                ),
                              ),
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: pageItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 4),
                              itemBuilder: (context, i) {
                                final inc = pageItems[i];
                                final status = _statusOf(inc);
                                final isSelected = _selectedIncident?.id == inc.id;
                                return InkWell(
                                  onTap: () => _selectIncident(inc),
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
                                                inc.incidentType.isEmpty
                                                    ? 'Unknown'
                                                    : inc.incidentType,
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
                                          '${_dateFormat.format(inc.createdAt)} ${_timeFormat.format(inc.createdAt)}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          'Camera ${inc.cameraId} · ${(inc.confidenceScore * 100).round()}% confidence',
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
                  if (!_isLoading && _error == null && total > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${start + 1}-${end} of $total',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed:
                                _pageIndex == 0
                                    ? null
                                    : () => setState(() => _pageIndex -= 1),
                            child: const Text('Previous'),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed:
                                end >= total
                                    ? null
                                    : () => setState(() => _pageIndex += 1),
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── Right: Detail Panel + Action Tab ─────────────────────────
          Expanded(
            child:
                _selectedIncident == null
                    ? _buildEmptyState()
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildDetailPanel(_selectedIncident!),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildActionTab(),
                        ),
                      ],
                    ),
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
              'select incident to view',
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

  Widget _buildActionTab() {
    final hasSelection = _selectedIncident != null;
    final hasArgument = !_isLoadingDisputes && _disputes.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: AppColors.brandBlue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Actions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed:
                  hasSelection
                      ? () => _showActionToast(
                        'Rerun facial recognition (not wired yet).',
                      )
                      : null,
              icon: const Icon(Icons.face_retouching_natural_outlined, size: 18),
              label: const Text('Rerun facial recognition'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.brandBlue.withValues(
                  alpha: 0.25,
                ),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed:
                  hasSelection && hasArgument
                      ? () => _showActionToast(
                        'Reject Dispute (not wired yet).',
                      )
                      : null,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject Dispute'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.stopRed,
                side: BorderSide(
                  color: AppColors.stopRed.withValues(alpha: 0.7),
                ),
                disabledForegroundColor: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed:
                  hasSelection && hasArgument
                      ? () => _showActionToast(
                        'Accept Dispute (not wired yet).',
                      )
                      : null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accept Dispute'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.activeGreen,
                side: BorderSide(
                  color: AppColors.activeGreen.withValues(alpha: 0.7),
                ),
                disabledForegroundColor: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!hasSelection)
            const Text(
              'Select an incident to enable actions.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          else if (_isLoadingDisputes)
            const Text(
              'Loading arguments...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          else if (!hasArgument)
            const Text(
              'No argument found for this incident.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(Incident inc) {
    final status = _statusOf(inc);
    final offenderName =
        inc.offenderId != null
            ? (_offenderNameCache[inc.offenderId!] ?? 'Loading...')
            : 'Unknown / Not Detected';

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
                      '${inc.incidentType} — ${_incidentIdLabel(inc.id)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_dateFormat.format(inc.createdAt)}  ${_timeFormat.format(inc.createdAt)}  ·  Camera ${inc.cameraId}',
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
            _metadataGrid(inc, status, offenderName),
            const SizedBox(height: 20),

            // Video player
            IncidentVideoPlayer(videoPath: inc.videoPath, height: 260),
            const SizedBox(height: 20),

            // Disputes
            _disputesPanel(),
          ],
        ),
      ),
    );
  }

  Widget _metadataGrid(Incident inc, String status, String offenderName) {
    final items = [
      ['Incident ID', _incidentIdLabel(inc.id)],
      ['Type', inc.incidentType.isEmpty ? 'Unknown' : inc.incidentType],
      ['Date', _dateFormat.format(inc.createdAt)],
      ['Time', _timeFormat.format(inc.createdAt)],
      ['Camera', 'Camera ${inc.cameraId}'],
      ['Location', 'Unknown'],
      ['Confidence', '${(inc.confidenceScore * 100).round()}%'],
      ['Duration', '-'],
      ['Status', _statusLabel(status)],
      ['Alleged Offender', offenderName],
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
        ],
      ),
    );
  }

  Widget _disputesPanel() {
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
              Icon(Icons.forum_outlined, color: AppColors.statPurple, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Disputes / Arguments',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingDisputes)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_disputes.isEmpty)
            const Text(
              'No disputes found for this incident.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          else
            Column(
              children:
                  _disputes.map((d) {
                    final offenderName =
                        d.offenderId != null
                            ? (_offenderNameCache[d.offenderId!] ?? 'Loading...')
                            : 'Unknown';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Reason: ${d.reason}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                d.status,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Submitted by: $offenderName',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
        ],
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
