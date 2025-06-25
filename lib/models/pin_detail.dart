import 'package:flutter/material.dart';

// --- Data Models (for dynamic content) ---
class PinDetail {
  final String title;
  final String description;
  final List<AudioItem> audios;
  final List<PhotoItem> photos;

  PinDetail({
    required this.title,
    required this.description,
    required this.audios,
    required this.photos,
  });
}

class AudioItem {
  late final String audioUrl; // URL or local path to the audio file
  late final String duration; // Formatted duration like "15:31"
  // Potentially add waveform data here if you're pre-processing it

  AudioItem({
    required this.audioUrl,
    required this.duration, // <--- This line ensures 'duration' is initialized
  });
}

class PhotoItem {
  late final String imageUrl;

  PhotoItem({
    required this.imageUrl,
  });
  // URL or local path to the image
}
