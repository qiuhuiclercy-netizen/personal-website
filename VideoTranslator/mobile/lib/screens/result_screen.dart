import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final String jobId;
  const ResultScreen({super.key, required this.jobId});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _downloading = false;
  double _dlProgress = 0;
  String? _savedPath;

  Future<void> _download() async {
    setState(() { _downloading = true; _dlProgress = 0; });
    try {
      final downloadUrl = await ApiService.getDownloadUrl(widget.jobId);
      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final path = '${dir.path}/dubbed_${widget.jobId}.mp4';

      await Dio().download(
        downloadUrl,
        path,
        onReceiveProgress: (recv, total) {
          if (total > 0) setState(() => _dlProgress = recv / total);
        },
      );

      setState(() { _downloading = false; _savedPath = path; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已保存到：$path'), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      setState(() { _downloading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('配音完成')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72))
              .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text('配音完成！',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700))
              .animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            const Text('视频已成功翻译为中文配音',
              style: TextStyle(color: Colors.grey, fontSize: 15))
              .animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 48),
            if (_downloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _dlProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF7C6AFF)),
                ),
              ),
              const SizedBox(height: 12),
              Text('下载中 ${(_dlProgress * 100).toInt()}%',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C6AFF), Color(0xFFFF6AAD)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: _savedPath != null ? null : _download,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _savedPath != null ? '✅ 已保存到相册' : '⬇️ 下载视频到手机',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('再翻译一个', style: TextStyle(color: Colors.white70)),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ],
        ),
      ),
    );
  }
}
