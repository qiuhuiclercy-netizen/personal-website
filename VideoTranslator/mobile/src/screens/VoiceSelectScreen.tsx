import React, {useEffect, useState, useRef} from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import {useAudioPlayer, useAudioPlayerStatus} from 'expo-audio';
import type {NativeStackScreenProps} from '@react-navigation/native-stack';
import type {RootStackParamList} from '../../App';
import {getVoices, voicePreviewUrl, VoiceInfo} from '../services/api';

type Props = NativeStackScreenProps<RootStackParamList, 'VoiceSelect'>;

const VOICE_EMOJIS: Record<string, string> = {
  '猫娘': '🐱',
  '派大星': '⭐',
  '林黛玉': '🌸',
  '播音员': '📻',
  '男主播': '🎙️',
};

export default function VoiceSelectScreen({navigation, route}: Props) {
  const [voices, setVoices] = useState<Record<string, VoiceInfo>>({});
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState('播音员');
  const [previewing, setPreviewing] = useState<string | null>(null);
  const [currentUrl, setCurrentUrl] = useState<string | null>(null);

  const player = useAudioPlayer(currentUrl);
  const status = useAudioPlayerStatus(player);
  const stoppedRef = useRef(false);

  useEffect(() => {
    getVoices()
      .then(data => {
        const filtered = {...data};
        delete filtered['自定义角色'];
        setVoices(filtered);
        setLoading(false);
      })
      .catch(() => setLoading(false));
    return () => {
      stoppedRef.current = true;
      try {
        player.remove();
      } catch {}
    };
  }, []);

  useEffect(() => {
    if (status.didJustFinish) {
      setPreviewing(null);
    }
  }, [status.didJustFinish]);

  const onPreview = async (name: string) => {
    try {
      if (previewing === name) {
        player.pause();
        setPreviewing(null);
        return;
      }
      const url = voicePreviewUrl(name);
      setCurrentUrl(url);
      setPreviewing(name);
      // small delay to let player swap source
      setTimeout(() => {
        player.seekTo(0);
        player.play();
      }, 100);
    } catch (e) {
      setPreviewing(null);
      Alert.alert('试听失败', String(e));
    }
  };

  const onStart = () => {
    try {
      player.pause();
    } catch {}
    navigation.navigate('Progress', {
      isUrl: route.params.isUrl,
      url: route.params.url,
      filePath: route.params.filePath,
      mimeType: route.params.mimeType,
      character: selected,
    });
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color="#7C6AFF" />
      </View>
    );
  }

  return (
    <View style={{flex: 1}}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.sourceCard}>
          <Text style={{fontSize: 16}}>🎧</Text>
          <Text style={styles.sourceText} numberOfLines={1}>
            {route.params.isUrl
              ? '已选链接'
              : `已选文件：${route.params.fileName ?? ''}`}
          </Text>
        </View>

        <Text style={styles.title}>🎭 选择配音角色</Text>
        <Text style={styles.hint}>点击 ▶ 试听声音，点击卡片选择</Text>

        {Object.entries(voices).map(([name, info]) => {
          const isSelected = name === selected;
          const isPlaying = previewing === name;
          return (
            <TouchableOpacity
              key={name}
              activeOpacity={0.85}
              onPress={() => setSelected(name)}
              style={[styles.voiceCard, isSelected && styles.voiceCardActive]}>
              <View style={styles.voiceAvatar}>
                <Text style={{fontSize: 26}}>{VOICE_EMOJIS[name] ?? '🎤'}</Text>
              </View>
              <View style={{flex: 1, marginLeft: 14}}>
                <View style={{flexDirection: 'row', alignItems: 'center'}}>
                  <Text style={styles.voiceName}>{name}</Text>
                  {isSelected && (
                    <View style={styles.selectedBadge}>
                      <Text style={styles.selectedBadgeText}>已选</Text>
                    </View>
                  )}
                </View>
                <Text style={styles.voiceDesc}>{info.desc}</Text>
              </View>
              <TouchableOpacity
                onPress={() => onPreview(name)}
                style={[styles.playBtn, isPlaying && styles.playBtnActive]}>
                <Text style={{fontSize: 20, color: '#fff'}}>
                  {isPlaying ? '■' : '▶'}
                </Text>
              </TouchableOpacity>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      <View style={styles.footer}>
        <TouchableOpacity
          activeOpacity={0.85}
          onPress={onStart}
          style={styles.primaryBtn}>
          <Text style={styles.primaryBtnText}>⚡ 开始翻译配音</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  center: {flex: 1, justifyContent: 'center', alignItems: 'center'},
  scroll: {padding: 20, paddingBottom: 40},
  sourceCard: {
    flexDirection: 'row', alignItems: 'center', padding: 14,
    backgroundColor: 'rgba(124,106,255,0.12)',
    borderWidth: 1, borderColor: 'rgba(124,106,255,0.3)',
    borderRadius: 12, marginBottom: 24,
  },
  sourceText: {flex: 1, color: '#fff', fontSize: 13, marginLeft: 8},
  title: {color: '#fff', fontSize: 16, fontWeight: '700'},
  hint: {color: '#888', fontSize: 12, marginTop: 6, marginBottom: 16},
  voiceCard: {
    flexDirection: 'row', alignItems: 'center', padding: 16,
    backgroundColor: 'rgba(255,255,255,0.04)',
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 16, marginBottom: 12,
  },
  voiceCardActive: {
    backgroundColor: 'rgba(124,106,255,0.15)',
    borderColor: '#7C6AFF', borderWidth: 2,
  },
  voiceAvatar: {
    width: 52, height: 52, borderRadius: 14,
    backgroundColor: 'rgba(255,255,255,0.06)',
    justifyContent: 'center', alignItems: 'center',
  },
  voiceName: {color: '#fff', fontSize: 16, fontWeight: '700'},
  voiceDesc: {color: '#888', fontSize: 12, marginTop: 4},
  selectedBadge: {
    marginLeft: 8, paddingHorizontal: 8, paddingVertical: 2,
    backgroundColor: '#7C6AFF', borderRadius: 6,
  },
  selectedBadgeText: {color: '#fff', fontSize: 10, fontWeight: '700'},
  playBtn: {
    width: 44, height: 44, borderRadius: 22,
    backgroundColor: 'rgba(255,255,255,0.1)',
    justifyContent: 'center', alignItems: 'center',
  },
  playBtnActive: {backgroundColor: '#FF6AAD'},
  footer: {padding: 20, backgroundColor: '#0D0F1A'},
  primaryBtn: {
    height: 56, borderRadius: 14, backgroundColor: '#7C6AFF',
    justifyContent: 'center', alignItems: 'center',
  },
  primaryBtnText: {color: '#fff', fontSize: 17, fontWeight: '700'},
});
