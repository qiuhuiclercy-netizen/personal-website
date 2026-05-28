import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
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
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final url = await ApiService.getDownloadUrl(widget.jobId);
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      _videoController!.setLooping(false);
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() { _downloading = true; _dlProgress = 0; });
    try {
      final downloadUrl = await ApiService.getDownloadUrl(widget.jobId);
      Directory saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!saveDir.existsSync()) {
          saveDir = (await getExternalStorageDirectory()) ?? await getApplicationDocumentsDirectory();
        }
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }
      final path = '${saveDir.path}/配音视频_${widget.jobId}.mp4';
      await Dio().download(
        downloadUrl, path,
        onReceiveProgress: (recv, total) {
          if (total > 0) setState(() => _dlProgress = recv / total);
        },
      );
      setState(() { _downloading = false; _savedPath = path; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已保存：${path.split('/').last}'), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      setState(() => _downloading = false);
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
      appBar: AppBar(
        title: const Text('配音完成 🎉'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // 视频播放器
              AspectRatio(
                aspectRatio: _videoController?.value.aspectRatio ?? 16/9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _videoReady
                    ? Stack(alignment: Alignment.center, children: [
                        VideoPlayer(_videoController!),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: AnimatedOpacity(
                              opacity: _videoController!.value.isPlaying ? 0 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, size: 40, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ])
                    : Container(
                        color: Colors.black,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                ),
              ),
              if (_videoReady) VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF7C6AFF),
                  bufferedColor: Color(0x447C6AFF),
                  backgroundColor: Color(0x22FFFFFF),
                ),
              ),
              const SizedBox(height: 20),
              const Text('✅ 配音完成', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('视频已成功翻译为中文配音', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ]),
          )),
          // 底部操作按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(children: [
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
                const SizedBox(height: 8),
                Text('下载中 ${(_dlProgress * 100).toInt()}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ] else SizedBox(
                width: double.infinity, height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C6AFF), Color(0xFFFF6AAD)]),
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
                      _savedPath != null ? '✅ 已保存到下载' : '⬇️  下载视频到手机',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('再翻译一个', style: TextStyle(color: Colors.white70)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
