import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/incident.dart';
import 'video_analysis_screen.dart';

class DetectionHistoryScreen extends StatefulWidget {
  /// Called when user taps "View" — navigates to Video Analysis with that incident
  final void Function(IncidentModel)? onOpenIncident;

  const DetectionHistoryScreen({super.key, this.onOpenIncident});

  @override
  State<DetectionHistoryScreen> createState() => _DetectionHistoryScreenState();
}

class _DetectionHistoryScreenState extends State<DetectionHistoryScreen> {
  static const int _pageSize = 10;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  final List<String> _filters = const [
    'All',
    'PENDING',
    'CONFIRMED',
    'REJECTED',
    'ESCALATED',
  ];

  bool _isLoading = false;
  String? _error;
  List<Incident> _incidents = [];
  String _statusFilter = 'All';
  bool _sortAscending = false;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final incidents = await ApiService.getIncidents();
      if (!mounted) return;
      setState(() {
        _incidents = incidents;
        _isLoading = false;
        _pageIndex = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load incidents.';
        _isLoading = false;
      });
    }
  }

  List<Incident> get _filteredIncidents {
    List<Incident> list = List.from(_incidents);
    if (_statusFilter != 'All') {
      list = list
          .where((i) => _statusOf(i) == _statusFilter)
          .toList();
    }
    list.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
    });
    return list;
  }

  String _statusOf(Incident incident) {
    final status = incident.status.toUpperCase();
    if (status.isEmpty || status == 'UNKNOWN') return 'PENDING';
    return status;
  }

  IncidentModel _toModel(Incident incident) {
    final date = incident.createdAt;
    final confidence = (incident.confidenceScore * 100).round();
    final status = _statusOf(incident).toLowerCase();
    return IncidentModel(
      id: 'INC-${incident.id.toString().padLeft(3, '0')}',
      type: incident.incidentType.isEmpty ? 'Unknown' : incident.incidentType,
      date: _dateFormat.format(date),
      time: _timeFormat.format(date),
      location: 'Unknown',
      cameraId: incident.cameraId.toString(),
      cameraName:
          incident.cameraId == 0 ? 'Unknown Camera' : 'Camera ${incident.cameraId}',
      confidence: confidence,
      status: status.toLowerCase(),
      duration: '-',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIncidents;
    final start = _pageIndex * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    final shown = filtered.sublist(start, end);

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
                ..._filters.expand((label) {
                  final selected = _statusFilter == label;
                  return [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _statusFilter = label;
                          _pageIndex = 0;
                        });
                      },
                      child: _filterChip(label, selected),
                    ),
                    const SizedBox(width: 6),
                  ];
                }).toList()
                  ..removeLast(),
                const SizedBox(width: 12),
                _sortControl(),
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.alertHigh,
                    fontSize: 12,
                  ),
                ),
              )
            else if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No incidents found.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              )
            else
              ...shown.map(
                (inc) {
                  final model = _toModel(inc);
                  return _IncidentRow(
                    incident: model,
                    onView: () => widget.onOpenIncident?.call(model),
                  );
                },
              ),
            if (!_isLoading && _error == null && filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${start + 1}-${end} of ${filtered.length}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          end >= filtered.length
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

  Widget _sortControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Text(
            'Sort',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _sortAscending = true;
                _pageIndex = 0;
              });
            },
            child: Text(
              'Oldest',
              style: TextStyle(
                color:
                    _sortAscending ? AppColors.brandBlue : AppColors.textMuted,
                fontSize: 11,
                fontWeight:
                    _sortAscending ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _sortAscending = false;
                _pageIndex = 0;
              });
            },
            child: Text(
              'Newest',
              style: TextStyle(
                color:
                    !_sortAscending ? AppColors.brandBlue : AppColors.textMuted,
                fontSize: 11,
                fontWeight:
                    !_sortAscending ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
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
      case 'rejected':
        return AppColors.alertHigh;
      case 'escalated':
        return AppColors.warningOrange;
      default:
        return AppColors.warningOrange;
    }
  }

  String get _statusLabel {
    switch (widget.incident.status) {
      case 'confirmed':
        return 'Confirmed';
      case 'rejected':
        return 'Rejected';
      case 'escalated':
        return 'Escalated';
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
