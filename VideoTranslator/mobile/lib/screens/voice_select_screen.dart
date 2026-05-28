import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import 'progress_screen.dart';

class VoiceSelectScreen extends StatefulWidget {
  final bool isUrl;
  final String? url;
  final String? filePath;
  final String? fileName;
  const VoiceSelectScreen({
    super.key,
    required this.isUrl,
    this.url,
    this.filePath,
    this.fileName,
  });

  @override
  State<VoiceSelectScreen> createState() => _VoiceSelectScreenState();
}

class _VoiceSelectScreenState extends State<VoiceSelectScreen> {
  Map<String, dynamic> _voices = {};
  bool _loading = true;
  String _selected = '播音员';
  String? _playingVoice;
  final AudioPlayer _player = AudioPlayer();

  static const _voiceEmojis = {
    '猫娘':   '🐱',
    '派大星': '⭐',
    '林黛玉': '🌸',
    '播音员': '📻',
    '男主播': '🎙️',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingVoice = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final voices = await ApiService.getVoices();
      voices.removeWhere((k, v) => k == '自定义角色');
      setState(() {
        _voices = voices;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _preview(String name) async {
    if (_playingVoice == name) {
      await _player.stop();
      setState(() => _playingVoice = null);
      return;
    }
    setState(() => _playingVoice = name);
    try {
      final url = ApiService.voicePreviewUrl(name);
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      if (!mounted) return;
      setState(() => _playingVoice = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('试听失败: $e')),
      );
    }
  }

  void _start() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressScreen(
      isUrl: widget.isUrl,
      url: widget.url,
      filePath: widget.filePath,
      character: _selected,
      ttsProvider: 'xunfei',
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择配音声音', style: TextStyle(fontSize: 17)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(children: [
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C6AFF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7C6AFF).withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.headphones, color: Color(0xFF7C6AFF), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      widget.isUrl ? '已选链接' : '已选文件：${widget.fileName ?? ""}',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ]),
                ),
                const SizedBox(height: 24),
                const Text('🎭 选择配音角色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('点击 ▶ 试听声音，点击卡片选择', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                ..._voices.entries.map((e) => _voiceCard(e.key, e.value)),
              ]),
            )),
            _startButton(),
          ]),
    );
  }

  Widget _voiceCard(String name, dynamic info) {
    final isSelected = name == _selected;
    final isPlaying = _playingVoice == name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selected = name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
              ? const LinearGradient(colors: [Color(0x337C6AFF), Color(0x33FF6AAD)])
              : null,
            color: isSelected ? null : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF7C6AFF) : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(_voiceEmojis[name] ?? '🎤', style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  if (isSelected) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C6AFF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('已选', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(info['desc'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )),
            GestureDetector(
              onTap: () => _preview(name),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isPlaying ? const Color(0xFFFF6AAD) : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _startButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C6AFF), Color(0xFFFF6AAD)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, color: Colors.white),
                  SizedBox(width: 8),
                  Text('开始翻译配音', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
