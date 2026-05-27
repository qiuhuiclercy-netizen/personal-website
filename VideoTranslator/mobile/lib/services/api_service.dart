import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _defaultBaseUrl = 'http://192.168.1.100:8000';
  static const _prefKey = 'server_url';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? _defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, url.trimRight().replaceAll(RegExp(r'/$'), ''));
  }

  static Future<Map<String, dynamic>> getVoices() async {
    final base = await getBaseUrl();
    final dio = Dio();
    final res = await dio.get('$base/api/voices');
    return Map<String, dynamic>.from(res.data);
  }

  static Future<String> translateUrl({
    required String url,
    required String character,
    required String ttsProvider,
  }) async {
    final base = await getBaseUrl();
    final dio = Dio();
    final res = await dio.post(
      '$base/api/translate/url',
      data: {
        'url': url,
        'character': character,
        'tts_provider': ttsProvider,
      },
    );
    return res.data['job_id'] as String;
  }

  static Future<String> translateFile({
    required String filePath,
    required String character,
    required String ttsProvider,
    void Function(double)? onProgress,
  }) async {
    final base = await getBaseUrl();
    final dio = Dio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'character': character,
      'tts_provider': ttsProvider,
    });
    final res = await dio.post(
      '$base/api/translate/file',
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0 && onProgress != null) {
          onProgress(sent / total);
        }
      },
    );
    return res.data['job_id'] as String;
  }

  static Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final base = await getBaseUrl();
    final dio = Dio();
    final res = await dio.get('$base/api/job/$jobId');
    return Map<String, dynamic>.from(res.data);
  }

  static String downloadUrl(String jobId) =>
      throw UnimplementedError(); // resolved at runtime

  static Future<String> getDownloadUrl(String jobId) async {
    final base = await getBaseUrl();
    return '$base/api/download/$jobId';
  }

  /// Poll job until done or error. Calls [onProgress] with status string.
  static Stream<Map<String, dynamic>> pollJob(String jobId) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      final job = await getJobStatus(jobId);
      yield job;
      if (job['status'] == 'done' || job['status'] == 'error') break;
    }
  }
}
