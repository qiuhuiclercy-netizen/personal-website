import React, {useState} from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ScrollView,
  Platform,
  PermissionsAndroid,
} from 'react-native';
import Video from 'react-native-video';
import RNFS from 'react-native-fs';
import type {NativeStackScreenProps} from '@react-navigation/native-stack';
import type {RootStackParamList} from '../../App';
import {getDownloadUrl} from '../services/api';

type Props = NativeStackScreenProps<RootStackParamList, 'Result'>;

export default function ResultScreen({navigation, route}: Props) {
  const {jobId} = route.params;
  const videoUrl = getDownloadUrl(jobId);
  const [downloading, setDownloading] = useState(false);
  const [dlProgress, setDlProgress] = useState(0);
  const [saved, setSaved] = useState(false);
  const [paused, setPaused] = useState(true);

  const requestPermissionIfNeeded = async (): Promise<boolean> => {
    if (Platform.OS !== 'android') return true;
    if (Platform.Version >= 33) return true;
    try {
      const granted = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE,
      );
      return granted === PermissionsAndroid.RESULTS.GRANTED;
    } catch {
      return false;
    }
  };

  const download = async () => {
    const ok = await requestPermissionIfNeeded();
    if (!ok) {
      Alert.alert('需要权限', '需要存储权限以保存视频');
      return;
    }
    setDownloading(true);
    setDlProgress(0);
    try {
      const savePath =
        Platform.OS === 'android'
          ? `${RNFS.DownloadDirectoryPath}/配音视频_${jobId}.mp4`
          : `${RNFS.DocumentDirectoryPath}/配音视频_${jobId}.mp4`;
      const res = RNFS.downloadFile({
        fromUrl: videoUrl,
        toFile: savePath,
        progressInterval: 500,
        progressDivider: 1,
        progress: ({bytesWritten, contentLength}) => {
          if (contentLength > 0) {
            setDlProgress(bytesWritten / contentLength);
          }
        },
      });
      const r = await res.promise;
      setDownloading(false);
      if (r.statusCode === 200) {
        setSaved(true);
        Alert.alert('下载完成', `已保存到：${savePath}`);
      } else {
        Alert.alert('下载失败', `状态码 ${r.statusCode}`);
      }
    } catch (e) {
      setDownloading(false);
      Alert.alert('下载失败', String(e));
    }
  };

  return (
    <View style={{flex: 1}}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.videoBox}>
          <Video
            source={{uri: videoUrl}}
            style={styles.video}
            controls
            paused={paused}
            resizeMode="contain"
            onLoad={() => setPaused(false)}
          />
        </View>

        <Text style={styles.successTitle}>✅ 配音完成</Text>
        <Text style={styles.successSub}>视频已成功翻译为中文配音</Text>
      </ScrollView>

      <View style={styles.footer}>
        {downloading ? (
          <View>
            <View style={styles.barOuter}>
              <View
                style={[styles.barInner, {width: `${dlProgress * 100}%`}]}
              />
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
              {saved ? '✅ 已保存到下载' : '⬇️  下载视频到手机'}
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
    aspectRatio: 16 / 9,
    borderRadius: 16,
    backgroundColor: '#000',
    overflow: 'hidden',
  },
  video: {width: '100%', height: '100%'},
  successTitle: {color: '#fff', fontSize: 22, fontWeight: '700', marginTop: 24, textAlign: 'center'},
  successSub: {color: '#888', fontSize: 14, marginTop: 8, textAlign: 'center'},
  footer: {padding: 20, backgroundColor: '#0D0F1A'},
  primaryBtn: {
    height: 54,
    borderRadius: 14,
    backgroundColor: '#7C6AFF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  btnDisabled: {opacity: 0.5},
  primaryBtnText: {color: '#fff', fontSize: 16, fontWeight: '700'},
  secondaryBtn: {
    height: 48,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 10,
  },
  secondaryBtnText: {color: 'rgba(255,255,255,0.7)', fontSize: 14},
  barOuter: {
    height: 8,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 4,
    overflow: 'hidden',
  },
  barInner: {height: '100%', backgroundColor: '#7C6AFF'},
  dlText: {color: '#888', fontSize: 12, marginTop: 6, textAlign: 'center'},
});
