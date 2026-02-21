import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:image_picker/image_picker.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

Future<User?> loadUserData(int userId) async {
  try {
    final res = await ApiClient.dio.get('/user/$userId');

    final data = res.data; // Map<String, dynamic>
    final curUser = User.fromJson(data);

    return curUser;
  } catch (error) {
    print("Error loading user data: $error");
    return null; // Return null in case of an error
  }
}

String getFlagEmoji(String countryCode) {
  countryCode = countryCode.toUpperCase();
  // String countryName = Countries.byCode(countryCode).name ?? 'Unknown';
  String flagEmoji =
      countryCode.codeUnits.map((e) => String.fromCharCode(e + 127397)).join();
  return flagEmoji;
}

Future<List<OpinionSummary>> fetchOpinions(int userId2) async {
  // FirebaseFirestore firestore = FirebaseFirestore.instance;

  final res = await ApiClient.dio.get("/matchOpinions/$userId2");

  var opinion1 = res.data[0];
  var opinion2 = res.data[1];

  return [OpinionSummary.fromJson(opinion1), OpinionSummary.fromJson(opinion2)];
}

Future<String> uploadProfileImage(XFile imageFile) async {
  try {
    final String extension = p.extension(imageFile.path).toLowerCase();

    // 2. Map extension to the exact MIME string your Go backend expects
    String contentType;
    switch (extension) {
      case '.png':
        contentType = 'image/png';
        break;
      case '.webp':
        contentType = 'image/webp';
        break;
      case '.heic':
        contentType = 'image/heic'; // Common on iPhones
        break;
      case '.jpg':
      case '.jpeg':
      default:
        contentType = 'image/jpeg';
        break;
    }

    final fileBytes = await maybeCompressImage(imageFile);

    // --- STEP 1: GET THE PRESIGNED URL FROM GO ---
    // We tell Go we want a profile image and its content type
    final presignResponse = await ApiClient.dio.get(
      '/images/presigned',
      queryParameters: {
        'type': 'profile',
        'contentType': contentType, // Ensure this matches your Go switch case
      },
    );

    final String uploadUrl = presignResponse.data['url'];
    final String s3Key = presignResponse.data['key'];

    // --- STEP 2: UPLOAD DIRECTLY TO S3 ---
    // IMPORTANT: Use a clean Dio instance or reset headers.
    // S3 will REJECT the request if you send your Backend's Auth Token to it.
    try {
      await Dio().put(
        uploadUrl,
        data: Stream.fromIterable(
          fileBytes.map((e) => [e]),
        ), // Efficient streaming
        options: Options(
          contentType: contentType, // MUST match Step 1
          headers: {'Content-Length': fileBytes.length},
        ),
      );

      // --- STEP 3: CONFIRM UPLOAD TO YOUR BACKEND ---
      // Now tell your Go server: "The file is in S3, here is the key to save in DB"
      final response = await ApiClient.dio.post(
        '/images',
        data: {'s3_key': s3Key},
        queryParameters: {'type': 'profile'},
      );
      return response.data['url'];
    } on DioException catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  } catch (error) {
    throw Exception('Failed to upload profile image: $error');
  }
}

Future<String> uploadSupportImage(XFile imageFile) async {
  try {
    final String extension = p.extension(imageFile.path).toLowerCase();

    // 2. Map extension to the exact MIME string your Go backend expects
    String contentType;
    switch (extension) {
      case '.png':
        contentType = 'image/png';
        break;
      case '.webp':
        contentType = 'image/webp';
        break;
      case '.heic':
        contentType = 'image/heic'; // Common on iPhones
        break;
      case '.jpg':
      case '.jpeg':
      default:
        contentType = 'image/jpeg';
        break;
    }

    final fileBytes = await maybeCompressImage(imageFile);

    // --- STEP 1: GET THE PRESIGNED URL FROM GO ---
    // We tell Go we want a profile image and its content type
    final presignResponse = await ApiClient.dio.get(
      '/images/presigned',
      queryParameters: {
        'type': 'gallery',
        'contentType': contentType, // Ensure this matches your Go switch case
      },
    );

    final String uploadUrl = presignResponse.data['url'];
    final String s3Key = presignResponse.data['key'];
    // --- STEP 2: UPLOAD DIRECTLY TO S3 ---
    // IMPORTANT: Use a clean Dio instance or reset headers.
    // S3 will REJECT the request if you send your Backend's Auth Token to it.

    await Dio().put(
      uploadUrl,
      data: Stream.fromIterable(
        fileBytes.map((e) => [e]),
      ), // Efficient streaming
      options: Options(
        contentType: contentType, // MUST match Step 1
        headers: {'Content-Length': fileBytes.length},
      ),
    );

    // --- STEP 3: CONFIRM UPLOAD TO YOUR BACKEND ---
    // Now tell your Go server: "The file is in S3, here is the key to save in DB"
    final response = await ApiClient.dio.post(
      '/images',
      data: {'s3_key': s3Key},
      queryParameters: {'type': 'gallery'},
    );
    return response.data['url'];
  } on DioException catch (e) {
    // Read backend error JSON
    final errorMsg = e.response?.data['error'] ?? e.message;
    print('Error: $errorMsg');

    throw Exception('Failed to upload support image: $errorMsg');
  } on Exception catch (e) {
    throw Exception('Failed to upload support image: $e');
  }
}

int calculateAge(DateTime birthday) {
  final today = DateTime.now().toUtc();
  int age = today.year - birthday.year;

  // Adjust if birthday hasn't occurred yet this year
  if (today.month < birthday.month ||
      (today.month == birthday.month && today.day < birthday.day)) {
    age--;
  }

  return age;
}

Future<Uint8List> maybeCompressImage(
  XFile imageFile, {
  int maxFileSize = 500 * 1024, // 500 KB
  int maxWidth = 1024,
  int quality = 70,
}) async {
  // 1️⃣ Get the file size
  final int fileSize = await imageFile.length();

  if (fileSize <= maxFileSize) {
    // Already small enough, no need to compress
    return await imageFile.readAsBytes();
  }

  // 2️⃣ Decide compression format
  final String extension = p.extension(imageFile.path).toLowerCase();
  CompressFormat format;
  switch (extension) {
    case '.png':
      format = CompressFormat.png;
      break;
    case '.webp':
      format = CompressFormat.webp;
      break;
    case '.heic':
      format = CompressFormat.jpeg; // Convert HEIC to JPEG
      break;
    case '.jpg':
    case '.jpeg':
    default:
      format = CompressFormat.jpeg;
      break;
  }

  // 3️⃣ Compress using flutter_image_compress
  Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
    imageFile.path,
    minWidth: maxWidth,
    quality: quality,
    format: format,
  );

  if (compressedBytes == null) {
    throw Exception("Failed to compress image");
  }

  return compressedBytes;
}

Future<String> getDeviceId() async {
  print("Getting device ID");
  final prefs = await SharedPreferences.getInstance();

  // Check if we already have a device ID
  String? deviceId = prefs.getString('device_id');
  if (deviceId != null) {
    print("Already have device ID: $deviceId");
    return deviceId;
  }

  // Generate a new UUID
  deviceId = const Uuid().v4();

  await prefs.setString('device_id', deviceId);
  print("compelted getting device ID");
  return deviceId;
}
