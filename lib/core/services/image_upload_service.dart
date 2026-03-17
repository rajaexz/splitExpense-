import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import '../config/image_upload_config.dart';

/// Uploads images to ImgBB (free, no Firebase Storage needed)
abstract class ImageUploadService {
  Future<String> uploadImage(File file);
}

class ImgBBImageUploadService implements ImageUploadService {
  final Dio _dio = Dio();
  static const _uploadUrl = 'https://api.imgbb.com/1/upload';

  @override
  Future<String> uploadImage(File file) async {
    if (!ImageUploadConfig.isConfigured) {
      throw Exception(
        'ImgBB API key not set. Get free key at https://api.imgbb.com/ '
        'Then add it in lib/core/config/imgbb_key.dart',
      );
    }

    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);

    final formData = FormData.fromMap({
      'key': ImageUploadConfig.imgbbApiKey,
      'image': base64,
    });

    final response = await _dio.post(
      _uploadUrl,
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['success'] != true) {
      final error = data?['error']?['message'] ?? response.statusMessage ?? 'Upload failed';
      throw Exception('Image upload failed: $error');
    }

    final imageData = data['data'] as Map<String, dynamic>?;
    final url = (imageData?['url'] ?? imageData?['display_url'])?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('No URL in upload response');
    }

    return url;
  }
}
