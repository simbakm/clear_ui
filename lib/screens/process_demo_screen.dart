import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/api_config.dart';
import '../models/incident_processing_event.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ProcessDemoScreen extends StatefulWidget {
  final bool isConnected;
  final Stream<IncidentProcessingEvent> eventStream;
  final IncidentProcessingEvent? initialEvent;

  const ProcessDemoScreen({
    super.key,
    required this.isConnected,
    required this.eventStream,
    this.initialEvent,
  });

  @override
  State<ProcessDemoScreen> createState() => _ProcessDemoScreenState();
}

class _ProcessDemoScreenState extends State<ProcessDemoScreen> with AutomaticKeepAliveClientMixin {
  final List<IncidentProcessingEvent> _events = [];
  bool _isConnected = false;

  // State variables for visualization
  String? _extractedFaceUrl;
  List<dynamic> _databasePersons = [];
  Map<String, dynamic>? _matchResult;
  String _currentStatus = 'Waiting for incidents...';
  int? _currentIncidentId;
  String? _incidentVideoPath;
  VideoPlayerController? _videoController;
  String? _videoError;
  bool _isFetchingIncident = false;

  Timer? _dbAnimationTimer;
  int _currentDbIndex = 0;
  DateTime? _animationStartTime;
  final List<IncidentProcessingEvent> _pendingFinishedEvents = [];
  StreamSubscription<IncidentProcessingEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _isConnected = widget.isConnected;
    _currentStatus =
        widget.isConnected ? 'Listening for new incidents...' : 'Offline';
    _eventSub = widget.eventStream.listen(_handleNewEvent);

