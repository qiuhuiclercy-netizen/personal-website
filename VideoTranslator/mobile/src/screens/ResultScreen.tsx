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
import * as MediaLibrary from 'expo-media-library';
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
    // 1. 申请相册权限
    const perm = await MediaLibrary.requestPermissionsAsync(true);
    if (!perm.granted) {
      Alert.alert(
        '需要相册权限',
        '请在系统设置里允许 VideoDub AI 访问相册，否则视频无法保存',
      );
      return;
    }

    setDownloading(true);
    setDlProgress(0);
    try {
      // 2. 先下载到 App 缓存目录
      const filename = `VideoDub_${jobId}.mp4`;
      const cachePath = `${FileSystem.cacheDirectory}${filename}`;
      const downloadResumable = FileSystem.createDownloadResumable(
        videoUrl,
        cachePath,
        {},
        ({totalBytesWritten, totalBytesExpectedToWrite}) => {
          if (totalBytesExpectedToWrite > 0) {
            setDlProgress(totalBytesWritten / totalBytesExpectedToWrite);
          }
        },
      );
      const res = await downloadResumable.downloadAsync();
      if (!res?.uri) {
        setDownloading(false);
        Alert.alert('下载失败', '未返回文件路径');
        return;
      }

      // 3. 写入系统相册（Movies/VideoDub AI 相册）
      const asset = await MediaLibrary.createAssetAsync(res.uri);
      try {
        const album = await MediaLibrary.getAlbumAsync('VideoDub AI');
        if (album) {
          await MediaLibrary.addAssetsToAlbumAsync([asset], album, false);
        } else {
          await MediaLibrary.createAlbumAsync('VideoDub AI', asset, false);
        }
      } catch {
        // 部分设备不允许自建相册，资产已经在相册主目录里，忽略此错误
      }

      // 4. 清理缓存文件
      try { await FileSystem.deleteAsync(res.uri, {idempotent: true}); } catch {}

      setDownloading(false);
      setSaved(true);
      Alert.alert('保存完成', '中文配音视频已存入手机相册（VideoDub AI 相册）。');
    } catch (e) {
      setDownloading(false);
      Alert.alert('保存失败', e instanceof Error ? e.message : String(e));
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
