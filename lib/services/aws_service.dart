import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:memory_pins_app/aws/aws_fields.dart' as AppConstant;

class AWSService {
  final Uuid _uuid = Uuid();

  /// Upload profile image and return only the filename (not full URL)
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final fileName =
          'IMG_Profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Use existing AWS upload function
      final uploadedFileName = await AppConstant.uploadImageToAWS(
        file: imageFile,
        fileName: fileName,
      );

      if (uploadedFileName != null) {
        // Return only the filename, not the full URL
        return uploadedFileName;
      } else {
        throw Exception('Failed to upload profile image');
      }
    } catch (e) {
      throw Exception('Error uploading profile image: $e');
    }
  }

  /// Upload pin image and return only the filename (not full URL)
  Future<String> uploadPinImage(File imageFile) async {
    try {
      final fileName =
          'IMG_Pin_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Use existing AWS upload function
      final uploadedFileName = await AppConstant.uploadImageToAWS(
        file: imageFile,
        fileName: fileName,
      );

      if (uploadedFileName != null) {
        // Return only the filename, not the full URL
        return uploadedFileName;
      } else {
        throw Exception('Failed to upload pin image');
      }
    } catch (e) {
      throw Exception('Error uploading pin image: $e');
    }
  }

  /// Upload multiple pin images and return only filenames (not full URLs)
  Future<List<String>> uploadPinImages(List<File> imageFiles) async {
    final List<String> uploadedFilenames = [];

    for (final imageFile in imageFiles) {
      try {
        final fileName = await uploadPinImage(imageFile);
        uploadedFilenames.add(fileName);
      } catch (e) {
        print('Failed to upload pin image ${imageFile.path}: $e');
        // Continue with other images even if one fails
      }
    }

    return uploadedFilenames;
  }

  /// Upload image to AWS S3 using existing AWS fields
  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = '${_uuid.v4()}_${path.basename(imageFile.path)}';

      // Use existing AWS upload function
      final uploadedFileName = await AppConstant.uploadImageToAWS(
        file: imageFile,
        fileName: fileName,
      );

      if (uploadedFileName != null) {
        return AppConstant.getUrlForUserUploadedImage(uploadedFileName);
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Upload multiple images to AWS S3
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      try {
        final url = await uploadImage(imageFile);
        uploadedUrls.add(url);
      } catch (e) {
        print('Failed to upload image ${imageFile.path}: $e');
        // Continue with other images even if one fails
      }
    }

    return uploadedUrls;
  }

  /// Upload audio file to AWS S3 using existing AWS fields
  Future<String> uploadAudio(File audioFile) async {
    try {
      final fileName = 'AUDIO_${DateTime.now().millisecondsSinceEpoch}.mp3';

      // Use existing AWS upload function for audio
      final uploadedFileName = await AppConstant.uploadAudioToAWS(
        file: audioFile,
        fileName: fileName,
      );

      if (uploadedFileName != null) {
        return AppConstant.getUrlForUserUploadedAudio(uploadedFileName);
      } else {
        throw Exception('Failed to upload audio');
      }
    } catch (e) {
      throw Exception('Error uploading audio: $e');
    }
  }

  /// Upload multiple audio files to AWS S3
  Future<List<String>> uploadAudios(List<File> audioFiles) async {
    print('=== AWS SERVICE AUDIO UPLOAD DEBUG ===');
    print('Uploading ${audioFiles.length} audio files');

    final List<String> uploadedUrls = [];

    for (int i = 0; i < audioFiles.length; i++) {
      try {
        final audioFile = audioFiles[i];
        print('Uploading audio file $i: ${audioFile.path}');
        print('  - File exists: ${audioFile.existsSync()}');
        print(
            '  - File size: ${audioFile.existsSync() ? audioFile.lengthSync() : 'N/A'} bytes');

        final url = await uploadAudio(audioFile);
        print('  - Upload result: $url');
        uploadedUrls.add(url);
      } catch (e) {
        print('Failed to upload audio file ${audioFiles[i].path}: $e');
        // Continue with other audios even if one fails
      }
    }

    print('Audio uploads completed: ${uploadedUrls.length} URLs');
    print('Uploaded URLs: $uploadedUrls');
    return uploadedUrls;
  }

  /// Upload image from bytes (for camera capture)
  Future<String> uploadImageFromBytes(
      Uint8List imageBytes, String fileName) async {
    try {
      final finalFileName = '${_uuid.v4()}_$fileName';

      // Create temporary file
      final tempDir = await Directory.systemTemp.createTemp('image_upload');
      final tempFile = File('${tempDir.path}/$finalFileName');
      await tempFile.writeAsBytes(imageBytes);

      // Upload using existing function
      final uploadedFileName = await AppConstant.uploadImageToAWS(
        file: tempFile,
        fileName: finalFileName,
      );

      // Clean up temp file
      await tempFile.delete();
      await tempDir.delete();

      if (uploadedFileName != null) {
        return AppConstant.getUrlForUserUploadedImage(uploadedFileName);
      } else {
        throw Exception('Failed to upload image from bytes');
      }
    } catch (e) {
      throw Exception('Error uploading image from bytes: $e');
    }
  }

  /// Upload audio from bytes (for voice recording)
  Future<String> uploadAudioFromBytes(
      Uint8List audioBytes, String fileName) async {
    try {
      final finalFileName =
          'AUDIO_${DateTime.now().millisecondsSinceEpoch}.mp3';

      // Create temporary file
      final tempDir = await Directory.systemTemp.createTemp('audio_upload');
      final tempFile = File('${tempDir.path}/$finalFileName');
      await tempFile.writeAsBytes(audioBytes);

      // Use existing AWS upload function for audio
      final uploadedFileName = await AppConstant.uploadAudioToAWS(
        file: tempFile,
        fileName: finalFileName,
      );

      // Clean up temp file
      await tempFile.delete();
      await tempDir.delete();

      if (uploadedFileName != null) {
        return AppConstant.getUrlForUserUploadedAudio(uploadedFileName);
      } else {
        throw Exception('Failed to upload audio from bytes');
      }
    } catch (e) {
      throw Exception('Error uploading audio from bytes: $e');
    }
  }

  /// Delete file from AWS S3 (placeholder - implement if needed)
  Future<bool> deleteFile(String fileUrl) async {
    try {
      // This would need to be implemented based on your AWS setup
      // For now, return true as placeholder
      print('Delete file functionality not implemented yet');
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Get file extension from file name
  String _getFileExtension(String fileName) {
    return path.extension(fileName).toLowerCase();
  }

  /// Validate file type
  bool _isValidImageFile(String fileName) {
    final extension = _getFileExtension(fileName);
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
  }

  bool _isValidAudioFile(String fileName) {
    final extension = _getFileExtension(fileName);
    return ['.mp3', '.wav', '.m4a', '.aac', '.ogg'].contains(extension);
  }

  /// Validate file size (in MB)
  bool _isValidFileSize(File file, int maxSizeMB) {
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB <= maxSizeMB;
  }

  /// Upload image with validation
  Future<String> uploadImageWithValidation(File imageFile,
      {int maxSizeMB = 10}) async {
    if (!_isValidImageFile(imageFile.path)) {
      throw Exception(
          'Invalid image file type. Supported: jpg, jpeg, png, gif, webp');
    }

    if (!_isValidFileSize(imageFile, maxSizeMB)) {
      throw Exception('Image file size exceeds $maxSizeMB MB limit');
    }

    return await uploadImage(imageFile);
  }

  /// Upload audio with validation
  Future<String> uploadAudioWithValidation(File audioFile,
      {int maxSizeMB = 50}) async {
    if (!_isValidAudioFile(audioFile.path)) {
      throw Exception(
          'Invalid audio file type. Supported: mp3, wav, m4a, aac, ogg');
    }

    if (!_isValidFileSize(audioFile, maxSizeMB)) {
      throw Exception('Audio file size exceeds $maxSizeMB MB limit');
    }

    return await uploadAudio(audioFile);
  }
}
