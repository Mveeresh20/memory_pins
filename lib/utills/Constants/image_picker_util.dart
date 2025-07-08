import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memory_pins_app/aws/aws_fields.dart' as AppConstant;
import 'package:memory_pins_app/aws/image_compresion.dart';

import 'package:path/path.dart'; // For extracting the file name
import 'package:http/http.dart' as http;



class ImagePickerUtil {
  String uploadedFileUrl = '';
  final ImagePicker _picker = ImagePicker();
  String _fileName = '';
  File? file;

  String getImageUrl(String imageName) {
    return "${AppConstant.baseUrlToFetchStaticImage}images/$imageName";
  }

  void showImageSourceSelection(
    BuildContext context,
    Function(String) onUploadSuccess, // Pass callback for success
    Function(String) onUploadFailure,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  _pickImageFromGallery(context, onUploadSuccess,
                      onUploadFailure); // Pass callbacks
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  _pickImageFromCamera(context, onUploadSuccess,
                      onUploadFailure); // Pass callbacks
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery(
    BuildContext context,
    Function(String) onUploadSuccess, // Callback for success
    Function(String) onUploadFailure, // Callback for failure
  ) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      file = File(image.path);
      debugPrint("Original image picked: ${image.path}");

      // Compress the image before showing preview
      try {
        file = await pickAndCompressImage(file!);
        debugPrint("Image compressed: ${file!.path}");
        await _showImagePreviewDialog(
            context, file!, onUploadSuccess, onUploadFailure);
      } catch (e) {
        debugPrint("Error compressing image: $e");
        onUploadFailure("Error compressing image: $e");
      }
    }
  }

  /// Function to capture image using camera
  Future<void> _pickImageFromCamera(
    BuildContext context,
    Function(String) onUploadSuccess, // Callback for success
    Function(String) onUploadFailure, // Callback for failure
  ) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      file = File(image.path);
      debugPrint("Original image captured: ${image.path}");

      // Compress the image before showing preview
      try {
        file = await pickAndCompressImage(file!);
        debugPrint("Image compressed: ${file!.path}");
        await _showImagePreviewDialog(
            context, file!, onUploadSuccess, onUploadFailure);
      } catch (e) {
        debugPrint("Error compressing image: $e");
        onUploadFailure("Error compressing image: $e");
      }
    }
  }

  // Method to generate the signed URL
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

  // Upload file with callbacks
  Future<void> uploadFileToS3WithCallback(
    String signedUrl,
    String filePath,
    BuildContext context,
    Function(String) onUploadSuccess, // Success callback
    Function(String) onUploadFailure, // Failure callback
  ) async {
    try {
      final file = File(filePath);

      if (await file.exists()) {
        final fileBytes = await file.readAsBytes();

        final response = await http.put(
          Uri.parse(signedUrl),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': fileBytes.length.toString(),
          },
          body: fileBytes,
        );

        log("File uploaded response: ${response.body}");

        if (response.statusCode == 200) {
          onUploadSuccess(uploadedFileUrl); // Pass the filename to the callback
          // onUploadSuccess(_fileName);  // Pass the filename to the callback
        } else {
          onUploadFailure(
              'Failed to upload file: ${response.statusCode}'); // Call failure callback
        }
      } else {
        onUploadFailure(
            'File not found at the specified path'); // Failure callback
      }
    } catch (e) {
      onUploadFailure('Error uploading file: $e'); // Failure callback
    }
  }

  // URL for the uploaded image
  String getUrlForUserUploadedImage(String postFilePath) {
    if (postFilePath.startsWith("/")) {
      return AppConstant.baseUrlToUploadAndFetchUsersImage + postFilePath;
    }
    return "${AppConstant.baseUrlToUploadAndFetchUsersImage}/$postFilePath";
  }

  Future<void> _showImagePreviewDialog(
    BuildContext context,
    File imageFile,
    Function(String) onUploadSuccess, // Callback for success
    Function(String) onUploadFailure,
  ) async {
    bool loading = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame != null || wasSynchronouslyLoaded) {
                      return child;
                    }
                    return CircularProgressIndicator.adaptive();
                  },
                  height: 200,
                  width: 300,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.red),
              ),
            ),
            // Upload Button
            StatefulBuilder(builder: (_context, state) {
              return loading
                  ? Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator.adaptive())
                  : ElevatedButton(
                      style: const ButtonStyle(
                          // backgroundColor:  color1,
                          ),
                      onPressed: () async {
                        String _fileName =
                            'IMG_Profile_${DateTime.now().millisecondsSinceEpoch}${extension(imageFile.path)}';
                        try {
                          print("_fileName $_fileName");
                          if (_fileName.isNotEmpty) {
                            if (_fileName.isNotEmpty) {
                              state(() {
                                loading = true;
                              });
                              String? url = await getSignedUrl(
                                  _fileName, AppConstant.bundleNameForPostAPI);
                              if (url != null &&
                                  url.isNotEmpty &&
                                  file != null) {
                                uploadFileToS3WithCallback(url, file!.path,
                                    context, onUploadSuccess, onUploadFailure);
                                state(() {
                                  loading = false;
                                });
                                Navigator.maybePop(dialogContext);
                              }
                            }
                          }
                        } catch (e) {
                          state(() {
                            loading = false;
                          });
                          onUploadFailure("Error uploading image: $e");
                        }
                      },
                      child: Text(
                        "Upload",
                        style: TextStyle(color: Colors.black),
                      ),
                    );
            }),
          ],
        );
      },
    );
  }
}

