import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class IncidentVideoPlayer extends StatefulWidget {
  final String? videoPath;
  final double height;
  final bool allowFullScreen;

  const IncidentVideoPlayer({
    super.key,
    required this.videoPath,
    this.height = 300,
    this.allowFullScreen = true,
  });

  @override
  State<IncidentVideoPlayer> createState() => _IncidentVideoPlayerState();
}

class _IncidentVideoPlayerState extends State<IncidentVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  // Changing this key after fullscreen forces Flutter to fully recreate the
  // VideoPlayer widget and re-register its platform texture.
  Key _playerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant IncidentVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _initVideo();
    }
  }

  void _initVideo() {
    final path = widget.videoPath;
    if (path == null || path.isEmpty) {
      _controller?.dispose();
      _controller = null;
      _error = null;
      setState(() {});
      return;
    }
    _controller?.dispose();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(ApiConfig.getVideoUrl(path)),
    );
    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _error = null;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _error = "Failed to load video: $error";
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child:
            (_controller != null && _controller!.value.isInitialized)
                ? Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!, key: _playerKey),
                    ),
                    _buildVideoControls(),
                  ],
                )
                : _error != null
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
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _initVideo,
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
                    : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _controller!.value.isPlaying
                  ? _controller!.pause()
                  : _controller!.play();
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child:
                  !_controller!.value.isPlaying
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
                    _controller!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller!.value.isPlaying
                          ? _controller!.pause()
                          : _controller!.play();
                    });
                  },
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.brandBlue,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ),
                if (widget.allowFullScreen)
                  IconButton(
                    icon: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _openFullScreen,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openFullScreen() {
    if (_controller == null) return;

    // Capture playback state before entering fullscreen
    final wasPlaying = _controller!.value.isPlaying;
    _controller!.pause();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (ctx) => _FullScreenVideoView(
              controller: _controller!,
              wasPlaying: wasPlaying,
            ),
      ),
    ).then((_) {
      // Give the platform a frame to fully tear down the fullscreen texture,
      // then assign a new key so Flutter recreates the VideoPlayer widget
      // and re-registers a fresh texture with the same controller.
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _playerKey = UniqueKey();
            });
          }
        });
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Dedicated fullscreen route — owns its own controls so the shared controller
// is not split across two VideoPlayer widget trees simultaneously.
// ---------------------------------------------------------------------------
class _FullScreenVideoView extends StatefulWidget {
  final VideoPlayerController controller;
  final bool wasPlaying;

  const _FullScreenVideoView({
    required this.controller,
    required this.wasPlaying,
  });

  @override
  State<_FullScreenVideoView> createState() => _FullScreenVideoViewState();
}

class _FullScreenVideoViewState extends State<_FullScreenVideoView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    // Defer play() to after the first frame so no setState is triggered
    // during the ongoing build phase (avoids VideoProgressIndicator crash).
    if (widget.wasPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.play();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video (bottom layer)
          Center(
            child: AspectRatio(
              aspectRatio: ctrl.value.aspectRatio,
              child: VideoPlayer(ctrl),
            ),
          ),

          // 2. Tap-to-play/pause — MUST be before controls so buttons sit on top
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
            },
            child: const SizedBox.expand(),
          ),

          // 3. Bottom controls bar (on top — receives taps before GestureDetector)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () =>
                        ctrl.value.isPlaying ? ctrl.pause() : ctrl.play(),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      ctrl,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppColors.brandBlue,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.fullscreen_exit,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),

          // 4. Close button top-right (additional escape hatch)
          Positioned(
            top: 40,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
