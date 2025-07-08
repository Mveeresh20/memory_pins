import 'package:flutter/material.dart';
import 'dart:async';
import 'package:memory_pins_app/models/audio_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'dart:math' as math;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:flutter/services.dart';

// WaveformPainter class for the audio waveform visualization
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
    final heightPattern = [0.2, 0.4, 0.6, 0.4, 0.8, 0.3, 0.5, 0.7];

    int patternLength = heightPattern.length;
    int barSpacing = 3; // space between waveform bars

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

// New widget for displaying recorded audio files in create pin screen
class RecordedAudioListItem extends StatefulWidget {
  final File audioFile;
  final VoidCallback onDelete;

  const RecordedAudioListItem({
    Key? key,
    required this.audioFile,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<RecordedAudioListItem> createState() => _RecordedAudioListItemState();
}

class _RecordedAudioListItemState extends State<RecordedAudioListItem> {
  audioplayers.AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isInitialized = false;
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

      // Check if file exists before playing
      if (!await widget.audioFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio file not found!')),
        );
        return;
      }

      if (_isPlaying) {
        print('Pausing audio');
        await _audioPlayer!.pause();
      } else {
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
              .play(audioplayers.DeviceFileSource(widget.audioFile.path));

          setState(() {
            _isLoading = false;
          });
        } else if (!_isInitialized) {
          print('First time playing');
          setState(() {
            _isLoading = true;
          });

          await _audioPlayer!
              .play(audioplayers.DeviceFileSource(widget.audioFile.path));

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
                  child: CustomPaint(
                    painter: WaveformPainter(
                      isPlaying: _isPlaying,
                      position: _position,
                      duration: _duration,
                    ),
                    size: Size(MediaQuery.of(context).size.width * 0.6, 40),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 10),

        // Duration Text and Delete Button
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                // Delete Button
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
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

class AudioRecorderSection extends StatefulWidget {
  final Function(String audioFilePath)? onAudioRecorded;
  final Function()? onAudioDeleted;

  const AudioRecorderSection({
    super.key,
    this.onAudioRecorded,
    this.onAudioDeleted,
  });

  @override
  State<AudioRecorderSection> createState() => _AudioRecorderSectionState();
}

class _AudioRecorderSectionState extends State<AudioRecorderSection> {
  AudioState _audioState = AudioState.initial;
  final AudioRecorder _recorder = AudioRecorder();
  final audioplayers.AudioPlayer _audioPlayer = audioplayers.AudioPlayer();
  String? _audioFilePath;
  Timer? _recordingTimer;
  int _recordingDuration = 0; // in seconds

  // Audio waveforms controller
  late RecorderController _recorderController;
  late PlayerController _playerController;

  bool _isRecorderInitialized = false;
  bool _isRecordingPaused = false;
  bool _isPlayingAudio = false;
  Duration _currentPlaybackPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAudioWaveforms();
    _initializeAudio();
    _setupAudioPlayerListeners();
  }

  void _initializeAudioWaveforms() {
    // Initialize recorder controller
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 128000
      ..updateFrequency = const Duration(milliseconds: 100);
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPlaybackPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _currentPlaybackPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorderController.dispose();
    if (_audioState == AudioState.recorded && _playerController != null) {
      _playerController.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  // Initializes the audio recorder
  Future<void> _initializeAudio() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Microphone permission denied. Cannot record audio.')),
        );
      }
      print('Microphone permission not granted. Cannot initialize recorder.');
      return;
    }

    // Check if recording is available
    try {
      final isRecordingAvailable = await _recorder.hasPermission();
      if (isRecordingAvailable) {
        setState(() {
          _isRecorderInitialized = true;
        });
        print('Audio recorder initialized successfully');
      } else {
        print('Recording permission not granted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording permission not granted')),
          );
        }
      }
    } catch (e) {
      print('Error initializing recorder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error initializing recorder: ${e.toString()}')),
        );
      }
    }
  }

  // Starts recording audio
  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      print('Error: Recorder is not initialized. Cannot start recording.');
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      _audioFilePath =
          '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      print('Recording to: $_audioFilePath');

      // Start recording with audio_waveforms
      await _recorderController.record(path: _audioFilePath);

      setState(() {
        _audioState = AudioState.recording;
        _recordingDuration = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration++;
          });
        }
      });
      print('Recording started successfully');
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed: ${e.toString()}')),
        );
      }
    }
  }

  // Stops recording audio
  Future<void> _stopRecording() async {
    try {
      final path = await _recorderController.stop();
      _recordingTimer?.cancel();

      if (path != null) {
        setState(() {
          _audioState = AudioState.recorded;
          _audioFilePath = path;
        });

        // Initialize player controller for the recorded file
        _playerController = PlayerController()
          ..preparePlayer(
            path: path,
            noOfSamples: MediaQuery.of(context).size.width.toInt() ~/ 2,
          );

        // Set up listeners for player position updates
        _playerController.onCurrentDurationChanged.listen((durationInMillis) {
          if (mounted) {
            setState(() {
              _currentPlaybackPosition =
                  Duration(milliseconds: durationInMillis);
            });
          }
        });

        // Notify parent component about the recorded audio
        if (widget.onAudioRecorded != null) {
          print('Calling onAudioRecorded callback with path: $path');
          widget.onAudioRecorded!(path);
        } else {
          print('Warning: onAudioRecorded callback is null');
        }

        print('Recording stopped. File: $_audioFilePath');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      // Reset to initial state on error
      setState(() {
        _audioState = AudioState.initial;
        _recordingDuration = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: ${e.toString()}')),
        );
      }
    }
  }

  // Plays the recorded audio
  Future<void> _playAudio() async {
    try {
      if (_audioFilePath != null && await File(_audioFilePath!).exists()) {
        if (_isPlayingAudio) {
          await _playerController.pausePlayer();
          setState(() {
            _isPlayingAudio = false;
          });
        } else {
          await _playerController.startPlayer();
          setState(() {
            _isPlayingAudio = true;
          });
        }
        print('Playing audio: $_audioFilePath');
      } else {
        print('No audio file to play or file does not exist.');
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  // Pause recording
  Future<void> _pauseRecording() async {
    try {
      await _recorderController.pause();
      _recordingTimer?.cancel();
      setState(() {
        _isRecordingPaused = true;
      });
      print('Recording paused');
    } catch (e) {
      print('Error pausing recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error pausing recording: ${e.toString()}')),
        );
      }
    }
  }

  // Resume recording
  Future<void> _resumeRecording() async {
    try {
      await _recorderController.record();
      setState(() {
        _isRecordingPaused = false;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration++;
          });
        }
      });

      print('Recording resumed');
    } catch (e) {
      print('Error resuming recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resuming recording: ${e.toString()}')),
        );
      }
    }
  }

  // Deletes the recorded audio
  Future<void> _deleteAudio() async {
    try {
      if (_audioFilePath != null) {
        final file = File(_audioFilePath!);
        if (await file.exists()) {
          await file.delete();
          print('Audio file deleted: $_audioFilePath');
        }
      }

      // Reset controllers if needed
      if (_audioState == AudioState.recorded) {
        _playerController.dispose();
      } else if (_audioState == AudioState.recording) {
        await _recorderController.stop();
        _recorderController = RecorderController()
          ..androidEncoder = AndroidEncoder.aac
          ..androidOutputFormat = AndroidOutputFormat.mpeg4
          ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
          ..sampleRate = 44100
          ..bitRate = 128000
          ..updateFrequency = const Duration(milliseconds: 100);
      }

      setState(() {
        _audioState = AudioState.initial; // Go back to initial state
        _audioFilePath = null;
        _recordingDuration = 0;
        _isPlayingAudio = false;
        _isRecordingPaused = false;
      });

      _recordingTimer?.cancel();

      // Notify parent component about the deleted audio
      if (widget.onAudioDeleted != null) {
        widget.onAudioDeleted!();
      }
    } catch (e) {
      print('Error deleting audio: $e');
    }
  }

  // Formats duration for display (e.g., 00:00:10)
  String _formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String secondsStr = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAudioUI(),
      ],
    );
  }

  Widget _buildAudioUI() {
    switch (_audioState) {
      case AudioState.initial:
        return _buildAddComponentButton();
      case AudioState.addMicrophone:
        return _buildMicrophoneButton();
      case AudioState.recording:
        return _buildRecordingInProgressUI();
      case AudioState.recorded:
        // After recording, always show the add component button instead of recorded audio UI
        return _buildAddComponentButton();
    }
  }

  // Figma: initial state (plus icon in dotted box)
  Widget _buildAddComponentButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _audioState = AudioState.addMicrophone;
        });
      },
      child: Container(
        width: double.infinity,
        height: 80, // Adjusted height
        decoration: BoxDecoration(
          color: const Color(0xFF38383D), // Dark grey background
          borderRadius: BorderRadius.circular(15), // Rounded corners
          border: Border.all(
            color: Colors.white,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  // Figma: microphone button after tapping "Add component"
  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onTap: _isRecorderInitialized
          ? _startRecording
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Audio recorder is initializing. Please try again in a moment.')),
              );
              // Try to initialize again if it failed
              _initializeAudio();
            },
      child: Container(
        width: double.infinity,
        height: 80, // Adjusted height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8A2BE2),
              const Color(0xFFC71585)
            ], // Purple gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: _isRecorderInitialized
              ? const Icon(Icons.mic, color: Colors.white, size: 30)
              : const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
        ),
      ),
    );
  }

  // Figma: recording in progress UI
  Widget _buildRecordingInProgressUI() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF38383D),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              // Waveform visualization
              Expanded(
                child: AudioWaveforms(
                  enableGesture: false,
                  size: Size(MediaQuery.of(context).size.width - 40, 80),
                  recorderController: _recorderController,
                  waveStyle: const WaveStyle(
                    waveColor: Colors.white,
                    extendWaveform: true,
                    showMiddleLine: false,
                    showDurationLabel: false,
                    spacing: 5.0,
                    waveThickness: 3,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 10),
              // Timer display
              Text(
                _formatDuration(_recordingDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stop Button
            _buildIconButton(
              icon: Icons.stop,
              onTap: _stopRecording,
              backgroundColor: const Color(0xFF55555B), // Grey background
            ),
            const SizedBox(width: 20),
            // Pause/Resume Button (in the middle)
            _buildIconButton(
              icon: _isRecordingPaused ? Icons.play_arrow : Icons.pause,
              onTap: _isRecordingPaused ? _resumeRecording : _pauseRecording,
              backgroundColor: const Color(0xFF8A2BE2), // Purple background
              size: 70, // Larger size for the middle button
            ),
            const SizedBox(width: 20),
            // Delete Button
            _buildIconButton(
              icon: Icons.delete,
              onTap: _deleteAudio,
              backgroundColor: const Color(0xFF55555B), // Grey background
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size / 2), // Circular buttons
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
