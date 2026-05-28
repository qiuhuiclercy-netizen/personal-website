import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class ProgressScreen extends StatefulWidget {
  final bool isUrl;
  final String? url;
  final String? filePath;
  final String character;
  final String ttsProvider;

  const ProgressScreen({
    super.key,
    required this.isUrl,
    this.url,
    this.filePath,
    required this.character,
    required this.ttsProvider,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _status = '提交任务...';
  double _progress = 0.05;
  bool _failed = false;
  String? _errorMsg;
  String? _jobId;
  StreamSubscription<Map<String, dynamic>>? _pollSub;

  static const _steps = [
    {'id': 'download',  'label': '📥 下载/接收视频',   'keywords': ['下载', '接收', 'upload', '上传']},
    {'id': 'asr',       'label': '🎤 语音识别',        'keywords': ['语音识别', 'Whisper', '提取音频']},
    {'id': 'translate', 'label': '🌐 DeepSeek 翻译',   'keywords': ['翻译', 'DeepSeek']},
    {'id': 'tts',       'label': '🎭 角色配音合成',    'keywords': ['配音', 'TTS', '合成']},
    {'id': 'merge',     'label': '🎬 合并输出',        'keywords': ['合并', '输出', '完成']},
  ];

  int _activeStep = -1;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _pollSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      String jobId;
      if (widget.isUrl) {
        jobId = await ApiService.translateUrl(
          url: widget.url!,
          character: widget.character,
          ttsProvider: widget.ttsProvider,
        );
      } else {
        jobId = await ApiService.translateFile(
          filePath: widget.filePath!,
          character: widget.character,
          ttsProvider: widget.ttsProvider,
          onProgress: (p) => setState(() => _progress = p * 0.15),
        );
      }
      _jobId = jobId;
      _poll(jobId);
    } catch (e) {
      setState(() { _failed = true; _errorMsg = e.toString(); });
    }
  }

  void _poll(String jobId) {
    _pollSub = ApiService.pollJob(jobId).listen(
      (job) {
        if (!mounted) return;
        final msg = (job['progress'] ?? '') as String;
        setState(() {
          _status = msg;
          _activeStep = _detectStep(msg);
          _progress = _activeStep >= 0
              ? 0.15 + ((_activeStep + 1) / _steps.length) * 0.80
              : 0.15;
        });
        if (job['status'] == 'done') {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => ResultScreen(jobId: jobId),
          ));
        } else if (job['status'] == 'error') {
          setState(() { _failed = true; _errorMsg = job['error'] ?? '未知错误'; });
        }
      },
      onError: (e) => setState(() { _failed = true; _errorMsg = e.toString(); }),
    );
  }

  int _detectStep(String msg) {
    for (int i = 0; i < _steps.length; i++) {
      final keywords = _steps[i]['keywords'] as List<String>;
      if (keywords.any((k) => msg.contains(k))) return i;
    }
    return _activeStep;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('处理中...'),
        leading: _failed
          ? BackButton(onPressed: () => Navigator.pop(context))
          : const SizedBox(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_failed) ..._buildError()
            else ...[
              _buildProgressBar(),
              const SizedBox(height: 28),
              ..._buildSteps(),
              const SizedBox(height: 24),
              Center(child: Text(_status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14))),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${(_progress * 100).toInt()}%',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF7C6AFF)),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  List<Widget> _buildSteps() {
    return _steps.asMap().entries.map((e) {
      final i = e.key;
      final step = e.value;
      final isDone = i < _activeStep;
      final isActive = i == _activeStep;

      Color color = Colors.grey;
      if (isDone) color = Colors.greenAccent;
      if (isActive) color = const Color(0xFF7C6AFF);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(
            width: 3,
            height: 32,
            color: color,
            margin: const EdgeInsets.only(right: 12),
          ),
          Text(
            '${step['label']}${isDone ? ' ✓' : ''}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
          ],
        ]),
      );
    }).toList();
  }

  List<Widget> _buildError() {
    return [
      const Center(child: Text('❌', style: TextStyle(fontSize: 60))),
      const SizedBox(height: 20),
      const Center(child: Text('处理失败', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
      const SizedBox(height: 12),
      Center(
        child: Text(_errorMsg ?? '未知错误',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
      ),
    ];
  }
}