class ImagePickerUtilForPst {
  String uploadedFileUrl = '';
  final ImagePicker _picker = ImagePicker();
  String _fileName = '';
  File? file;

  // Modify this method to accept callbacks for success and failure
  Future<void> _pickImageFromGallery(
    BuildContext context,
    Function(String) onUploadSuccess, // Callback for success
    Function(String) onUploadFailure, // Callback for failure
  ) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      file = File(image.path);

      // Generate a unique file name using current date and time
      String uniqueFileName =
          'IMG_Profile_${DateTime.now().millisecondsSinceEpoch}${extension(image.path)}';

      // Update the file name
      log("Original File Name: ${basename(image.path)}");

      _fileName = uniqueFileName;

      if (_fileName.isNotEmpty) {
        String? url =
            await getSignedUrl(_fileName, AppConstant.bundleNameForPostAPI);
        if (url != null && url.isNotEmpty && file != null) {
          uploadFileToS3WithCallback(
              url, file!.path, context, onUploadSuccess, onUploadFailure);
        }
      }
    }
  }

  /// Function to capture image using camera
  Future<void> _pickImageFromCamera(
    BuildContext context,
    Function(String) onUploadSuccess, // Callback for success
    Function(String) onUploadFailure, // Callback for failure
  ) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      file = File(image.path);

      // Generate a unique file name using current date and time
      String uniqueFileName =
          'IMG_Profile_${DateTime.now().millisecondsSinceEpoch}${extension(image.path)}';

      log("Original File Name: ${basename(image.path)}");
      log("Unique File Name: $uniqueFileName");

      _fileName = uniqueFileName;
      log('_fileName  ====> $_fileName');
      if (_fileName.isNotEmpty) {
        String? url =
            await getSignedUrl(_fileName, AppConstant.bundleNameForPostAPI);
        if (url != null && url.isNotEmpty && file != null) {
          uploadFileToS3WithCallback(
              url, file!.path, context, onUploadSuccess, onUploadFailure);
        }
      }
    }
  }

  void showImageSourceSelection(
    BuildContext context,
    Function(String) onUploadSuccess, // Pass callback for success
    Function(String) onUploadFailure, // Pass callback for failure
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  _pickImageFromGallery(context, onUploadSuccess,
                      onUploadFailure); // Pass callbacks
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  _pickImageFromCamera(context, onUploadSuccess,
                      onUploadFailure); // Pass callbacks
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to generate the signed URL
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

  // Upload file with callbacks
  Future<void> uploadFileToS3WithCallback(
    String signedUrl,
    String filePath,
    BuildContext context,
    Function(String) onUploadSuccess, // Success callback
    Function(String) onUploadFailure, // Failure callback
  ) async {
    try {
      final file = File(filePath);

      if (await file.exists()) {
        final fileBytes = await file.readAsBytes();

        final response = await http.put(
          Uri.parse(signedUrl),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': fileBytes.length.toString(),
          },
          body: fileBytes,
        );

        log("File uploaded response: ${response.body}");

        if (response.statusCode == 200) {
          log('File uploaded successfully!');
          onUploadSuccess(uploadedFileUrl); // Pass the filename to the callback
          // onUploadSuccess(_fileName);  // Pass the filename to the callback

          // onUploadSuccess(response.body); // Call success callback with response body
        } else {
          log('Failed to upload file: ${response.statusCode} : ${response.body}');
          onUploadFailure(
              'Failed to upload file: ${response.statusCode}'); // Call failure callback
        }
      } else {
        log('File not found at the specified path: $filePath');
        onUploadFailure(
            'File not found at the specified path'); // Failure callback
      }
    } catch (e) {
      log('Error uploading file: $e');
      onUploadFailure('Error uploading file: $e'); // Failure callback
    }
  }

  // URL for the uploaded image
  String getUrlForUserUploadedImage(String postFilePath) {
    if (postFilePath.startsWith("/")) {
      return AppConstant.baseUrlToUploadAndFetchUsersImage + postFilePath;
    }
    return "${AppConstant.baseUrlToUploadAndFetchUsersImage}/$postFilePath";
  }
}
