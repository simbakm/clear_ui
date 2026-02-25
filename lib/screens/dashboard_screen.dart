import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/system_footer.dart';
import 'overview_screen.dart';
import 'video_analysis_screen.dart';
import 'alerts_screen.dart';
import 'detection_history_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMonitoring = false;
  IncidentModel? _preSelectedIncident;

  // Tab indices
  static const int _kVideoAnalysis = 1;

  final List<_TabItem> _tabs = const [
    _TabItem(Icons.auto_awesome, 'Overview'),
    _TabItem(Icons.video_library_outlined, 'Video Analysis'),
    _TabItem(Icons.warning_amber_rounded, 'Alerts'),
    _TabItem(Icons.history, 'Detection History'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openIncident(IncidentModel incident) {
    setState(() => _preSelectedIncident = incident);
    _tabController.animateTo(_kVideoAnalysis);
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
                OverviewScreen(isMonitoring: _isMonitoring),
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
            onTap: () => setState(() => _isMonitoring = !_isMonitoring),
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
          const Icon(
            Icons.settings_outlined,
            color: AppColors.textSecondary,
            size: 20,
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
