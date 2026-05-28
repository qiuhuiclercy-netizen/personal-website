import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ 云端地址
  static const _defaultBaseUrl = 'http://121.41.16.66:8000';
  static const _prefKey = 'server_url';

  /// 从 DioException 中提取服务器返回的中文错误信息
  static String _extractError(dynamic e) {
    if (e is DioException) {
      // 优先读 {"detail": "..."} 字段
      try {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          return data['detail'].toString();
        }
        if (data is String && data.isNotEmpty) return data;
      } catch (_) {}
      // 网络层错误
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return '连接超时，请检查网络或稍后重试';
      }
      if (e.type == DioExceptionType.connectionError) {
        return '无法连接服务器，请检查网络';
      }
      final code = e.response?.statusCode;
      if (code == 429) return '服务器繁忙，请稍后重试';
      if (code == 413) return '文件太大，请压缩后再上传';
    }
    return e.toString();
  }

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
    try {
      final res = await Dio().post(
        '$base/api/translate/url',
        data: {'url': url, 'character': character, 'tts_provider': ttsProvider},
        options: Options(receiveDataWhenStatusError: true),
      );
      return res.data['job_id'] as String;
    } catch (e) {
      throw Exception(_extractError(e));
    }
  }

  static Future<String> translateFile({
    required String filePath,
    required String character,
    required String ttsProvider,
    void Function(double)? onProgress,
  }) async {
    final base = await getBaseUrl();
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'character': character,
        'tts_provider': ttsProvider,
      });
      final res = await Dio().post(
        '$base/api/translate/file',
        data: formData,
        options: Options(receiveDataWhenStatusError: true),
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) onProgress(sent / total);
        },
      );
      return res.data['job_id'] as String;
    } catch (e) {
      throw Exception(_extractError(e));
    }
  }

  static Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final base = await getBaseUrl();
    final dio = Dio();
    final res = await dio.get('$base/api/job/$jobId');
    return Map<String, dynamic>.from(res.data);
  }

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
