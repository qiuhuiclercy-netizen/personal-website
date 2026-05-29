# VideoDub AI - 安装与使用指南

## 项目结构

```
VideoTranslator/
├── backend/          ← Python FastAPI 后端（语音识别+翻译+配音）
├── frontend/         ← Web 前端（HTML/CSS/JS）
├── mobile/           ← Flutter 移动端 APP (Android + iOS)
└── start.bat         ← Windows 一键启动脚本
```

---

## 第一步：填入 API Key

编辑 `backend/.env` 文件：

```env
# 火山方舟 TTS（必填，用于角色配音）
# 控制台：https://console.volcengine.com/speech/app
VOLC_APP_ID=你的AppID
VOLC_ACCESS_TOKEN=你的AccessToken

# DeepSeek 翻译（必填）
DEEPSEEK_API_KEY=你的Key
```

---

## 第二步：启动 Web 服务

双击 `start.bat`，浏览器会自动打开 http://localhost:8000

或手动运行：
```
cd backend
D:\Users\26354\miniconda3\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000
```

---

## 第三步：使用 Web 端

1. 粘贴 YouTube/抖音链接，或上传本地视频
2. 选择配音角色（猫娘/派大星/林黛玉等）
3. 点击"开始翻译配音"
4. 等待处理完成后下载视频

---

## 第四步：构建移动端 APP

### 安装 Flutter（一次性操作）

```powershell
# 方式一：下载安装包（推荐）
# 访问 https://docs.flutter.dev/get-started/install/windows
# 下载 flutter_windows_xxx.zip，解压到 C:\flutter
# 添加 C:\flutter\bin 到 PATH 环境变量

# 验证安装
flutter doctor
```

### 创建并运行 Flutter 项目

```powershell
cd mobile

# 首次：用 flutter create 生成完整项目结构，然后覆盖 lib/ 目录
flutter create . --project-name video_dubber
flutter pub get

# 连接 Android 手机（开启开发者模式+USB调试）
flutter run

# 构建 Android APK
flutter build apk --release
# APK 在：build/app/outputs/flutter-apk/app-release.apk

# 构建 iOS（需要 macOS + Xcode）
flutter build ios --release
```

### 手机配置服务器地址

1. 打开 APP → 右上角设置
2. 填入电脑局域网 IP，如 `http://192.168.1.100:8000`
3. 点击"测试连接"确认

---

## 角色声音 ID（火山方舟）

| 角色 | voice_type | 说明 |
|------|-----------|------|
| 猫娘 | BV701_streaming | 萌系女声 |
| 派大星 | BV056_streaming | 憨厚男声 |
| 林黛玉 | BV007_streaming | 温婉女声 |
| 播音员 | BV001_streaming | 标准女声 |
| 男主播 | BV002_streaming | 标准男声 |
| 活泼小姐姐 | BV700_streaming | 灿灿 |

如需更换声音，在 `backend/config.py` 中修改 `VOICE_CHARACTERS` 字典中的 `volc_voice` 值。

---

## 处理流程

```
视频链接/文件
    ↓
yt-dlp 下载（YouTube/抖音）
    ↓
FFmpeg 提取音频
    ↓
Whisper base 语音识别（英→英文字幕+时间戳）
    ↓
DeepSeek API 翻译（英→中，批量翻译）
    ↓
火山方舟 TTS 合成（每段字幕→角色配音）
    ↓
FFmpeg 混音+时间对齐（adelay+amix）
    ↓
FFmpeg 合并回视频（保留原视频画面）
    ↓
输出 MP4 文件
```

---

## 常见问题

**Q: Whisper 第一次运行很慢？**  
A: 首次运行会下载模型文件（约 150MB），之后缓存在本地。

**Q: 火山方舟 TTS 报错？**  
A: 检查 `.env` 中 `VOLC_APP_ID` 和 `VOLC_ACCESS_TOKEN` 是否正确。  
控制台地址：https://console.volcengine.com/speech/app

**Q: 配音和画面不同步？**  
A: 系统会自动调速（±30%范围），如果超出则允许轻微偏移。  
可在 `config.py` 中调整各角色的 `speed` 参数。

**Q: 想提高识别精度？**  
A: 在 `.env` 中把 `WHISPER_MODEL=base` 改为 `WHISPER_MODEL=medium`（更准但更慢）。
