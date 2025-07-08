import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:memory_pins_app/aws/aws_fields.dart' as AppConstant;
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class AudioPickerUtil {
  String uploadedFileUrl = '';
  String _fileName = '';
  File? file;

  // Generate unique audio file name
  String _generateUniqueAudioName() {
    return 'AUDIO_${DateTime.now().millisecondsSinceEpoch}.mp3';
  }

  // Get audio file path
  Future<String?> getAudioFilePath(String localPath) async {
    if (localPath.isEmpty) {
      log('Audio file path is empty');
      return null;
    }
    log('Audio file path: $localPath');
    return localPath;
  }

  // Method to generate the signed URL for audio
  Future<String?> getSignedUrl(String fileName, String bundle) async {
    final String url = AppConstant.baseUrlForUploadPostApi;
    uploadedFileUrl = fileName;
    log('uploadedFileUrl -> ${url + uploadedFileUrl}');

    final Map<String, String> payload = {
      'fileName': fileName,
      'bundle': bundle,
    };

    final String jsonPayload = json.encode(payload);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonPayload,
      );

      if (response.statusCode == 200) {
        log('getSignedUrl Request successful: ${response.body}');
        Map map = json.decode(response.body);
        if (map.containsKey("data")) {
          String signedUrl = map['data'];
          return signedUrl;
        }
      } else {
        log('getSignedUrl Failed request: ${response.statusCode} : ${response.body}');
      }
    } catch (e) {
      log('getSignedUrl Error: $e');
    }
    return null;
  }

  // Upload audio file to S3 using new AWS service
  Future<void> uploadAudioToS3(
    String localPath,
    BuildContext context,
    Function(String) onUploadSuccess,
    Function(String) onUploadFailure,
  ) async {
    try {
      log('Attempting to upload audio from path: $localPath');
      file = File(localPath);

      if (file == null) {
        log('File is null');
        onUploadFailure('Audio file not found');
        return;
      }

      if (!await file!.exists()) {
        log('File does not exist at path: $localPath');
        onUploadFailure('Audio file not found');
        return;
      }

      _fileName = _generateUniqueAudioName();
      log('Generated unique filename: $_fileName');

      // Use the new uploadAudioToAWS function
      final uploadedFileName = await AppConstant.uploadAudioToAWS(
        file: file!,
        fileName: _fileName,
      );

      if (uploadedFileName != null) {
        log('Audio uploaded successfully. File URL: $uploadedFileName');
        final audioUrl =
            AppConstant.getUrlForUserUploadedAudio(uploadedFileName);
        onUploadSuccess(audioUrl);
      } else {
        log('Failed to upload audio');
        onUploadFailure('Failed to upload audio');
      }
    } catch (e) {
      log('Error uploading audio: $e');
      onUploadFailure('Error uploading audio: $e');
    }
  }

  // Get URL for the uploaded audio
  String getUrlForUploadedAudio(String audioFilePath) {
    if (audioFilePath.startsWith("/")) {
      return AppConstant.baseUrlToUploadAndFetchUsersImage + audioFilePath;
    }
    return "${AppConstant.baseUrlToUploadAndFetchUsersImage}/$audioFilePath";
  }
}
