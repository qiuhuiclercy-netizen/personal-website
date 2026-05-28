import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'voice_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  String? _filePath;
  String? _fileName;

  static const _platforms = [
    {'emoji': '🎬', 'name': '本地视频'},
    {'emoji': '🎵', 'name': '抖音'},
    {'emoji': '📺', 'name': 'B站'},
    {'emoji': '▶️', 'name': 'YouTube'},
    {'emoji': '🟣', 'name': '腾讯视频'},
    {'emoji': '🎵', 'name': 'TikTok'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path!;
        _fileName = result.files.single.name;
      });
    }
  }

  void _next() {
    final isUrl = _tabController.index == 0;
    if (isUrl && _urlController.text.trim().isEmpty) {
      _snack('请输入视频链接');
      return;
    }
    if (!isUrl && _filePath == null) {
      _snack('请选择视频文件');
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => VoiceSelectScreen(
      isUrl: isUrl,
      url: isUrl ? _urlController.text.trim() : null,
      filePath: isUrl ? null : _filePath,
      fileName: _fileName,
    )));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: RichText(text: const TextSpan(
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          children: [
            TextSpan(text: '🎙️ VideoDub '),
            TextSpan(text: 'AI', style: TextStyle(color: Color(0xFF7C6AFF))),
          ],
        )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('英语视频 → 中文配音', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stepTitle('1', '选择视频来源'),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  tabs: const [Tab(text: '🔗 粘贴链接'), Tab(text: '📁 本地视频')],
                  indicatorColor: const Color(0xFF7C6AFF),
                  labelColor: const Color(0xFF7C6AFF),
                  unselectedLabelColor: Colors.grey,
                  dividerColor: Colors.transparent,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 110,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _urlInput(),
                      _filePicker(),
                    ],
                  ),
                ),
              ],
            )),
            const SizedBox(height: 16),
            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('支持的平台', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: _platforms.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(p['emoji']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(p['name']!, style: const TextStyle(fontSize: 12)),
                    ]),
                  );
                }).toList()),
              ],
            )),
            const SizedBox(height: 32),
            _nextButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _urlInput() {
    return Column(children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: _urlController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '粘贴视频链接...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final data = await Clipboard.getData('text/plain');
            if (data?.text != null) _urlController.text = data!.text!;
          },
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.content_paste, size: 18, color: Colors.grey),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      const Text(
        '提示：B站/YouTube 链接如下载失败，请改用本地上传',
        style: TextStyle(color: Colors.orange, fontSize: 11),
      ),
    ]);
  }

  Widget _filePicker() {
    if (_filePath == null) {
      return GestureDetector(
        onTap: _pickFile,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎬', style: TextStyle(fontSize: 28)),
              SizedBox(height: 8),
              Text('点击选择视频文件', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Text('🎞️', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(_fileName ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
        GestureDetector(
          onTap: () => setState(() { _filePath = null; _fileName = null; }),
          child: const Icon(Icons.close, color: Colors.grey, size: 18),
        ),
      ]),
    );
  }

  Widget _stepTitle(String step, String title) {
    return Row(children: [
      Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF7C6AFF), Color(0xFFFF6AAD)]),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    ]);
  }

  Widget _nextButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7C6AFF), Color(0xFFFF6AAD)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('下一步：选择配音声音', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}
