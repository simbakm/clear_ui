import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../models/camera.dart' as model;
import '../models/incident.dart' as model;
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'package:intl/intl.dart';
import 'portal_placeholder_screen.dart';

/// Offender portal — no login required.
/// Accessed via a secure URL sent by email notification.
class OffenderPortalScreen extends StatefulWidget {
  final int? incidentId;
  const OffenderPortalScreen({super.key, this.incidentId});

  @override
  State<OffenderPortalScreen> createState() => _OffenderPortalScreenState();
}

class _OffenderPortalScreenState extends State<OffenderPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _paymentTabController;
  bool _disputeSubmitted = false;
  bool _paymentDone = false;
  final _disputeController = TextEditingController();

  model.Incident? _incident;
  model.Camera? _camera;
  bool _isLoading = true;
  String? _error;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _paymentTabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    // Try to get from constructor first, then URL
    String? idParam = widget.incidentId?.toString();
    if (idParam == null) {
      idParam = Uri.base.queryParameters['id'];
    }

    if (idParam == null) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid Incident ID';
      });
      return;
    }

    final id = int.tryParse(idParam);
    if (id == null) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid Incident ID format';
      });
      return;
    }

    final incident = await ApiService.getIncident(id);
    if (incident == null) {
      setState(() {
        _isLoading = false;
        _error = 'Incident not found';
      });
      return;
    }

    final camera = await ApiService.getCamera(incident.cameraId);

    if (mounted) {
      setState(() {
        _incident = incident;
        _camera = camera;
        _isLoading = false;
      });

      _initVideo(incident.videoPath);
    }
  }

  void _initVideo(String filename) {
    _videoController = VideoPlayerController.networkUrl(
        Uri.parse(ApiConfig.getVideoUrl(filename)),
      )
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _paymentTabController.dispose();
    _disputeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const PortalPlaceholderScreen(
        title: 'Connecting to CLEAR Services',
        message: 'Please wait while we retrieve your incident details...',
        iconLabel: 'LOADING',
        isLoading: true,
      );
    }

    if (_error != null) {
      return PortalPlaceholderScreen(
        title:
            _error == 'Invalid Incident ID'
                ? 'Access Restricted'
                : 'Connection Error',
        message:
            _error == 'Invalid Incident ID'
                ? 'Please use the secure link provided in your notification email to view this incident.'
                : 'We encountered an issue connecting to the database. Please try again later.',
        iconLabel: _error == 'Invalid Incident ID' ? 'ID MISSING' : 'OFFLINE',
        onRetry: _loadData,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notice banner
                      _buildNoticeBanner(),
                      const SizedBox(height: 24),
                      // Two-column layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: incident details + evidence
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildIncidentCard(),
                                const SizedBox(height: 16),
                                _buildVideoEvidence(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right: payment + dispute
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildPaymentSection(),
                                const SizedBox(height: 16),
                                _buildDisputeSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.alertHigh.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.alertHigh.withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'INCIDENT NOTICE',
              style: TextStyle(
                color: AppColors.alertHigh,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'This page is intended for the offender only.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertHigh.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.alertHigh.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel, color: AppColors.alertHigh, size: 22),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fine Notification',
                  style: TextStyle(
                    color: AppColors.alertHigh,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'In accordance with institute laws, you have been identified '
                  'in connection with a littering incident. Please review '
                  'the evidence, pay the fine, or submit a dispute below.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Fine Amount',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const Text(
                '5 USD or ZiG equiv.',
                style: TextStyle(
                  color: AppColors.alertHigh,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.warningOrange.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'UNPAID',
                  style: TextStyle(
                    color: AppColors.warningOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard() {
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    final details = [
      ['Incident ID', 'INC-${_incident!.id.toString().padLeft(3, '0')}'],
      ['Date', dateFormat.format(_incident!.effectiveDate)],
      ['Time', timeFormat.format(_incident!.effectiveDate)],
      ['Location', _camera?.location ?? 'Unknown'],
      ['Camera', _camera?.cameraName ?? 'Camera ${_incident!.cameraId}'],
      ['Offence', _incident!.incidentType],
      ['Status', _incident!.status],
      ['Fine', '5 USD'],
    ];

    return _card(
      title: 'Incident Details',
      icon: Icons.description_outlined,
      iconColor: AppColors.brandBlue,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            details.map((d) {
              return SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d[0],
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d[1],
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
    );
  }

  Widget _buildVideoEvidence() {
    return _card(
      title: 'Evidence Video',
      icon: Icons.videocam_outlined,
      iconColor: AppColors.statPurple,
      child: Column(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child:
                  (_videoController != null &&
                          _videoController!.value.isInitialized)
                      ? Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                          _buildVideoControls(),
                        ],
                      )
                      : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'This footage is provided as evidence of the incident. '
            'You may use it to inform your dispute if applicable.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls({bool isFullScreen = false}) {
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
                IconButton(
                  icon: Icon(
                    isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed:
                      isFullScreen
                          ? () => Navigator.of(context).pop()
                          : _toggleFullScreen,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                    _buildVideoControls(isFullScreen: true),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return _paymentDone
        ? _card(
          title: 'Payment',
          icon: Icons.check_circle_outline,
          iconColor: AppColors.activeGreen,
          child: Column(
            children: [
              Icon(Icons.check_circle, color: AppColors.activeGreen, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  color: AppColors.activeGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your fine of R 500.00 has been paid.\nA receipt will be emailed to you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        )
        : _card(
          title: 'Pay via PesePay Gateway',
          icon: Icons.payment,
          iconColor: AppColors.activeGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment method tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TabBar(
                  controller: _paymentTabController,
                  indicatorColor: AppColors.brandBlue,
                  indicatorWeight: 2,
                  labelColor: AppColors.brandBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '💳  Card'),
                    Tab(text: '🏦  EFT'),
                    Tab(text: '📱  Mobile Money'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: TabBarView(
                  controller: _paymentTabController,
                  children: [_cardPayForm(), _eftPayForm(), _mobilePayForm()],
                ),
              ),
            ],
          ),
        );
  }

  Widget _cardPayForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _payField('Card Number', '1234  5678  9012  3456', Icons.credit_card),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _payField('Expiry', 'MM / YY', Icons.date_range)),
            const SizedBox(width: 10),
            Expanded(child: _payField('CVV', '•••', Icons.lock_outline)),
          ],
        ),
        const SizedBox(height: 10),
        _payField('Card Holder Name', 'Full Name', Icons.person_outline),
        const SizedBox(height: 16),
        _payBtn(),
      ],
    );
  }

  Widget _eftPayForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transfer to the following account:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        _infoRow('Bank', 'First National Bank'),
        _infoRow('Account Name', 'CLEAR Environmental'),
        _infoRow('Account Number', '62012345678'),
        _infoRow('Branch Code', '250655'),
        _infoRow('Reference', 'INC-001'),
        const SizedBox(height: 16),
        _payBtn(label: 'I Have Made Payment'),
      ],
    );
  }

  Widget _mobilePayForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pay using mobile money:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        // Method buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ['MTN MoMo', 'Vodacom M-Pesa', 'OPay'].map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    m,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 14),
        _payField('Mobile Number', '+27 XX XXX XXXX', Icons.phone_outlined),
        const SizedBox(height: 16),
        _payBtn(label: 'Send Payment Request'),
      ],
    );
  }

  Widget _payField(String label, String hint, IconData icon) {
    return TextField(
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 16),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _payBtn({String label = 'Pay via PesePay'}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => setState(() => _paymentDone = true),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.activeGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeSection() {
    return _disputeSubmitted
        ? _card(
          title: 'Dispute',
          icon: Icons.forum_outlined,
          iconColor: AppColors.statPurple,
          child: Column(
            children: [
              Icon(Icons.check_circle, color: AppColors.statPurple, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Dispute Submitted',
                style: TextStyle(
                  color: AppColors.statPurple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your dispute has been recorded and will be\nreviewed by an Environmental Officer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        )
        : _card(
          title: 'Submit a Dispute',
          icon: Icons.forum_outlined,
          iconColor: AppColors.statPurple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'If you believe this fine was issued in error, you may submit an argument below. '
                'Your dispute will be reviewed by an Environmental Officer.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _disputeController,
                maxLines: 5,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Describe why you believe this incident was incorrectly recorded...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: AppColors.statPurple,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _disputeSubmitted = true),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text(
                    'Submit Dispute',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.cardBorder),
          child,
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 36,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            '© 2026 CLEAR Environmental Monitoring System',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const Spacer(),
          const Text(
            'This page is secured. Unauthorized access is prohibited.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Icon(Icons.lock_outline, color: AppColors.textMuted, size: 13),
        ],
      ),
    );
  }
}
