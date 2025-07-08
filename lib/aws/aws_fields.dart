import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// const appLink ="https://apps.apple.com/us/app/id6744412329";
/// base url for AWS
final baseUrl =
//  "https://app.stecoraeventa.info/";
    "https://d1r9c4nksnam33.cloudfront.net/";
final String baseUrlForUploadPostApi = "${baseUrl}upload";
final String baseUrlToFetchStaticImage = "$baseUrl$bundleNameToFetchImage";
final String baseUrlToUploadAndFetchUsersImage =
    "$baseUrl${bundleNameToFetchImage}upload";
const String bundleNameForPostAPI = "p27";

/// it will be fixed, it will never changed
String get bundleNameToFetchImage => "p27/";

/// Use the correct bundle name to match upload path

/// it will be empty for production, will be 388/ for testing
String getUrlForUserUploadedImage(String imageName) {
  print('getUrlForUserUploadedImage called with: $imageName');
  print(
      'baseUrlToUploadAndFetchUsersImage: $baseUrlToUploadAndFetchUsersImage');

  if (imageName.startsWith("http")) {
    print('Returning direct URL: $imageName');
    return imageName;
  }
  if (imageName.startsWith("/")) {
    final url = baseUrlToUploadAndFetchUsersImage + imageName;
    print('Returning URL with leading slash: $url');
    return url;
  }
  final url = "$baseUrlToUploadAndFetchUsersImage/$imageName";
  print('Returning URL with slash: $url');
  return url;
}

String getUrlForUserUploadedAudio(String audioName) {
  print('getUrlForUserUploadedAudio called with: $audioName');
  print(
      'baseUrlToUploadAndFetchUsersImage: $baseUrlToUploadAndFetchUsersImage');

  if (audioName.startsWith("http")) {
    print('Returning direct URL: $audioName');
    return audioName;
  }
  if (audioName.startsWith("/")) {
    final url = baseUrlToUploadAndFetchUsersImage + audioName;
    print('Returning URL with leading slash: $url');
    return url;
  }
  final url = "$baseUrlToUploadAndFetchUsersImage/$audioName";
  print('Returning URL with slash: $url');
  return url;
}

Future<String?> uploadImageToAWS(
    {required File file, required String fileName}) async {
  // Add images/ prefix to fileName
  final imageFileName = 'images/$fileName';
  String? url = await getSignedUrl(imageFileName, bundleNameForPostAPI);
  if (url != null && url.isNotEmpty) {
    return await uploadFileToS3(
      signedUrl: url,
      filePath: file.path,
      fileName: imageFileName,
    );
  }
  return null;
}

Future<String?> uploadAudioToAWS(
    {required File file, required String fileName}) async {
  // Add audios/ prefix to fileName
  final audioFileName = 'audios/$fileName';
  String? url = await getSignedUrl(audioFileName, bundleNameForPostAPI);
  if (url != null && url.isNotEmpty) {
    return await uploadFileToS3(
      signedUrl: url,
      filePath: file.path,
      fileName: audioFileName,
    );
  }
  return null;
}

Future<String?> getSignedUrl(
  String fileName,
  String bundle,
) async {
  // The JSON payload that will be sent in the request body
  final Map<String, String> payload = {
    'fileName': fileName, // image.png or audios/AUDIO_xxx.mp3
    'bundle': bundle,
  };

  // Convert the payload to JSON
  final String jsonPayload = json.encode(payload);

  try {
    // Make the PUT request
    final response = await http.post(
      Uri.parse(baseUrlForUploadPostApi),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonPayload,
    );

    // Check the response status
    if (response.statusCode == 200) {
      debugPrint('getSignedUrl Request successful: ${response.body}');
      Map map = json.decode(response.body);
      if (map.containsKey("data")) {
        String signedUrl = map['data'];
        return signedUrl;
      }
    } else {
      debugPrint(
          'getSignedUrl Failed request: ${response.statusCode} : ${response.body}');
    }
  } catch (e) {
    debugPrint('getSignedUrl Error: $e');
  }
  return null;
}

Future<String?> uploadFileToS3(
    {required String signedUrl,
    required String filePath,
    required String fileName}) async {
  try {
    // Create a File object from the provided file path
    final file = File(filePath);

    // Make sure the file exists
    if (await file.exists()) {
      // Read the file as bytes
      final fileBytes = await file.readAsBytes();

      // Determine content type based on file extension
      String contentType = 'application/octet-stream';
      if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.mp3')) {
        contentType = 'audio/mpeg';
      } else if (fileName.toLowerCase().endsWith('.wav')) {
        contentType = 'audio/wav';
      } else if (fileName.toLowerCase().endsWith('.m4a')) {
        contentType = 'audio/mp4';
      }

      // Send a PUT request with the file bytes as the body
      final response = await http.put(
        Uri.parse(signedUrl), // The signed URL provided
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileBytes.length.toString(),
        },
        body: fileBytes, // Send the file content as the body
      );
      // debugPrint("File uploaded string [${(await response).toString()}]");
      // Check if the upload was successful
      if (response.statusCode == 200) {
        debugPrint("File uploaded body [${response.body}]");
        // Map map = json.decode(response.body);

        // Use appropriate URL getter based on file type
        if (fileName.startsWith('audios/')) {
          debugPrint(
              'Audio uploaded successfully! at path ${getUrlForUserUploadedAudio(fileName)}');
        } else {
          debugPrint(
              'Image uploaded successfully! at path ${getUrlForUserUploadedImage(fileName)}');
        }
        return fileName;
      } else {
        debugPrint(
            'File uploaded Failed to upload file: ${response.statusCode} : ${response.body}');
        debugPrint(response.body);
      }
    } else {
      debugPrint(
          'File uploaded File not found at the specified path: $filePath');
    }
  } catch (e) {
    debugPrint('File uploaded Error uploading file: $e');
  }

  return null;
}