    if (widget.initialEvent != null) {
      _handleNewEvent(widget.initialEvent!);
    }
  }

  @override
  void didUpdateWidget(covariant ProcessDemoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      _isConnected = widget.isConnected;
      _currentStatus =
          widget.isConnected ? 'Listening for new incidents...' : 'Offline';
    }
    if (widget.eventStream != oldWidget.eventStream) {
      _eventSub?.cancel();
      _eventSub = widget.eventStream.listen(_handleNewEvent);
    }
    if (widget.initialEvent != null &&
        widget.initialEvent != oldWidget.initialEvent) {
      _handleNewEvent(widget.initialEvent!);
    }
  }

  void _startDbAnimation() {
    _dbAnimationTimer?.cancel();
    if (_databasePersons.isEmpty) return;

    _dbAnimationTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentDbIndex = (_currentDbIndex + 1) % _databasePersons.length;
      });
    });
  }

  void _stopDbAnimation({bool isMatch = false, String? matchedEmail}) {
    _dbAnimationTimer?.cancel();
    if (isMatch && matchedEmail != null) {
      final index = _databasePersons.indexWhere(
        (p) => p['email'] == matchedEmail,
      );
      if (index != -1) {
        setState(() {
          _currentDbIndex = index;
        });
      }
    }
  }

  void _handleNewEvent(IncidentProcessingEvent event) {
    if (!mounted) return;
    if (event.incidentId == 0 || event.status == 'KEEPALIVE') {
      return;
    }

    // Avoid re-processing the same event repeatedly (common when replaying
    // the latest event on tab activation).
    if (_events.any((e) =>
        e.incidentId == event.incidentId &&
        e.step == event.step &&
        e.status == event.status &&
        e.message == event.message)) {
      return;
    }

    if (_currentIncidentId != null && _currentIncidentId != event.incidentId) {
      _resetState();
    }

    if (event.status == 'FINISHED' && _animationStartTime != null) {
      final elapsed = DateTime.now().difference(_animationStartTime!);
      if (elapsed.inSeconds < 5) {
        // Buffer the event to be processed after the 5s artificial delay
        _pendingFinishedEvents.add(event);
        return;
      }
    }

    _processEventState(event);
  }

  void _resetState() {
    setState(() {
      _currentIncidentId = null;
      _events.clear();
      _extractedFaceUrl = null;
      _databasePersons.clear();
      _matchResult = null;
      _dbAnimationTimer?.cancel();
      _currentDbIndex = 0;
      _animationStartTime = null;
      _pendingFinishedEvents.clear();
      _incidentVideoPath = null;
      _videoController?.dispose();
      _videoController = null;
      _videoError = null;
    });
  }

  void _processEventState(IncidentProcessingEvent event) {
    setState(() {
      _currentIncidentId = event.incidentId;
      _events.add(event);
      _currentStatus = event.message;

      if (event.data != null) {
        if (event.data is Map) {
          final dataMap = event.data as Map;
          final videoPath =
              dataMap['videoPath'] ??
              dataMap['video_path'] ??
              dataMap['clipPath'] ??
              dataMap['clip_path'];
          if (videoPath is String && videoPath.isNotEmpty) {
            _incidentVideoPath = videoPath;
            _initVideo(videoPath);
          }
        }
        if (event.step == 3 &&
            event.data is Map &&
            (event.data as Map).containsKey('extractedFaceUrl')) {
          _extractedFaceUrl = (event.data as Map)['extractedFaceUrl'];
        } else if (event.step == 4 && event.data is List) {
          _databasePersons = List.from(event.data as List);
          _startDbAnimation();
          _animationStartTime = DateTime.now();

          // Schedule playback of any buffered finished events
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _pendingFinishedEvents.isNotEmpty) {
              final pending = List<IncidentProcessingEvent>.from(
                _pendingFinishedEvents,
              );
              _pendingFinishedEvents.clear();
              for (var e in pending) {
                _processEventState(e);
              }
            }
          });
        } else if (event.step == 5) {
          _matchResult = event.data as Map<String, dynamic>?;
          if (_matchResult != null) {
            bool isMatch =
                _matchResult!['match_found'].toString().toLowerCase() == 'true';
            _stopDbAnimation(
              isMatch: isMatch,
              matchedEmail: _matchResult!['email'],
            );
          }
        }
      }
    });

    if (_currentIncidentId != null) {
      _fetchIncidentVideo(_currentIncidentId!);
    }
  }

  Future<void> _fetchIncidentVideo(int incidentId) async {
    if (_isFetchingIncident) return;
    if (_incidentVideoPath != null && _incidentVideoPath!.isNotEmpty) return;
    _isFetchingIncident = true;
    try {
      final incident = await ApiService.getIncident(incidentId);
      if (incident != null &&
          incident.videoPath.isNotEmpty &&
          _incidentVideoPath != incident.videoPath) {
        setState(() {
          _incidentVideoPath = incident.videoPath;
        });
        _initVideo(incident.videoPath);
      }
    } finally {
      _isFetchingIncident = false;
    }
  }

  void _initVideo(String filename) {
    if (filename.isEmpty) return;
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(ApiConfig.getVideoUrl(filename)),
    );

    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _videoError = null;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _videoError = "Failed to load video: $error";
        });
      }
    });
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Normalize Windows backslashes to standard URL forward slashes
    final normalizedPath = path.replaceAll('\\', '/');

    // Route target faces straight to the python port
    if (normalizedPath.startsWith('/faces/')) {
      return '${ApiConfig.pythonServiceUrl}$normalizedPath';
    }

    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    if (normalizedPath.startsWith('/')) {
      return '$base$normalizedPath';
    } else {
      return '$base/$normalizedPath';
    }
  }

  @override
  void dispose() {
    _dbAnimationTimer?.cancel();
    _eventSub?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bool isFinished = _events.isNotEmpty && _events.last.status == 'FINISHED';

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isFinished),
            const SizedBox(height: 24),
            SizedBox(
              height: 480, // Giving extra space to side-by-side panels
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 1, child: _buildTargetFacePanel()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildDatabaseComparisonPanel()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 360,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 1, child: _buildProcessLogsPanel()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildIncidentVideoPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isFinished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'facial recognition live tracking', // Matched lowercase per mockup, though optional
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (_currentIncidentId != null)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    'incident id : $_currentIncidentId',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isFinished
                            ? AppColors.activeGreen.withOpacity(0.1)
                            : AppColors.brandBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          isFinished
                              ? AppColors.activeGreen
                              : AppColors.brandBlue,
                    ),
                  ),
                  child:
                      isFinished
                          ? const Text(
                            'finished',
                            style: TextStyle(
                              color: AppColors.activeGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : Row(
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.brandBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'processing indicator',
                                style: TextStyle(
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _isConnected
                        ? AppColors.activeGreen.withOpacity(0.1)
                        : AppColors.alertHigh.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isConnected ? 'Connected. Waiting for videos...' : 'Offline',
                style: TextStyle(
                  color:
                      _isConnected
                          ? AppColors.activeGreen
                          : AppColors.alertHigh,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTargetFacePanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Text(
              'target face',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child:
                  _extractedFaceUrl != null
                      ? Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brandBlue,
                            width: 4,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            _getImageUrl(_extractedFaceUrl),
                            fit: BoxFit.cover,
                            errorBuilder:
                                (c, e, s) => const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ),
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cardBorder,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_search,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentIncidentId != null
                                ? 'Extracting face...'
                                : 'Waiting...',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseComparisonPanel() {
    dynamic currentPerson;
    if (_databasePersons.isNotEmpty &&
        _currentDbIndex < _databasePersons.length) {
      currentPerson = _databasePersons[_currentDbIndex];
    }

    bool isMatchFound =
        _matchResult != null &&
        _matchResult!['match_found'].toString().toLowerCase() == 'true';
    bool isNoMatch =
        _matchResult != null &&
        _matchResult!['match_found'].toString().toLowerCase() != 'true';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isMatchFound
                  ? AppColors.activeGreen
                  : isNoMatch
                  ? AppColors.alertHigh
                  : AppColors.cardBorder,
          width: _matchResult != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
              border: Border(
                bottom: BorderSide(
                  color:
                      isMatchFound
                          ? AppColors.activeGreen
                          : isNoMatch
                          ? AppColors.alertHigh
                          : AppColors.cardBorder,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'database comparizon',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _databasePersons.isEmpty
                    ? const Center(
                      child: Text(
                        'Awaiting database payload',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          // Picture & Name Column
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          isMatchFound
                                              ? AppColors.activeGreen
                                              : AppColors.cardBorder,
                                      width: isMatchFound ? 4 : 2,
                                    ),
                                    boxShadow:
                                        isMatchFound
                                            ? [
                                              BoxShadow(
                                                color: AppColors.activeGreen
                                                    .withOpacity(0.5),
                                                blurRadius: 15,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                            : [],
                                  ),
                                  child: ClipOval(
                                    child:
                                        (isNoMatch || currentPerson?['picturePath'] == null || currentPerson?['picturePath'].isEmpty)
                                            ? const Icon(
                                              Icons.person,
                                              size: 80,
                                              color: AppColors.textMuted,
                                            )
                                            : Image.network(
                                              _getImageUrl(
                                                currentPerson?['picturePath'],
                                              ),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (c, e, s) => const Icon(
                                                    Icons.person,
                                                    size: 80,
                                                    color: AppColors.textMuted,
                                                  ),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    isNoMatch ? 'unknown' : (currentPerson?['fullName'] ?? '...'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),

                          // Details Column
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Match Status Card
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _matchResult == null
                                            ? AppColors.surface
                                            : isMatchFound
                                            ? AppColors.activeGreen.withOpacity(
                                              0.1,
                                            )
                                            : AppColors.alertHigh.withOpacity(
                                              0.1,
                                            ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          _matchResult == null
                                              ? AppColors.cardBorder
                                              : isMatchFound
                                              ? AppColors.activeGreen
                                              : AppColors.alertHigh,
                                    ),
                                  ),
                                  child: Text(
                                    _matchResult == null
                                        ? '?'
                                        : isMatchFound
                                        ? 'match verified'
                                        : 'no match found',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _matchResult == null
                                              ? AppColors.textSecondary
                                              : isMatchFound
                                              ? AppColors.activeGreen
                                              : AppColors.alertHigh,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Email Field
                                _buildDetailRow(
                                  isMatchFound
                                      ? (currentPerson?['email'] ?? 'N/A')
                                      : (isNoMatch ? 'email:?' : 'email'),
                                ),
                                const SizedBox(height: 12),

                                // Role Field
                                _buildDetailRow(
                                  isMatchFound
                                      ? (currentPerson?['role'] ?? 'N/A')
                                      : (isNoMatch ? 'role:?' : 'role'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildProcessLogsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Text(
              'process logs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length > 0 ? _events.length : 1,
              itemBuilder: (context, index) {
                if (_events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        _currentStatus,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }
                final event = _events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        event.status == 'PROCESSING'
                            ? Icons.sync
                            : event.status == 'FINISHED'
                            ? Icons.check_circle
                            : Icons.error,
                        size: 20,
                        color:
                            event.status == 'PROCESSING'
                                ? AppColors.brandBlue
                                : event.status == 'FINISHED'
                                ? AppColors.activeGreen
                                : AppColors.alertHigh,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.message,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Step ${event.step} - ${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentVideoPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Text(
              'incident video',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    (_videoController != null &&
                            _videoController!.value.isInitialized)
                        ? Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio:
                                  _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                            _buildVideoControls(),
                          ],
                        )
                        : _videoError != null
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.alertHigh,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _videoError!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      onPressed:
                                          () => _initVideo(
                                            _incidentVideoPath ?? '',
                                          ),
                                      icon: const Icon(
                                        Icons.refresh,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Retry',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : Center(
                              child: Text(
                                _incidentVideoPath == null
                                    ? 'Waiting for incident video...'
                                    : 'Loading video...',
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _videoController!.value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play();
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child:
                  !_videoController!.value.isPlaying
                      ? Icon(
                        Icons.play_arrow,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 50,
                      )
                      : const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.brandBlue,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

