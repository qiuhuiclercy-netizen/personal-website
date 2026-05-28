import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../widgets/voice_card.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

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
  String _selectedCharacter = '播音员';
  String _ttsProvider = 'xunfei';  // 默认讯飞TTS（火山方舟TTS需另行配置）
  Map<String, dynamic> _voices = {};
  bool _loadingVoices = true;

  static const _voiceEmojis = {
    '猫娘': '🐱',
    '派大星': '⭐',
    '林黛玉': '🌸',
    '播音员': '📻',
    '男主播': '🎙️',
    '活泼小姐姐': '✨',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await ApiService.getVoices();
      setState(() { _voices = voices; _loadingVoices = false; });
    } catch (e) {
      setState(() { _loadingVoices = false; });
    }
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

  Future<void> _start() async {
    final isUrl = _tabController.index == 0;
    if (isUrl && _urlController.text.trim().isEmpty) {
      _snack('请输入视频链接');
      return;
    }
    if (!isUrl && _filePath == null) {
      _snack('请选择视频文件');
      return;
    }

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressScreen(
      isUrl: isUrl,
      url: isUrl ? _urlController.text.trim() : null,
      filePath: isUrl ? null : _filePath,
      character: _selectedCharacter,
      ttsProvider: _ttsProvider,
    )));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          const Text('🎙️ ', style: TextStyle(fontSize: 22)),
          RichText(text: TextSpan(
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            children: [
              const TextSpan(text: 'VideoDub '),
              TextSpan(
                text: 'AI',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFF7C6AFF), Color(0xFFFF6AAD)],
                    ).createShader(const Rect.fromLTWH(0, 0, 60, 20)),
                ),
              ),
            ],
          )),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(theme),
            const SizedBox(height: 16),
            _buildVoiceCard(theme),
            const SizedBox(height: 16),
            _buildTtsProviderCard(theme),
            const SizedBox(height: 24),
            _buildStartButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(ThemeData theme) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('1', '选择视频来源'),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: '🔗 粘贴链接'), Tab(text: '📁 本地视频')],
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            dividerColor: Colors.transparent,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: TabBarView(
              controller: _tabController,
              children: [
                // URL tab
                Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '暂时仅支持上传本地视频文件...',
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
                      _IconBtn(Icons.content_paste, () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) _urlController.text = data!.text!;
                      }),
                    ]),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('⚠️ 平台限制：请先保存视频到手机，再用「本地视频」上传', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                  ],
                ),
                // File tab
                _filePath == null
                  ? GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, style: BorderStyle.solid),
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
                    )
                  : Container(
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
                    ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildVoiceCard(ThemeData theme) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('2', '选择配音角色'),
          const SizedBox(height: 16),
          _loadingVoices
            ? const Center(child: CircularProgressIndicator())
            : _voices.isEmpty
              ? const Text('无法加载角色列表，请检查服务器连接', style: TextStyle(color: Colors.grey))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _voices.length,
                  itemBuilder: (_, i) {
                    final name = _voices.keys.elementAt(i);
                    final info = _voices[name] as Map;
                    return VoiceCard(
                      name: name,
                      emoji: _voiceEmojis[name] ?? '🎤',
                      desc: info['desc'] ?? '',
                      isSelected: name == _selectedCharacter,
                      onTap: () => setState(() => _selectedCharacter = name),
                    );
                  },
                ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTtsProviderCard(ThemeData theme) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TTS 引擎', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          Row(children: [
            _RadioOption('xunfei', '⚡ 讯飞 TTS（推荐）', _ttsProvider, (v) => setState(() => _ttsProvider = v!)),
            const SizedBox(width: 20),
            _RadioOption('volcengine', '🌋 火山方舟', _ttsProvider, (v) => setState(() => _ttsProvider = v!)),
          ]),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C6AFF), Color(0xFFFF6AAD)],
          ),
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
              Text('⚡', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('开始翻译配音', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

// ─── Helpers ──────────────────────────────────────────────────

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

class _SectionTitle extends StatelessWidget {
  final String step;
  final String title;
  const _SectionTitle(this.step, this.title);
  @override
  Widget build(BuildContext context) {
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
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 20, color: Colors.grey[300]),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String value;
  final String label;
  final String groupValue;
  final ValueChanged<String?> onChanged;
  const _RadioOption(this.value, this.label, this.groupValue, this.onChanged);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(children: [
        Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged, activeColor: const Color(0xFF7C6AFF)),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}
