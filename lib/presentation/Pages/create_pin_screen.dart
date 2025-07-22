import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:memory_pins_app/presentation/Widgets/audio_recorder_section.dart';

import 'package:memory_pins_app/presentation/Widgets/dialog_helper.dart';
import 'package:memory_pins_app/services/location_picker.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:memory_pins_app/services/app_integration_service.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/utills/Constants/image_picker_util.dart';
import 'package:memory_pins_app/utills/Constants/imageType.dart';
import 'package:memory_pins_app/services/media_service.dart';

// --- Import new packages ---
import 'package:geolocator/geolocator.dart'; // For location
import 'package:permission_handler/permission_handler.dart'; // For permissions
import 'package:record/record.dart'; // For audio recording
import 'package:audioplayers/audioplayers.dart'; // For audio playback
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:path_provider/path_provider.dart'; // For temporary directory
import 'dart:io'; // For File operations
import 'dart:async'; // For Timer

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  Map<String, dynamic> _location = {};

  bool isEdit = false;

  final gap10 = const SizedBox(height: 10);
  final gap16 = const SizedBox(height: 16);
  final gap24 = const SizedBox(height: 24);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  String? _imageUrl;
  String? eventId;

  // App integration service
  final AppIntegrationService _appService = AppIntegrationService();
  final ImagePickerUtil _imagePickerUtil = ImagePickerUtil();
  final MediaService _mediaService = MediaService();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _performerController = TextEditingController();
  final _specialGuestController = TextEditingController();
  final _priceController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _maxAttendeesController = TextEditingController();

  // Form values
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 2) % 24,
    minute: TimeOfDay.now().minute,
  );

  // --- Audio Recording Variables ---
  late final AudioRecorder _audioRecorder;
  final _audioPlayer = AudioPlayer();
  String? _recordedAudioPath;
  Duration _recordingDuration = Duration.zero;
  Duration _recordedFileDuration =
      Duration.zero; // Added for saved audio file duration
  Duration _currentPlaybackPosition =
      Duration.zero; // Added for current playback position
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  Timer? _recordingTimer;

  // --- Mood Emojis ---
  final List<String> _moodEmojis = [
    Images.starImg,
    Images.confusionImg,
    Images.dancingImg,
    Images.smileImg,
    Images.winklingImg,
  ];

  // --- State Variables ---
  String? _selectedMoodIconUrl;
  List<File> _selectedImageFiles = []; // Changed to File for actual images
  List<String> _uploadedImageFilenames = []; // Store uploaded image filenames
  List<File> _recordedAudioFiles = []; // List to store recorded audio files
  String? _recordedAudioFilePath; // Actual path to recorded audio file

  // --- Location Variables ---
  String _currentLocationAddress = 'Fetching location...';
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _fetchCurrentLocation();
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlayingAudio = false;
        _currentPlaybackPosition = Duration.zero; // Reset playback position
      });
    });
    // Listen for playback position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPlaybackPosition = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _performerController.dispose();
    _specialGuestController.dispose();
    _priceController.dispose();
    _venueNameController.dispose();
    _maxAttendeesController.dispose();
    _pinTitleController.dispose();
    _messageController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied.');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    setState(() {
      _currentLocationAddress = 'Getting your location...';
    });

    try {
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      // Get formatted address using LocationService
      final locationData = await locationService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          if (locationData != null && locationData['displayName'] != null) {
            _currentLocationAddress = locationData['displayName'] as String;
          } else if (locationData != null && locationData['address'] != null) {
            // Format address from components
            final address = locationData['address'] as Map<String, dynamic>;
            final components = [
              address['road'],
              address['city'] ?? address['town'] ?? address['village'],
              address['state'],
              address['country'],
            ].where((component) => component != null).join(', ');
            _currentLocationAddress =
                components.isNotEmpty ? components : 'Unknown location';
          } else {
            _currentLocationAddress = 'Location found but address unavailable';
          }
        });
      }
    } catch (e) {
      print('Error fetching location: $e');
      if (mounted) {
        setState(() {
          _currentLocationAddress = 'Could not get location.';
        });
        _showSnackBar('Failed to get location: $e');
      }
    }
  }

  void showLocationPicker() async {
    try {
      // Get saved or default location
      final defaultLocation = await _getDefaultLocation();

      // If location is empty, set default location
      if (_location.isEmpty && defaultLocation != null) {
        setState(() {
          _location = defaultLocation;
          _currentLocationAddress = defaultLocation['address'] as String;
        });
      }

      // Show loading indicator using ScaffoldMessenger instead of Get.dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Checking location permissions...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Check location permission first
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final hasPermission = await locationService.isLocationPermissionGranted();

      if (!hasPermission) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Permission'),
              content: const Text(
                'Location permission is required to select a location. Please enable it.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final position = await locationService.getCurrentLocation();
                    if (position != null && mounted) {
                      // Get formatted address for current location
                      final locationData = await locationService.reverseGeocode(
                        position.latitude,
                        position.longitude,
                      );
                      if (locationData != null && mounted) {
                        setState(() {
                          _currentLocationAddress =
                              locationData['displayName'] as String? ??
                                  'Location found but address unavailable';
                        });
                      }
                      showLocationPickerSheet(context, defaultLocation);
                    }
                  },
                  child: const Text('Enable'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // If we have permission, show the location picker
      if (mounted) {
        showLocationPickerSheet(context, defaultLocation);
      }
    } catch (e) {
      debugPrint("Error in location picker: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void showLocationPickerSheet(
    BuildContext context,
    Map<String, Object>? defaultLocation,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Location',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LocationPicker(
                  initialLocation:
                      _location.isEmpty ? defaultLocation : _location,
                  onLocationSelected: (location) async {
                    if (location.isNotEmpty) {
                      final locationService =
                          Provider.of<LocationService>(context, listen: false);
                      final locationData = await locationService.reverseGeocode(
                        location['latitude'] as double,
                        location['longitude'] as double,
                      );

                      if (mounted) {
                        setState(() {
                          _location = location;
                          _currentLocationAddress =
                              locationData?['displayName'] as String? ??
                                  location['address'] as String? ??
                                  'Location selected but address unavailable';
                        });
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Tap anywhere on the map to pin your location.",
                  maxLines: 4,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Confirm Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, Object>> _getDefaultLocation() async {
    try {
      final box = await Hive.openBox('locationBox');
      final savedLocation = box.get('lastLocation');

      if (savedLocation != null) {
        return {
          'latitude': savedLocation['latitude'] as double,
          'longitude': savedLocation['longitude'] as double,
          'address': savedLocation['address'] as String,
          'city': savedLocation['city'] as String,
          'state': savedLocation['state'] as String,
          'country': savedLocation['country'] as String,
        };
      }
    } catch (e) {
      debugPrint('Error getting saved location: $e');
    }

    // Return London as fallback default location
    return {
      'latitude': 51.5074,
      'longitude': -0.1278,
      'address': 'London, United Kingdom',
      'city': 'London',
      'state': 'England',
      'country': 'United Kingdom',
    };
  }

  // --- Controllers for Text Fields ---
  final TextEditingController _pinTitleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // --- Audio Recording Functions ---
  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        // Get temporary directory for storing the recording
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Start recording
        if (await _audioRecorder.hasPermission()) {
          await _audioRecorder.start(
            RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: filePath,
          );

          setState(() {
            _isRecording = true;
            _recordedAudioPath = filePath; // Update recorded audio path
            _recordingDuration = Duration.zero;
            _currentPlaybackPosition = Duration.zero; // Reset playback position
            _recordedFileDuration = Duration.zero; // Reset saved file duration
          });

          // Start timer to update recording duration
          _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (_isRecording) {
              setState(() {
                _recordingDuration += const Duration(seconds: 1);
              });
            } else {
              timer.cancel();
            }
          });
        } else {
          _showSnackBar('Microphone permission not granted');
        }
      } else {
        _showSnackBar('Microphone permission not granted');
      }
    } catch (e) {
      print('Error starting recording: $e');
      _showSnackBar('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordingTimer?.cancel();
        });

        if (path != null) {
          setState(() {
            _recordedAudioPath = path;
            // Get duration of recorded file
            _audioPlayer.setSourceDeviceFile(path).then((_) async {
              final duration = await _audioPlayer.getDuration();
              if (duration != null) {
                setState(() {
                  _recordedFileDuration = duration;
                });
              }
              // Stop audio player to ensure it's ready for next play
              await _audioPlayer.stop();
            });
          });
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      _showSnackBar('Failed to stop recording');
    }
  }

  Future<void> _playAudio() async {
    if (_recordedAudioPath == null) {
      _showSnackBar('No recording available');
      return;
    }

    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
      } else {
        // Stop any ongoing recording before playing
        if (_isRecording) {
          await _stopRecording();
        }
        await _audioPlayer.play(DeviceFileSource(_recordedAudioPath!));
      }
      setState(() {
        _isPlayingAudio = !_isPlayingAudio;
      });
    } catch (e) {
      print('Error playing audio: $e');
      _showSnackBar('Failed to play audio');
    }
  }

  Future<void> _deleteAudio() async {
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.stop();
      }
      if (_isRecording) {
        await _audioRecorder.stop(); // Stop recording if ongoing
      }

      if (_recordedAudioPath != null) {
        final file = File(_recordedAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _recordedAudioPath = null;
        _recordingDuration = Duration.zero;
        _recordedFileDuration = Duration.zero;
        _currentPlaybackPosition = Duration.zero;
        _isPlayingAudio = false;
        _isRecording = false;
        _recordingTimer?.cancel();
      });
    } catch (e) {
      print('Error deleting audio: $e');
      _showSnackBar('Failed to delete recording');
    }
  }

  // --- Audio Recording Callback Methods ---
  void _onAudioRecorded(String audioFilePath) {
    print('=== AUDIO RECORDED CALLBACK ===');
    print('Audio recorded: $audioFilePath');
    print('File exists: ${File(audioFilePath).existsSync()}');
    print('File size: ${File(audioFilePath).lengthSync()} bytes');

    setState(() {
      _recordedAudioFiles.add(File(audioFilePath));
    });

    print('Total recorded audio files: ${_recordedAudioFiles.length}');
    for (int i = 0; i < _recordedAudioFiles.length; i++) {
      print('Audio file $i: ${_recordedAudioFiles[i].path}');
    }

    _showSnackBar('Audio recorded successfully!');
  }

  void _onAudioDeleted() {
    print('=== AUDIO DELETED CALLBACK ===');
    print('Audio deleted');
    setState(() {
      // Remove the last recorded audio file
      if (_recordedAudioFiles.isNotEmpty) {
        _recordedAudioFiles.removeLast();
      }
    });
    print('Remaining audio files: ${_recordedAudioFiles.length}');
    _showSnackBar('Audio deleted');
  }

  // --- Image Picking Functions ---
  Future<void> _addPhoto() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Use the image picker to select and upload image
      _imagePickerUtil.showImageSourceSelection(
        context,
        (String imageFilename) async {
          // Success callback - imageFilename is just the filename, not full URL
          setState(() {
            _uploadedImageFilenames.add(imageFilename);
            _isLoading = false;
          });
          _showSnackBar('Image uploaded successfully!');
        },
        (String error) {
          // Error callback
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Failed to upload image: $error');
        },
        imageType: ImageType.pin_images,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error picking images: $e');
      _showSnackBar('Failed to pick images.');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _uploadedImageFilenames.removeAt(index);
    });
  }

  // --- Post Pin Logic ---
  Future<void> _postPin() async {
    final String title = _pinTitleController.text.trim();
    final String message = _messageController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('Please enter a Pin Title');
      return;
    }
    if (_selectedMoodIconUrl == null) {
      _showSnackBar('Please select a Mood');
      return;
    }
    // Use selected location if available, otherwise use current location
    double? pinLatitude = _location.isNotEmpty
        ? _location['latitude'] as double?
        : _currentLatitude;
    double? pinLongitude = _location.isNotEmpty
        ? _location['longitude'] as double?
        : _currentLongitude;

    if (pinLatitude == null || pinLongitude == null) {
      _showSnackBar('Please wait for location to be fetched or try again.');
      return;
    }
    if (_uploadedImageFilenames.isEmpty) {
      _showSnackBar('Please add at least one photo.');
      return;
    }
    if (_messageController.text.isEmpty) {
      _showSnackBar('Please enter a message....');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare audio files list
      List<File> audioFiles = [];
      // Add recorded audio files from AudioRecorderSection
      audioFiles.addAll(_recordedAudioFiles);
      // Add legacy recorded audio file if exists
      if (_recordedAudioPath != null) {
        audioFiles.add(File(_recordedAudioPath!));
      }

      print('=== POST PIN DEBUG ===');
      print(
          'Creating pin with ${_uploadedImageFilenames.length} image filenames');
      print('Image filenames: $_uploadedImageFilenames');
      print('Creating pin with ${audioFiles.length} audio files');

      for (int i = 0; i < audioFiles.length; i++) {
        final file = audioFiles[i];
        print('Audio file $i: ${file.path}');
        print('  - Exists: ${file.existsSync()}');
        print(
            '  - Size: ${file.existsSync() ? file.lengthSync() : 'N/A'} bytes');
      }

      // Create pin with image filenames and audio files
      final pinProvider = context.read<PinProvider>();

      // Upload audios to AWS
      print('Uploading ${audioFiles.length} audios...');
      final audioUrls = await _mediaService.uploadAudiosDirectly(audioFiles);
      print('Audio uploads completed: ${audioUrls.length} URLs');

      print(
          'Creating pin with ${_uploadedImageFilenames.length} image filenames:');
      print('Image filenames: $_uploadedImageFilenames');

      // Create pin in Firebase with image filenames and audio URLs
      final success = await pinProvider.createPin(
        title: title,
        description: message,
        mood: _selectedMoodIconUrl!,
        photoUrls:
            _uploadedImageFilenames, // Store filenames only, not full URLs
        audioUrls: audioUrls,
        latitude: pinLatitude,
        longitude: pinLongitude,
      );

      if (success) {
        _showSnackBar('Pin created successfully!');

        // Refresh the home screen data before navigating back
        await pinProvider.loadNearbyPins();
        await pinProvider.loadUserPins();

        // Navigate back to home screen
        Navigator.pop(context);
      } else {
        _showSnackBar('Failed to create pin. Please try again.');
      }
    } catch (e) {
      print('Error creating pin: $e');
      _showSnackBar('Error creating pin: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds"; // Simplified to show only minutes:seconds
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131F2B),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF253743),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    Text(
                      'Create Pin',
                      style: GoogleFonts.nunitoSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : _postPin,
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: _isLoading ? Colors.grey : Color(0xFFF5BF4D),
                            border: Border.all(
                                width: 0.5, color: Color(0xFFB37FEB)),
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 16,
                                  color: Color(0xFF9254DE).withOpacity(0.32))
                            ]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  'Drop Pin',
                                  style: GoogleFonts.nunitoSans(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    )
                  ],
                ),

                // --- Location Section ---
                GestureDetector(
                  onTap: showLocationPicker, // Re-fetch location on tap
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentLocationAddress,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.refresh,
                          color: Colors.white70,
                          size: 20,
                        ), // Refresh icon
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Select Mood Section ---
                _buildSectionHeader('Select Mood', Images.moodsymbols),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 6,
                    children: _moodEmojis.map((url) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMoodIconUrl = url;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedMoodIconUrl == url
                                ? Color(0xFF531DAB)
                                : Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.network(
                              url,
                              height: 40,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 1.5,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.emoji_emotions,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Pin Title Input ---
                _buildSectionHeader('Pin Title', Images.pinicon),
                const SizedBox(height: 10),
                _buildTextField(_pinTitleController, 'Enter pin title'),
                const SizedBox(height: 20),

                // --- Record Voice Section (Using AudioRecorderSection widget) ---
                _buildSectionHeader('Record Voice', Images.recordvoice),
                const SizedBox(height: 10),
                // Show all recorded audios above the recorder
                if (_recordedAudioFiles.isNotEmpty)
                  Column(
                    children: [
                      ..._recordedAudioFiles.asMap().entries.map((entry) {
                        int idx = entry.key;
                        File audioFile = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: RecordedAudioListItem(
                            audioFile: audioFile,
                            onDelete: () {
                              setState(() {
                                _recordedAudioFiles.removeAt(idx);
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                AudioRecorderSection(
                  onAudioRecorded: _onAudioRecorded,
                  onAudioDeleted: _onAudioDeleted,
                  // Don't show duplicate UI
                ),
                const SizedBox(height: 20),

                // --- Add Photos Section ---
                _buildSectionHeader('Add Photos', Images.attchingimages),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100, // Height for image thumbnails
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Display uploaded image filenames
                      ..._uploadedImageFilenames.asMap().entries.map((entry) {
                        int index = entry.key;
                        String imageFilename = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _imagePickerUtil.getUrlForUserUploadedImage(
                                        imageFilename),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // Add Photo Button
                      GestureDetector(
                        onTap: _isLoading ? null : _addPhoto,
                        child: DottedBorder(
                          // Correct usage: parameters directly here
                          borderType:
                              BorderType.RRect, // This is a direct parameter
                          radius: const Radius.circular(
                              16), // This is a direct parameter
                          dashPattern: const [
                            8,
                            4
                          ], // This is a direct parameter
                          strokeWidth: 2, // This is a direct parameter
                          color: _isLoading
                              ? Colors.grey
                              : Colors.white, // This is a direct parameter
                          child: Padding(
                            padding: const EdgeInsets.all(34.0),
                            child: _isLoading
                                ? SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- Message for Others Input ---
                _buildSectionHeader('Message for Others', Images.messageicon),
                const SizedBox(height: 10),
                _buildTextField(
                  _messageController,
                  'Write a message...',
                  maxLines: 5,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (mostly unchanged) ---
  Widget _buildSectionHeader(String title, String assestPath) {
    return Row(
      children: [
        Image.asset(
          assestPath,
          height: 24,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: AppColors.frameBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // --- New Helper Widgets for UI ---

  // Placeholder for waveform
  Widget _buildAudioWaveformPlaceholder({
    required Color color,
    bool isActive = false, // For active recording/playback visualization
  }) {
    return Container(
      height: 40, // Height of the waveform area
      decoration: BoxDecoration(
        color: Colors.grey[800], // Background color of waveform area
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            20, // Number of bars in the waveform
            (index) => Container(
              width: 4, // Width of each bar
              height: isActive
                  ? (index % 3 == 0 ? 30 : (index % 2 == 0 ? 20 : 10))
                      .toDouble() // Dynamic height for active state
                  : (index % 4 == 0 ? 25 : (index % 3 == 0 ? 15 : 8))
                      .toDouble(), // Static height for saved state
              color: color,
              margin: const EdgeInsets.symmetric(horizontal: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSquareActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(onPressed != null ? 0.7 : 0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 30),
        onPressed: onPressed,
      ),
    );
  }

  // UI for Saved Audio Playback (Top block in Figma)
  Widget _buildSavedAudioPlaybackSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3540),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // Play/Pause button (circular, purple)
          GestureDetector(
            onTap: _playAudio,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlayingAudio ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                // Waveform placeholder (yellow)
                Expanded(
                  child: _buildAudioWaveformPlaceholder(
                    color: Colors.yellow,
                    isActive: _isPlayingAudio, // Waveform animates if playing
                  ),
                ),
                const SizedBox(width: 10),
                // Duration
                Text(
                  _formatDuration(_recordedFileDuration),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 10),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white70),
                  onPressed: _deleteAudio,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UI for Active Recording/Playback Controls (Middle and Bottom blocks in Figma)
  Widget _buildActiveSessionControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3540),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Middle waveform and duration display
          _buildAudioWaveformPlaceholder(
            color: _isRecording
                ? Colors.green
                : (_isPlayingAudio ? Colors.yellow : Colors.grey),
            isActive: _isRecording || _isPlayingAudio,
          ),
          const SizedBox(height: 10),
          Text(
            _isRecording
                ? 'Recording... ${_formatDuration(_recordingDuration)}'
                : _isPlayingAudio
                    ? 'Playing... ${_formatDuration(_currentPlaybackPosition)}'
                    : '00:00', // Default when idle
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Bottom control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop button (square)
              _buildSquareActionButton(
                icon: Icons.stop,
                onPressed: _isRecording ? _stopRecording : null,
                color: _isRecording ? Colors.purple : Colors.grey,
              ),
              const SizedBox(width: 20),

              // Central circular button (mic/record/pause)
              if (_isRecording)
                GestureDetector(
                  onTap: _stopRecording, // Tap to stop recording
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
              else if (_isPlayingAudio)
                GestureDetector(
                  onTap: _playAudio, // Tap to pause playing
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.purpleAccent,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.purpleAccent,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              const SizedBox(width: 20),

              // Delete button (square)
              _buildSquareActionButton(
                icon: Icons.delete,
                onPressed: (_recordedAudioPath != null || _isRecording)
                    ? _deleteAudio
                    : null, // Enable if audio exists or recording
                color: (_recordedAudioPath != null || _isRecording)
                    ? Colors.red
                    : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem('My Pins', Icons.push_pin, () {
            print('My Pins tapped from Create Pin Screen');
          }),
          _buildCentralActionButton(() {
            print('Map tapped from Create Pin Screen');
            Navigator.pop(context); // Go back to Home Screen (Map)
          }),
          _buildBottomNavItem('New Pin', Icons.add_location_alt, () {
            print('New Pin tapped (already on Create Pin Screen)');
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralActionButton(VoidCallback onPressed) {
    return SizedBox(
      width: 70,
      height: 70,
      child: FloatingActionButton(
        heroTag: 'central_nav_fab_create_pin',
        onPressed: onPressed,
        backgroundColor: Colors.amber,
        child: const Icon(
          Icons.location_searching,
          color: Colors.black,
          size: 35,
        ),
        elevation: 5,
      ),
    );
  }
}
