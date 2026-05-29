import React, {useState} from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ScrollView,
} from 'react-native';
import {useVideoPlayer, VideoView} from 'expo-video';
import * as FileSystem from 'expo-file-system/legacy';
import type {NativeStackScreenProps} from '@react-navigation/native-stack';
import type {RootStackParamList} from '../../App';
import {getDownloadUrl} from '../services/api';

type Props = NativeStackScreenProps<RootStackParamList, 'Result'>;

export default function ResultScreen({navigation, route}: Props) {
  const {jobId} = route.params;
  const videoUrl = getDownloadUrl(jobId);

  const player = useVideoPlayer(videoUrl, p => {
    p.loop = false;
  });

  const [downloading, setDownloading] = useState(false);
  const [dlProgress, setDlProgress] = useState(0);
  const [saved, setSaved] = useState(false);

  const download = async () => {
    setDownloading(true);
    setDlProgress(0);
    try {
      const filename = `dubbed_${jobId}.mp4`;
      const targetPath = `${FileSystem.documentDirectory}${filename}`;
      const downloadResumable = FileSystem.createDownloadResumable(
        videoUrl,
        targetPath,
        {},
        ({totalBytesWritten, totalBytesExpectedToWrite}) => {
          if (totalBytesExpectedToWrite > 0) {
            setDlProgress(totalBytesWritten / totalBytesExpectedToWrite);
          }
        },
      );
      const res = await downloadResumable.downloadAsync();
      setDownloading(false);
      if (res?.uri) {
        setSaved(true);
        Alert.alert('下载完成', `已保存：${res.uri}`);
      } else {
        Alert.alert('下载失败', '未返回文件路径');
      }
    } catch (e) {
      setDownloading(false);
      Alert.alert('下载失败', e instanceof Error ? e.message : String(e));
    }
  };

  return (
    <View style={{flex: 1}}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.videoBox}>
          <VideoView
            player={player}
            style={styles.video}
            contentFit="contain"
            nativeControls
          />
        </View>

        <Text style={styles.successTitle}>✅ 配音完成</Text>
        <Text style={styles.successSub}>视频已成功翻译为中文配音</Text>
      </ScrollView>

      <View style={styles.footer}>
        {downloading ? (
          <View>
            <View style={styles.barOuter}>
              <View style={[styles.barInner, {width: `${dlProgress * 100}%`}]} />
            </View>
            <Text style={styles.dlText}>
              下载中 {Math.round(dlProgress * 100)}%
            </Text>
          </View>
        ) : (
          <TouchableOpacity
            activeOpacity={0.85}
            onPress={download}
            disabled={saved}
            style={[styles.primaryBtn, saved && styles.btnDisabled]}>
            <Text style={styles.primaryBtnText}>
              {saved ? '✅ 已保存' : '⬇️  下载视频到手机'}
            </Text>
          </TouchableOpacity>
        )}
        <TouchableOpacity
          activeOpacity={0.85}
          onPress={() => navigation.popToTop()}
          style={styles.secondaryBtn}>
          <Text style={styles.secondaryBtnText}>再翻译一个</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  scroll: {padding: 20, paddingBottom: 20},
  videoBox: {
    aspectRatio: 16 / 9, borderRadius: 16,
    backgroundColor: '#000', overflow: 'hidden',
  },
  video: {width: '100%', height: '100%'},
  successTitle: {color: '#fff', fontSize: 22, fontWeight: '700', marginTop: 24, textAlign: 'center'},
  successSub: {color: '#888', fontSize: 14, marginTop: 8, textAlign: 'center'},
  footer: {padding: 20, backgroundColor: '#0D0F1A'},
  primaryBtn: {
    height: 54, borderRadius: 14, backgroundColor: '#7C6AFF',
    justifyContent: 'center', alignItems: 'center',
  },
  btnDisabled: {opacity: 0.5},
  primaryBtnText: {color: '#fff', fontSize: 16, fontWeight: '700'},
  secondaryBtn: {
    height: 48, borderRadius: 14,
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center', alignItems: 'center', marginTop: 10,
  },
  secondaryBtnText: {color: 'rgba(255,255,255,0.7)', fontSize: 14},
  barOuter: {
    height: 8, backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 4, overflow: 'hidden',
  },
  barInner: {height: '100%', backgroundColor: '#7C6AFF'},
  dlText: {color: '#888', fontSize: 12, marginTop: 6, textAlign: 'center'},
});
