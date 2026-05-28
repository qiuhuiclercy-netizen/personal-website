import React, {useEffect, useRef, useState} from 'react';
import {View, Text, StyleSheet, ActivityIndicator} from 'react-native';
import type {NativeStackScreenProps} from '@react-navigation/native-stack';
import type {RootStackParamList} from '../../App';
import {translateFile, translateUrl, getJobStatus} from '../services/api';

type Props = NativeStackScreenProps<RootStackParamList, 'Progress'>;

const STEPS = [
  {id: 'download', label: '📥 下载/接收视频', keywords: ['下载', '接收', 'upload', '上传']},
  {id: 'asr', label: '🎤 语音识别', keywords: ['语音识别', '提取音频', 'ASR']},
  {id: 'translate', label: '🌐 翻译成中文', keywords: ['翻译']},
  {id: 'tts', label: '🎭 角色配音合成', keywords: ['配音', 'TTS', '合成']},
  {id: 'merge', label: '🎬 合并输出', keywords: ['合并', '输出', '完成']},
];

export default function ProgressScreen({navigation, route}: Props) {
  const [status, setStatus] = useState('提交任务...');
  const [progress, setProgress] = useState(0.05);
  const [activeStep, setActiveStep] = useState(-1);
  const [error, setError] = useState<string | null>(null);
  const pollTimer = useRef<NodeJS.Timeout | null>(null);
  const stoppedRef = useRef(false);

  useEffect(() => {
    start();
    return () => {
      stoppedRef.current = true;
      if (pollTimer.current) clearTimeout(pollTimer.current);
    };
  }, []);

  const detectStep = (msg: string): number => {
    for (let i = 0; i < STEPS.length; i++) {
      if (STEPS[i].keywords.some(k => msg.includes(k))) return i;
    }
    return activeStep;
  };

  const poll = (jobId: string) => {
    const tick = async () => {
      if (stoppedRef.current) return;
      try {
        const job = await getJobStatus(jobId);
        const msg = job.progress ?? '';
        setStatus(msg);
        const step = detectStep(msg);
        setActiveStep(step);
        if (step >= 0) {
          setProgress(0.15 + ((step + 1) / STEPS.length) * 0.8);
        }
        if (job.status === 'done') {
          navigation.replace('Result', {jobId});
          return;
        }
        if (job.status === 'error') {
          setError(job.error ?? '未知错误');
          return;
        }
      } catch (e) {
        setError(String(e));
        return;
      }
      pollTimer.current = setTimeout(tick, 2000);
    };
    tick();
  };

  const start = async () => {
    try {
      let jobId: string;
      if (route.params.isUrl) {
        jobId = await translateUrl(route.params.url!, route.params.character);
      } else {
        jobId = await translateFile(
          route.params.filePath!,
          'video.mp4',
          route.params.character,
          p => setProgress(p * 0.15),
        );
      }
      poll(jobId);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  };

  if (error) {
    return (
      <View style={styles.errorBox}>
        <Text style={{fontSize: 60}}>❌</Text>
        <Text style={styles.errorTitle}>处理失败</Text>
        <Text style={styles.errorMsg}>{error}</Text>
        <Text style={styles.backHint} onPress={() => navigation.popToTop()}>
          返回首页
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.pct}>{Math.round(progress * 100)}%</Text>
      <View style={styles.barOuter}>
        <View style={[styles.barInner, {width: `${progress * 100}%`}]} />
      </View>

      <View style={styles.stepsList}>
        {STEPS.map((s, i) => {
          const isDone = i < activeStep;
          const isActive = i === activeStep;
          const color = isDone ? '#4ADE80' : isActive ? '#7C6AFF' : '#666';
          return (
            <View key={s.id} style={styles.stepRow}>
              <View style={[styles.stepBar, {backgroundColor: color}]} />
              <Text
                style={{
                  color,
                  fontSize: 14,
                  fontWeight: isActive ? '600' : '400',
                }}>
                {s.label}
                {isDone ? ' ✓' : ''}
              </Text>
              {isActive && (
                <ActivityIndicator
                  size="small"
                  color={color}
                  style={{marginLeft: 8}}
                />
              )}
            </View>
          );
        })}
      </View>

      <Text style={styles.status}>{status}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {flex: 1, padding: 24},
  pct: {color: '#fff', fontSize: 36, fontWeight: '700'},
  barOuter: {
    height: 8,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 4,
    overflow: 'hidden',
    marginTop: 12,
  },
  barInner: {height: '100%', backgroundColor: '#7C6AFF', borderRadius: 4},
  stepsList: {marginTop: 28},
  stepRow: {flexDirection: 'row', alignItems: 'center', paddingVertical: 6},
  stepBar: {width: 3, height: 32, marginRight: 12, borderRadius: 1.5},
  status: {color: '#888', fontSize: 13, textAlign: 'center', marginTop: 24},
  errorBox: {flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24},
  errorTitle: {color: '#fff', fontSize: 22, fontWeight: '700', marginTop: 16},
  errorMsg: {color: '#F87171', fontSize: 14, textAlign: 'center', marginTop: 12},
  backHint: {color: '#7C6AFF', fontSize: 14, marginTop: 24, textDecorationLine: 'underline'},
});
