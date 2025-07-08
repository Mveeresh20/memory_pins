import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/presentation/Widgets/add_photo_grid_item.dart';
import 'package:memory_pins_app/presentation/Widgets/audio_list_item.dart';
import 'package:memory_pins_app/presentation/Widgets/photo_grid_item.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';



// --- Data Models (for dynamic content) ---


class PinDetailScreen extends StatefulWidget {
  final PinDetail pinDetail; // Pass the data to the screen

  const PinDetailScreen({Key? key, required this.pinDetail}) : super(key: key);

  @override
  State<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends State<PinDetailScreen> {
  // You might manage audio playback state here or in a separate provider
  // e.g., AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Initialize audio player if needed
  }

  @override
  void dispose() {
    // Dispose audio player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Color(0xFF253743), // Dark background
   
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

                  Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 20),

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
                    child: Icon(Icons.format_quote, color: Colors.white, size:20),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.format_quote, color: Colors.white, size: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Text(
                      widget.pinDetail.description,
                      style: text14W500White(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
        
              // --- Audios Section ---
               Text(
                textAlign: TextAlign.left,
                'Audios',
                style: text18W700White(context),
              ),
              const SizedBox(height: 15),
              ListView.separated(
                separatorBuilder: (context, index) => SizedBox(height: 16),
                shrinkWrap: true, // Important for nested list views
                physics:  NeverScrollableScrollPhysics(), // Disable scrolling of inner list
                itemCount: widget.pinDetail.audios.length,
                itemBuilder: (context, index) {
                  final audio = widget.pinDetail.audios[index];
                  return AudioListItem(audio: audio);
                },
              ),
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
                itemCount: widget.pinDetail.photos.length + 1, // +1 for the "add new photo" button
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