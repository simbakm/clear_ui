import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/system_footer.dart';
import 'overview_screen.dart';
import 'video_analysis_screen.dart';
import 'alerts_screen.dart';
import 'detection_history_screen.dart';
import 'process_demo_screen.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import '../models/camera.dart';
import '../widgets/register_camera_dialog.dart';
import '../config/api_config.dart';
import '../models/incident_processing_event.dart';
import '../services/sse_client.dart';
import '../services/sound_player.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMonitoring = false;
  bool _isDiscovering = false;
  String? _discoveryError;
  Map<String, List<Camera>> _camerasByLocation = {};
  IncidentModel? _preSelectedIncident;
  int? _lastNotifiedIncidentId;
  IncidentProcessingEvent? _latestProcessEvent;
  bool _sseConnected = false;
  final SseClient _sseClient = SseClient();
  bool _isConnectingSse = false;
  final StreamController<IncidentProcessingEvent>
      _incidentEventController = StreamController.broadcast();

  // Tab indices
  static const int _kProcessDemo = 1;
  static const int _kVideoAnalysis = 2;

  final List<_TabItem> _tabs = const [
    _TabItem(Icons.auto_awesome, 'Overview'),
    _TabItem(Icons.play_circle_outline, 'Facial Recognition'),
    _TabItem(Icons.video_library_outlined, 'Video Analysis'),
    _TabItem(Icons.warning_amber_rounded, 'Alerts'),
    _TabItem(Icons.history, 'Detection History'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _listenForIncidentNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sseClient.close();
    _incidentEventController.close();
    super.dispose();
  }

  void _openIncident(IncidentModel incident) {
    setState(() => _preSelectedIncident = incident);
    _tabController.animateTo(_kVideoAnalysis);
  }

  void _listenForIncidentNotifications() {
    if (_isConnectingSse) return;
    _isConnectingSse = true;
    _sseClient.connect(
      '${ApiConfig.baseUrl}/incidents/stream',
      onOpen: () {
        _isConnectingSse = false;
        if (mounted && !_sseConnected) {
          setState(() => _sseConnected = true);
        }
      },
      onMessage: (data) {
        try {
          if (mounted && !_sseConnected) {
            setState(() => _sseConnected = true);
          }
          final processingEvent = IncidentProcessingEvent.fromString(data);
          if (processingEvent.incidentId == 0 ||
              processingEvent.status == 'KEEPALIVE') {
            return;
          }
          _incidentEventController.add(processingEvent);
          if (mounted) {
            setState(() {
              _latestProcessEvent = processingEvent;
            });
          }
          if (processingEvent.incidentId != 0 &&
              _lastNotifiedIncidentId != processingEvent.incidentId &&
              (processingEvent.step == 1 ||
                  processingEvent.message.toLowerCase().contains('new incident'))) {
            _showIncidentPopup(processingEvent.incidentId);
          }
        } catch (_) {}
      },
      onError: (_) {
        _isConnectingSse = false;
        if (mounted) {
          setState(() => _sseConnected = false);
        }
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _listenForIncidentNotifications();
          }
        });
      },
    );
  }

  void _showIncidentPopup(int incidentId) {
    if (_lastNotifiedIncidentId == incidentId) return;
    _lastNotifiedIncidentId = incidentId;

    SoundPlayer.playAlert();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(const Duration(seconds: 5), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              // Replay latest processing event when switching to Process Demo
              // so the screen has immediate initial data.
              if (_latestProcessEvent != null) {
                _incidentEventController.add(_latestProcessEvent!);
              }
              _tabController.animateTo(_kProcessDemo);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.alertHigh.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.alertHigh,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'New Incident Detected',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Click to view processing',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _discoverCameras() async {
    setState(() {
      _isDiscovering = true;
      _discoveryError = null;
    });
    try {
      final camerasByLocation = await ApiService.discoverCamerasByLocation();
      if (!mounted) return;
      setState(() {
        _camerasByLocation = camerasByLocation;
        _isDiscovering = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDiscovering = false;
        _discoveryError = 'Failed to discover cameras.';
      });
    }
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoring) {
      // Call the API to stop all cameras
      await ApiService.stopAllCameras();

      setState(() {
        _isMonitoring = false;
        _isDiscovering = false;
        _discoveryError = null;
        _camerasByLocation = {};
      });
      return;
    }

    setState(() {
      _isMonitoring = true;
    });

    SoundPlayer.prepare();

    await _discoverCameras();
  }

  Future<void> _openRegisterCameraDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const RegisterCameraDialog(),
    );
    if (result == true && _isMonitoring) {
      SoundPlayer.prepare();

    await _discoverCameras();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          _buildTabBar(),
          const Divider(height: 1, color: AppColors.cardBorder),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                OverviewScreen(
                  isMonitoring: _isMonitoring,
                  isDiscovering: _isDiscovering,
                  discoveryError: _discoveryError,
                  camerasByLocation: _camerasByLocation,
                ),
                ProcessDemoScreen(
                  isConnected: _sseConnected,
                  eventStream: _incidentEventController.stream,
                  initialEvent: _latestProcessEvent,
                ),
                VideoAnalysisScreen(preSelectedIncident: _preSelectedIncident),
                const AlertsScreen(),
                DetectionHistoryScreen(onOpenIncident: _openIncident),
              ],
            ),
          ),
          const SystemFooter(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.background,
      child: Row(
        children: [
          // CLEAR Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.brandBlue, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.brandBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'CLEAR',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Admin Console',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          const Spacer(),

          // Start/Stop Monitoring
          GestureDetector(
            onTap: _toggleMonitoring,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color:
                    _isMonitoring ? AppColors.stopRed : AppColors.activeGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isMonitoring ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Status dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  _isMonitoring ? AppColors.activeGreen : AppColors.textMuted,
              shape: BoxShape.circle,
              boxShadow:
                  _isMonitoring
                      ? [
                        BoxShadow(
                          color: AppColors.activeGreen.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isMonitoring ? 'Active' : 'Idle',
            style: TextStyle(
              color:
                  _isMonitoring ? AppColors.activeGreen : AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 18),

          // Theme Toggle
          IconButton(
            icon: Icon(
              themeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () {
              themeNotifier.value =
                  themeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
              setState(() {});
            },
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8),

          // Settings
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: _openRegisterCameraDialog,
            tooltip: 'Register Camera',
          ),
          const SizedBox(width: 14),

          // Profile Menu
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            color:
                themeNotifier.value == ThemeMode.dark
                    ? AppColors.cardBackground
                    : AppColors.cardBgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color:
                    themeNotifier.value == ThemeMode.dark
                        ? AppColors.cardBorder
                        : AppColors.borderLight,
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'account',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Account Settings',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 18,
                          color: AppColors.alertHigh,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.alertHigh,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brandBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.brandBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Admin',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.brandBlue,
        indicatorWeight: 2,
        labelColor: AppColors.brandBlue,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs:
            _tabs.map((tab) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 15),
                    const SizedBox(width: 6),
                    Text(tab.label),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}







