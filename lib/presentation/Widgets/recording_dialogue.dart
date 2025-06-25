import 'package:flutter/material.dart';
import 'package:memory_pins_app/services/journal_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';


class RecordingDialog extends StatefulWidget {
  final VoidCallback? onRecordingSaved;

  const RecordingDialog({
    super.key,
    this.onRecordingSaved,
  });

  @override
  State<RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<RecordingDialog>
    with SingleTickerProviderStateMixin {
  final _audioRecorder = AudioRecorder();
  final _journalService = JournalService();
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isSaving = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordingPath;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final fileName = 'AUDIO_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final path = '${dir.path}/$fileName';
        _recordingPath = path;

        debugPrint('Starting recording at path: $path');
        debugPrint('Temporary directory: ${dir.path}');

        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _isPaused = false;
        });

        _startTimer();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    if (_isRecording && !_isPaused) {
      await _audioRecorder.pause();
      setState(() => _isPaused = true);
      _timer?.cancel();
    }
  }

  Future<void> _resumeRecording() async {
    if (_isRecording && _isPaused) {
      await _audioRecorder.resume();
      setState(() => _isPaused = false);
      _startTimer();
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      setState(() {
        _isSaving = true;
        _isRecording = false;
        _isPaused = false;
      });

      _timer?.cancel();
      final path = await _audioRecorder.stop();
      debugPrint('Recording stopped. Final path: $path');
      debugPrint('Recording duration: ${_recordingDuration.inSeconds} seconds');

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingDuration = Duration.zero;
      });

      if (path != null && mounted) {
        debugPrint('Uploading audio file from path: $path');
        // Upload the recording
        await _journalService.saveAudioNoteWithUpload(
          path,
          context,
          title: 'Audio Note ${DateTime.now().toString()}',
          onUploadSuccess: (String uploadedPath) {
            debugPrint('Audio uploaded successfully. S3 path: $uploadedPath');
            if (widget.onRecordingSaved != null) {
              widget.onRecordingSaved!();
            }
            Navigator.pop(context, uploadedPath);
          },
          onUploadFailure: (String error) {
            debugPrint('Error uploading audio: $error');
            setState(() {
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading audio: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth * 0.8,
        height: screenHeight * 0.5,
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          // image: const DecorationImage(
          //   image: AssetImage(ImagePath.recordingBackgroundImage),
          //   fit: BoxFit.cover,
          // ),
        ),
        child: Stack(
          children: [
            // Close Button
            Positioned(
              right: 20,
              top: 20,
              child: GestureDetector(
                onTap: () async {
                  setState(() {
                    _isRecording = false;
                    _isPaused = false;
                  });
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF1E2730),
                  ),
                ),
              ),
            ),

            // Recording Animation
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular Gradients with Animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer circles with staggered animations
                      ...List.generate(4, (index) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final delay = index * 0.2;
                            final scale = 1.0 +
                                (_pulseAnimation.value - 1.0) * (1.0 - delay);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 141 - (index * 10),
                                height: 141 - (index * 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFA976E1)
                                          .withOpacity(1.0 - (index * 0.2)),
                                      const Color(0x005D43A5),
                                    ],
                                    stops: const [0.84375, 1.0],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),

                      // Microphone Icon with Pulse Animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 94,
                              height: 94,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFF241B52),
                                    Color(0xFF253262)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Recording Text and Timer
                  Column(
                    children: [
                      Text(
                        'Recording......',
                        style: const TextStyle(
                          color: Color(0xFF7492A7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          color: Color(0xFF07C75A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Control Buttons
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (_isRecording) {
                              if (_isPaused) {
                                await _resumeRecording();
                              } else {
                                await _pauseRecording();
                              }
                            } else {
                              await _startRecording();
                            }
                          },
                    child: Text(
                      _isPaused ? 'Pause' : 'Record',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: _isSaving
                        ? null
                        : () {
                            _stopRecording();
                          },
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
