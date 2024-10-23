import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_desktop/config.dart';
import 'package:window_manager/window_manager.dart';

class VideoPlayerMacosScreen extends StatefulWidget {
  const VideoPlayerMacosScreen({super.key});

  @override
  State<VideoPlayerMacosScreen> createState() => _VideoPlayerMacosScreenState();
}

class _VideoPlayerMacosScreenState extends State<VideoPlayerMacosScreen> {
  late VideoPlayerController _controller;
  var _showControls = false;
  Timer? _overlayTimer;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _toggleFullScreen();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('VideoPlayer MACOS'),
        ),
        body: _controller.value.isInitialized
            ? GestureDetector(
                onTap: () {
                  // toggle play pause
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      VideoPlayer(_controller),
                      Positioned.fill(child: _overlayVideo()),
                    ],
                  ),
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  Widget _overlayVideo() {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _showControls = true);
      },
      onHover: _onHover,
      onExit: (_) {
        setState(() => _showControls = false);
        _cancelOverlayTimer();
      },
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black38,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildProgressBar(),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return VideoProgressIndicator(
      _controller,
      allowScrubbing: true,
      padding: const EdgeInsets.all(8.0),
      colors: VideoProgressColors(
        playedColor: Colors.red,
        backgroundColor: Colors.grey.shade500,
        bufferedColor: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        children: [
          // play/pause
          InkWell(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // duration
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              return Row(
                children: [
                  Text(
                    Config.formatDuration(value.position),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Text(
                    " / ",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    Config.formatDuration(value.duration),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),

          // spacer
          const Spacer(),
          // configuration fullscreen & config
          Row(
            children: [
              const Icon(
                Icons.settings,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  _toggleFullScreen();
                },
                child: const Icon(
                  Icons.fullscreen_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleFullScreen() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    } else {
      await windowManager.setFullScreen(true);
    }
  }

  void _onHover(PointerHoverEvent event) {
    // Mouse is moving; cancel any existing timer
    _cancelOverlayTimer();
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }

    // Start a timer to hide the overlay after 3 seconds of inactivity
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _cancelOverlayTimer() {
    _overlayTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(Config.urlVideo))
      ..initialize().then((_) {
        setState(() {});
      });

    // Request focus to receive keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _overlayTimer?.cancel();
  }
}
