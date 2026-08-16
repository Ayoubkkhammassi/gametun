import 'dart:io';
import 'package:dio/dio.dart';
import '../config/env.dart';

/// Upload de médias (photos, vocaux) vers Cloudinary (upload non signé).
/// Renvoie l'URL publique ; la base de données ne stocke que ce lien.
class Cloudinary {
  final Dio _dio = Dio();

  /// resourceType : 'image' pour les photos, 'video' pour l'audio (m4a).
  Future<String?> upload(File file, {String resourceType = 'image'}) async {
    final url =
        'https://api.cloudinary.com/v1_1/${Env.cloudinaryCloudName}/$resourceType/upload';
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'upload_preset': Env.cloudinaryUploadPreset,
    });
    final res = await _dio.post(url, data: form);
    final data = res.data;
    if (data is Map && data['secure_url'] != null) {
      return data['secure_url'] as String;
    }
    return null;
  }
}
