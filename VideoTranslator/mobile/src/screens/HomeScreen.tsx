import React, {useState} from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
} from 'react-native';
import * as DocumentPicker from 'expo-document-picker';
import * as Clipboard from 'expo-clipboard';
import type {NativeStackScreenProps} from '@react-navigation/native-stack';
import type {RootStackParamList} from '../../App';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

const PLATFORMS = [
  {emoji: '🎬', name: '本地视频'},
  {emoji: '🎵', name: '抖音'},
  {emoji: '📺', name: 'B站'},
  {emoji: '▶️', name: 'YouTube'},
  {emoji: '🟣', name: '腾讯视频'},
  {emoji: '🎵', name: 'TikTok'},
];

export default function HomeScreen({navigation}: Props) {
  const [tab, setTab] = useState<'url' | 'file'>('url');
  const [url, setUrl] = useState('');
  const [filePath, setFilePath] = useState<string | null>(null);
  const [fileName, setFileName] = useState<string | null>(null);
  const [mimeType, setMimeType] = useState<string>('video/mp4');

  const pickFile = async () => {
    try {
      const res = await DocumentPicker.getDocumentAsync({
        type: 'video/*',
        copyToCacheDirectory: true,
        multiple: false,
      });
      if (res.canceled || !res.assets || res.assets.length === 0) return;
      const a = res.assets[0];
      setFilePath(a.uri);
      setFileName(a.name);
      setMimeType(a.mimeType || 'video/mp4');
    } catch (e) {
      Alert.alert('选择失败', String(e));
    }
  };

  const onPaste = async () => {
    const text = await Clipboard.getStringAsync();
    if (text) setUrl(text);
  };

  const onNext = () => {
    if (tab === 'url' && !url.trim()) {
      Alert.alert('提示', '请输入视频链接');
      return;
    }
    if (tab === 'file' && !filePath) {
      Alert.alert('提示', '请选择视频文件');
      return;
    }
    navigation.navigate('VoiceSelect', {
      isUrl: tab === 'url',
      url: tab === 'url' ? url.trim() : undefined,
      filePath: tab === 'file' ? filePath ?? undefined : undefined,
      fileName: tab === 'file' ? fileName ?? undefined : undefined,
      mimeType: tab === 'file' ? mimeType : undefined,
    });
  };

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.subtitle}>英语视频 → 中文配音</Text>

      <View style={styles.card}>
        <View style={styles.stepRow}>
          <View style={styles.stepBadge}>
            <Text style={styles.stepBadgeText}>1</Text>
          </View>
          <Text style={styles.stepTitle}>选择视频来源</Text>
        </View>

        <View style={styles.tabRow}>
          <TouchableOpacity
            style={[styles.tab, tab === 'url' && styles.tabActive]}
            onPress={() => setTab('url')}>
            <Text style={[styles.tabText, tab === 'url' && styles.tabTextActive]}>
              🔗 粘贴链接
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.tab, tab === 'file' && styles.tabActive]}
            onPress={() => setTab('file')}>
            <Text style={[styles.tabText, tab === 'file' && styles.tabTextActive]}>
              📁 本地视频
            </Text>
          </TouchableOpacity>
        </View>

        {tab === 'url' ? (
          <View>
            <View style={styles.urlInputRow}>
              <TextInput
                style={styles.input}
                placeholder="粘贴视频链接..."
                placeholderTextColor="#888"
                value={url}
                onChangeText={setUrl}
                autoCapitalize="none"
              />
              <TouchableOpacity style={styles.iconBtn} onPress={onPaste}>
                <Text style={{fontSize: 16}}>📋</Text>
              </TouchableOpacity>
            </View>
            <Text style={styles.warnText}>
              提示：B站/YouTube 链接如下载失败，请改用本地上传
            </Text>
          </View>
        ) : !filePath ? (
          <TouchableOpacity style={styles.dropZone} onPress={pickFile}>
            <Text style={styles.dropZoneIcon}>🎬</Text>
            <Text style={styles.dropZoneText}>点击选择视频文件</Text>
          </TouchableOpacity>
        ) : (
          <View style={styles.filePreview}>
            <Text style={{fontSize: 20}}>🎞️</Text>
            <Text style={styles.fileName} numberOfLines={1}>
              {fileName}
            </Text>
            <TouchableOpacity
              onPress={() => {
                setFilePath(null);
                setFileName(null);
              }}>
              <Text style={{color: '#888', fontSize: 18}}>✕</Text>
            </TouchableOpacity>
          </View>
        )}
      </View>

      <View style={styles.card}>
        <Text style={styles.platformsTitle}>支持的平台</Text>
        <View style={styles.platformsWrap}>
          {PLATFORMS.map(p => (
            <View key={p.name} style={styles.platformChip}>
              <Text style={{fontSize: 14}}>{p.emoji}</Text>
              <Text style={styles.platformText}>{p.name}</Text>
            </View>
          ))}
        </View>
      </View>

      <TouchableOpacity
        onPress={onNext}
        activeOpacity={0.85}
        style={styles.primaryBtn}>
        <Text style={styles.primaryBtnText}>下一步：选择配音声音 →</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: {padding: 20, paddingBottom: 40},
  subtitle: {color: '#888', fontSize: 13, marginBottom: 20},
  card: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    padding: 18,
    marginBottom: 16,
  },
  stepRow: {flexDirection: 'row', alignItems: 'center', marginBottom: 16},
  stepBadge: {
    width: 24, height: 24, borderRadius: 12,
    backgroundColor: '#7C6AFF',
    justifyContent: 'center', alignItems: 'center', marginRight: 10,
  },
  stepBadgeText: {color: '#fff', fontSize: 12, fontWeight: '700'},
  stepTitle: {color: '#fff', fontSize: 15, fontWeight: '600'},
  tabRow: {flexDirection: 'row', marginBottom: 16},
  tab: {flex: 1, paddingVertical: 10, alignItems: 'center'},
  tabActive: {borderBottomWidth: 2, borderBottomColor: '#7C6AFF'},
  tabText: {color: '#888', fontSize: 14},
  tabTextActive: {color: '#7C6AFF', fontWeight: '600'},
  urlInputRow: {flexDirection: 'row', alignItems: 'center'},
  input: {
    flex: 1, backgroundColor: 'rgba(255,255,255,0.05)',
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 10, paddingHorizontal: 14, paddingVertical: 10,
    color: '#fff', fontSize: 14,
  },
  iconBtn: {
    width: 44, height: 44, marginLeft: 8,
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 10, justifyContent: 'center', alignItems: 'center',
  },
  warnText: {color: '#FFA500', fontSize: 11, marginTop: 8},
  dropZone: {
    height: 110, borderWidth: 1, borderColor: 'rgba(255,255,255,0.2)',
    borderRadius: 12, justifyContent: 'center', alignItems: 'center',
  },
  dropZoneIcon: {fontSize: 28, marginBottom: 8},
  dropZoneText: {color: '#888', fontSize: 13},
  filePreview: {
    flexDirection: 'row', alignItems: 'center', padding: 12,
    backgroundColor: 'rgba(72,187,120,0.1)',
    borderWidth: 1, borderColor: 'rgba(72,187,120,0.3)', borderRadius: 10,
  },
  fileName: {flex: 1, color: '#fff', fontSize: 13, marginHorizontal: 10},
  platformsTitle: {color: '#fff', fontWeight: '600', fontSize: 14, marginBottom: 12},
  platformsWrap: {flexDirection: 'row', flexWrap: 'wrap'},
  platformChip: {
    flexDirection: 'row', alignItems: 'center',
    paddingHorizontal: 12, paddingVertical: 8,
    backgroundColor: 'rgba(255,255,255,0.06)', borderRadius: 20,
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)',
    marginRight: 8, marginBottom: 8,
  },
  platformText: {color: '#fff', fontSize: 12, marginLeft: 6},
  primaryBtn: {
    height: 54, borderRadius: 14, backgroundColor: '#7C6AFF',
    justifyContent: 'center', alignItems: 'center', marginTop: 16,
  },
  primaryBtnText: {color: '#fff', fontSize: 16, fontWeight: '700'},
});
