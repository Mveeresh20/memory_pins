import 'dart:io';
import 'package:flutter/material.dart';
import 'package:memory_pins_app/utills/Constants/image_picker_util.dart';
import 'package:memory_pins_app/utills/Constants/audio_picker_util.dart';
import 'package:memory_pins_app/utills/Constants/imageType.dart';
import 'package:memory_pins_app/services/aws_service.dart';

class MediaService {
  final ImagePickerUtil _imagePickerUtil = ImagePickerUtil();
  final AudioPickerUtil _audioPickerUtil = AudioPickerUtil();
  final AWSService _awsService = AWSService();

  /// Pick and upload multiple images
  Future<List<String>> pickAndUploadImages(BuildContext context) async {
    final List<String> uploadedUrls = [];

    _imagePickerUtil.showImageSourceSelection(
      context,
      (String fileName) async {
        // Success callback - upload to AWS
        try {
          final imageUrl =
              _imagePickerUtil.getUrlForUserUploadedImage(fileName);
          uploadedUrls.add(imageUrl);
        } catch (e) {
          print('Error uploading image: $e');
        }
      },
      (String error) {
        // Failure callback
        print('Image upload failed: $error');
      },
    );

    return uploadedUrls;
  }

  /// Pick and upload single image
  Future<String?> pickAndUploadSingleImage(BuildContext context) async {
    String? uploadedUrl;

    _imagePickerUtil.showImageSourceSelection(
      context,
      (String fileName) async {
        // Success callback - upload to AWS
        try {
          final imageUrl =
              _imagePickerUtil.getUrlForUserUploadedImage(fileName);
          uploadedUrl = imageUrl;
        } catch (e) {
          print('Error uploading image: $e');
        }
      },
      (String error) {
        // Failure callback
        print('Image upload failed: $error');
      },
    );

    return uploadedUrl;
  }

  /// Pick and upload multiple pin images (returns filenames, not URLs)
  Future<List<String>> pickAndUploadPinImages(BuildContext context) async {
    final List<String> uploadedFilenames = [];

    _imagePickerUtil.showImageSourceSelection(
      context,
      (String fileName) async {
        // Success callback - fileName is already just the filename
        try {
          uploadedFilenames.add(fileName);
        } catch (e) {
          print('Error uploading pin image: $e');
        }
      },
      (String error) {
        // Failure callback
        print('Pin image upload failed: $error');
      },
      imageType: ImageType.pin_images,
    );

    return uploadedFilenames;
  }

  /// Pick and upload single pin image (returns filename, not URL)
  Future<String?> pickAndUploadSinglePinImage(BuildContext context) async {
    String? uploadedFilename;

    _imagePickerUtil.showImageSourceSelection(
      context,
      (String fileName) async {
        // Success callback - fileName is already just the filename
        try {
          uploadedFilename = fileName;
        } catch (e) {
          print('Error uploading pin image: $e');
        }
      },
      (String error) {
        // Failure callback
        print('Pin image upload failed: $error');
      },
      imageType: ImageType.pin_images,
    );

    return uploadedFilename;
  }

  /// Record and upload audio
  Future<String?> recordAndUploadAudio(BuildContext context) async {
    String? uploadedUrl;

    // This would integrate with your existing audio recording functionality
    // For now, using the audio picker util
    try {
      // You'll need to implement this based on your audio recording flow
      // This is a placeholder for the audio recording and upload process
      print('Audio recording and upload functionality to be implemented');
    } catch (e) {
      print('Error recording and uploading audio: $e');
    }

    return uploadedUrl;
  }

  /// Upload existing audio file
  Future<String?> uploadAudioFile(
      String audioFilePath, BuildContext context) async {
    try {
      await _audioPickerUtil.uploadAudioToS3(
        audioFilePath,
        context,
        (String fileName) {
          // Success callback
          final audioUrl = _audioPickerUtil.getUrlForUploadedAudio(fileName);
          return audioUrl;
        },
        (String error) {
          // Failure callback
          print('Audio upload failed: $error');
        },
      );
    } catch (e) {
      print('Error uploading audio file: $e');
    }

    return null;
  }

  /// Upload multiple files using AWS service directly
  Future<List<String>> uploadImagesDirectly(List<File> imageFiles) async {
    return await _awsService.uploadImages(imageFiles);
  }

  /// Upload multiple audio files using AWS service directly
  Future<List<String>> uploadAudiosDirectly(List<File> audioFiles) async {
    return await _awsService.uploadAudios(audioFiles);
  }

  /// Upload multiple pin images using AWS service directly (returns filenames)
  Future<List<String>> uploadPinImagesDirectly(List<File> imageFiles) async {
    return await _awsService.uploadPinImages(imageFiles);
  }

  /// Upload single image using AWS service directly
  Future<String> uploadImageDirectly(File imageFile) async {
    return await _awsService.uploadImage(imageFile);
  }

  /// Upload single pin image using AWS service directly (returns filename)
  Future<String> uploadPinImageDirectly(File imageFile) async {
    return await _awsService.uploadPinImage(imageFile);
  }

  /// Upload single audio using AWS service directly
  Future<String> uploadAudioDirectly(File audioFile) async {
    return await _awsService.uploadAudio(audioFile);
  }

  /// Get image URL from filename
  String getImageUrl(String imageName) {
    return _imagePickerUtil.getImageUrl(imageName);
  }

  /// Get audio URL from filename
  String getAudioUrl(String audioName) {
    return _audioPickerUtil.getUrlForUploadedAudio(audioName);
  }
}
