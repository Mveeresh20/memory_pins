import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/presentation/Widgets/add_photo_grid_item.dart';
import 'package:memory_pins_app/presentation/Widgets/audio_list_item.dart';
import 'package:memory_pins_app/presentation/Widgets/photo_grid_item.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:provider/provider.dart';

// --- Data Models (for dynamic content) ---

class PinDetailScreen extends StatefulWidget {
  final PinDetail pinDetail; // Pass the data to the screen
  final Pin? originalPin; // Pass the original pin for saving

  const PinDetailScreen({
    Key? key,
    required this.pinDetail,
    this.originalPin, // Make it optional for backward compatibility
  }) : super(key: key);

  @override
  State<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends State<PinDetailScreen> {
  bool _isSaved = false; // Track if pin is saved

  @override
  void initState() {
    super.initState();
    // Debug logging for audio data
    print('=== PIN DETAIL SCREEN DEBUG ===');
    print('Pin title: ${widget.pinDetail.title}');
    print('Audio items count: ${widget.pinDetail.audios.length}');
    print(
        'Audio URLs: ${widget.pinDetail.audios.map((a) => a.audioUrl).toList()}');
    print(
        'Audio URLs with content: ${widget.pinDetail.audios.where((a) => a.audioUrl.isNotEmpty && a.audioUrl != 'null').map((a) => a.audioUrl).toList()}');
    print(
        'Will show audio section: ${widget.pinDetail.audios.any((audio) => audio.audioUrl.isNotEmpty && audio.audioUrl != 'null')}');
    print('================================');

    // Check if pin is already saved
    _checkIfPinIsSaved();
    _incrementPinViews();
  }

  void _checkIfPinIsSaved() async {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    // Use the original pin ID if available, otherwise use title
    final pinId = widget.originalPin?.id ?? widget.pinDetail.title;
    final isSaved = await pinProvider.isPinSaved(pinId);
    if (mounted) {
      setState(() {
        _isSaved = isSaved;
      });
    }
  }

  void _incrementPinViews() async {
    if (widget.originalPin != null) {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      await pinProvider.incrementPinViews(widget.originalPin!.id);
    }
  }

  void _incrementPinPlays() async {
    if (widget.originalPin != null) {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      await pinProvider.incrementPinPlays(widget.originalPin!.id);
    }
  }

  void _toggleSave() {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);

    setState(() {
      _isSaved = !_isSaved;
    });

    // Use the original pin ID if available, otherwise use title
    final pinId = widget.originalPin?.id ?? widget.pinDetail.title;

    if (_isSaved) {
      // Save the pin
      pinProvider.savePin(pinId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pin saved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Unsave the pin
      pinProvider.unsavePin(pinId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pin removed from saved'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Dispose audio player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF253743), // Dark background

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    '📍Title: ${widget.pinDetail.title}',
                    style: GoogleFonts.nunitoSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleSave,
                    child: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                      color: _isSaved ? Colors.white : Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),

              // --- Pin Title ---

              // Center(
              //   child: Text(
              //     '📍Title: ${widget.pinDetail.title}',
              //     style: GoogleFonts.nunitoSans(
              //       color: Colors.white,
              //       fontSize: 14,
              //       fontWeight: FontWeight.w900,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 24),

              // --- Quote/Description Section ---
              Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child:
                        Icon(Icons.format_quote, color: Colors.white, size: 20),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child:
                        Icon(Icons.format_quote, color: Colors.white, size: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    child: Text(
                      widget.pinDetail.description,
                      style: text14W500White(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Audios Section ---
              // Debug logging to see what's in the audios list
              if (widget.pinDetail.audios.isNotEmpty) ...[
                // Additional check: only show if there are actual audio URLs
                if (widget.pinDetail.audios.any((audio) =>
                    audio.audioUrl.isNotEmpty && audio.audioUrl != 'null')) ...[
                  Text(
                    textAlign: TextAlign.left,
                    'Audios',
                    style: text18W700White(context),
                  ),
                  const SizedBox(height: 15),
                  ListView.separated(
                    separatorBuilder: (context, index) => SizedBox(height: 16),
                    shrinkWrap: true, // Important for nested list views
                    physics:
                        NeverScrollableScrollPhysics(), // Disable scrolling of inner list
                    itemCount: widget.pinDetail.audios
                        .where((audio) =>
                            audio.audioUrl.isNotEmpty &&
                            audio.audioUrl != 'null')
                        .length,
                    itemBuilder: (context, index) {
                      final validAudios = widget.pinDetail.audios
                          .where((audio) =>
                              audio.audioUrl.isNotEmpty &&
                              audio.audioUrl != 'null')
                          .toList();
                      final audio = validAudios[index];
                      return AudioListItem(
                        audio: audio,
                        onPlayIncrement: _incrementPinPlays,
                      );
                    },
                  ),
                ],
              ],

              const SizedBox(height: 30),

              // --- Photos Section ---
              Text(
                'Photos',
                style: text18W700White(context),
              ),
              const SizedBox(height: 15),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 2 items per row
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0, // Square items
                ),
                itemCount: widget.pinDetail.photos.length +
                    1, // +1 for the "add new photo" button
                itemBuilder: (context, index) {
                  if (index < widget.pinDetail.photos.length) {
                    final photo = widget.pinDetail.photos[index];
                    return PhotoGridItem(photo: photo);
                  } else {
                    // "Add New Photo" button
                    return AddPhotoGridItem(onTap: () {
                      // Handle picking a new photo
                      print('Add new photo tapped!');
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
