import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:memory_pins_app/utills/Constants/app_constant.dart';
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

  // Upload audio file to S3
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

      String? signedUrl =
          await getSignedUrl(_fileName, AppConstant.bundleNameForPostAPI);
      log('Received signed URL: ${signedUrl != null ? 'Success' : 'Failed'}');

      if (signedUrl == null || signedUrl.isEmpty) {
        log('Failed to get signed URL');
        onUploadFailure('Failed to get signed URL');
        return;
      }

      final fileBytes = await file!.readAsBytes();
      log('File size: ${fileBytes.length} bytes');

      final response = await http.put(
        Uri.parse(signedUrl),
        headers: {
          'Content-Type': 'audio/mpeg',
          'Content-Length': fileBytes.length.toString(),
        },
        body: fileBytes,
      );

      log('Upload response status: ${response.statusCode}');
      log('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Audio uploaded successfully. File URL: $uploadedFileUrl');
        onUploadSuccess(uploadedFileUrl);
      } else {
        log('Failed to upload audio. Status code: ${response.statusCode}');
        onUploadFailure('Failed to upload audio: ${response.statusCode}');
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
