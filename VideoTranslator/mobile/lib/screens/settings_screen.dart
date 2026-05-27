import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    ApiService.getBaseUrl().then((url) => _urlController.text = url);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ApiService.setBaseUrl(_urlController.text.trim());
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  Future<void> _test() async {
    try {
      final voices = await ApiService.getVoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接成功！已加载 ${voices.length} 个角色声音 ✅'),
            backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('服务器地址', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('填入运行 VideoDub 后端的电脑 IP 地址', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'http://192.168.1.100:8000',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                prefixIcon: const Icon(Icons.dns_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _test,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.08),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('测试连接'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved ? Colors.green : const Color(0xFF7C6AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_saved ? '✅ 已保存' : '保存'),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            const Text('使用说明', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            ..._tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t[0], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(child: Text(t[1], style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5))),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  static const _tips = [
    ['1️⃣', '在电脑上运行 VideoDub 后端服务（双击 start.bat）'],
    ['2️⃣', '手机和电脑连接同一个 WiFi'],
    ['3️⃣', '在设置页填入电脑的局域网 IP（如 192.168.1.100:8000）'],
    ['4️⃣', '点击"测试连接"确认可以访问'],
    ['5️⃣', '回到主页，粘贴视频链接或上传本地视频，选择角色开始翻译'],
  ];
}
