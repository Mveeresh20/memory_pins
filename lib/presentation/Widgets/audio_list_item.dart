import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/presentation/Pages/pin_detail_screen.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'dart:async';

class AudioListItem extends StatefulWidget {
  final AudioItem audio;
  final VoidCallback? onPlayIncrement; // Callback to increment play count

  const AudioListItem({
    Key? key,
    required this.audio,
    this.onPlayIncrement,
  }) : super(key: key);

  @override
  State<AudioListItem> createState() => _AudioListItemState();
}

class _AudioListItemState extends State<AudioListItem> {
  audioplayers.AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _hasIncrementedPlay =
      false; // Track if we've already incremented play count
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
  }

  void _initializeAudioPlayer() {
    _audioPlayer = audioplayers.AudioPlayer();

    // Listen to position changes
    _positionSubscription = _audioPlayer!.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer!.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
          _isInitialized = true;
        });
      }
    });

    // Listen to player state changes
    _playerStateSubscription =
        _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == audioplayers.PlayerState.playing;
        });

        // When audio completes, reset position
        if (state == audioplayers.PlayerState.stopped) {
          setState(() {
            _position = Duration.zero;
            _isPlaying = false;
          });
        }
      }
    });
  }

  Future<void> _playPause() async {
    try {
      print(
          'Play/Pause called - isPlaying: $_isPlaying, position: ${_position.inSeconds}s, duration: ${_duration.inSeconds}s');

      if (_isPlaying) {
        print('Pausing audio');
        await _audioPlayer!.pause();
      } else {
        // Increment play count when starting to play for the first time
        if (!_hasIncrementedPlay && widget.onPlayIncrement != null) {
          widget.onPlayIncrement!();
          _hasIncrementedPlay = true;
        }

        // If position is at or near the end, restart from beginning
        if (_duration > Duration.zero &&
            _position >= _duration - Duration(milliseconds: 500)) {
          print('Audio near end, restarting from beginning');
          setState(() {
            _isLoading = true;
          });

          // Stop and restart
          await _audioPlayer!.stop();
          await Future.delayed(Duration(milliseconds: 100));
          await _audioPlayer!
              .play(audioplayers.UrlSource(widget.audio.audioUrl));

          setState(() {
            _isLoading = false;
          });
        } else if (!_isInitialized) {
          print('First time playing');
          setState(() {
            _isLoading = true;
          });

          await _audioPlayer!
              .play(audioplayers.UrlSource(widget.audio.audioUrl));

          setState(() {
            _isLoading = false;
          });
        } else {
          print('Resuming audio');
          await _audioPlayer!.resume();
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  Future<void> _seekTo(double progress) async {
    if (_duration.inMilliseconds > 0) {
      final newPosition = Duration(
        milliseconds: (progress * _duration.inMilliseconds).round(),
      );
      await _audioPlayer?.seek(newPosition);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Play/Pause Button
        GestureDetector(
          onTap: _playPause,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgGroundYellow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderColor1, width: 1),
              boxShadow: [AppColors.backShadow],
            ),
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),

        SizedBox(width: 12),

        // Waveform and Progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Touchable Waveform
              GestureDetector(
                onTapDown: (details) {
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final localPosition =
                      renderBox.globalToLocal(details.globalPosition);
                  final progress = localPosition.dx /
                      (MediaQuery.of(context).size.width * 0.6);
                  _seekTo(progress.clamp(0.0, 1.0));

                  // Add haptic feedback for better UX
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: WaveformPainter(
                          isPlaying: _isPlaying,
                          position: _position,
                          duration: _duration,
                        ),
                        size: Size(MediaQuery.of(context).size.width * 0.6, 40),
                      ),
                      // Add a subtle overlay to indicate it's touchable
                      // if (_duration != Duration.zero)
                      //   Positioned(
                      //     right: 8,
                      //     top: 8,
                      //     child: Container(
                      //       padding: EdgeInsets.all(4),
                      //       decoration: BoxDecoration(
                      //         color: Colors.black.withOpacity(0.3),
                      //         borderRadius: BorderRadius.circular(4),
                      //       ),
                      //       child: Icon(
                      //         Icons.touch_app,
                      //         color: Colors.white,
                      //         size: 12,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 10),

        // Duration Text
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDuration(_position),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_duration != Duration.zero) ...[
              SizedBox(height: 2),
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class WaveformPainter extends CustomPainter {
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  WaveformPainter({
    required this.isPlaying,
    required this.position,
    required this.duration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Progress value between 0.0 and 1.0
    double progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    // Define the repeating height pattern
    final heightPattern = [
      0.2,
      0.4,
      0.6,
      0.4,
    ];

    int patternLength = heightPattern.length;
    int barSpacing = 4; // space between waveform bars

    for (int i = 0; i < size.width; i += barSpacing) {
      int patternIndex = (i ~/ barSpacing) % patternLength;
      double heightFactor = heightPattern[patternIndex];
      double barHeight = size.height * heightFactor;

      double normalizedPosition = i / size.width;

      // Change color based on play progress
      paint.color = normalizedPosition <= progress
          ? Color(0xFF0CA3FC) // Played
          : Color(0xFF64748B); // Unplayed

      // Animate slight height change if playing
      if (isPlaying && normalizedPosition <= progress) {
        barHeight *=
            0.9 + 0.1 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
      }

      // Draw waveform bar
      canvas.drawLine(
        Offset(i.toDouble(), size.height / 2 - barHeight / 2),
        Offset(i.toDouble(), size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.isPlaying != isPlaying ||
        oldDelegate.position != position ||
        oldDelegate.duration != duration;
  }
}
