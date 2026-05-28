import axios, {AxiosError} from 'axios';

export const API_BASE = 'http://121.41.16.66:8000';

const client = axios.create({
  baseURL: API_BASE,
  timeout: 30000,
});

export interface VoiceInfo {
  desc: string;
  speed: number;
  is_custom?: boolean;
}

export interface JobStatus {
  status: 'pending' | 'running' | 'done' | 'error';
  progress?: string;
  error?: string;
  platform?: string;
  platform_emoji?: string;
}

function extractError(e: unknown): string {
  if (e instanceof AxiosError) {
    const data = e.response?.data as {detail?: string} | string | undefined;
    if (data && typeof data === 'object' && data.detail) {
      return data.detail;
    }
    if (typeof data === 'string') {
      return data;
    }
    if (e.code === 'ECONNABORTED') {
      return '连接超时，请检查网络或稍后重试';
    }
    if (e.code === 'ERR_NETWORK') {
      return '无法连接服务器，请检查网络';
    }
    if (e.response?.status === 429) {
      return '服务器繁忙，请稍后重试';
    }
    if (e.response?.status === 413) {
      return '文件太大，请压缩后再上传';
    }
  }
  return String(e);
}

export async function getVoices(): Promise<Record<string, VoiceInfo>> {
  const res = await client.get<Record<string, VoiceInfo>>('/api/voices');
  return res.data;
}

export function voicePreviewUrl(character: string): string {
  return `${API_BASE}/api/voice/preview/${encodeURIComponent(character)}`;
}

export async function translateUrl(
  url: string,
  character: string,
): Promise<string> {
  try {
    const res = await client.post<{job_id: string}>('/api/translate/url', {
      url,
      character,
      tts_provider: 'xunfei',
    });
    return res.data.job_id;
  } catch (e) {
    throw new Error(extractError(e));
  }
}

export async function translateFile(
  filePath: string,
  fileName: string,
  character: string,
  onProgress?: (percent: number) => void,
): Promise<string> {
  const form = new FormData();
  form.append('file', {
    uri: filePath.startsWith('file://') ? filePath : `file://${filePath}`,
    name: fileName,
    type: 'video/mp4',
  } as unknown as Blob);
  form.append('character', character);
  form.append('tts_provider', 'xunfei');

  try {
    const res = await client.post<{job_id: string}>(
      '/api/translate/file',
      form,
      {
        headers: {'Content-Type': 'multipart/form-data'},
        timeout: 600000,
        onUploadProgress: e => {
          if (e.total && onProgress) {
            onProgress(e.loaded / e.total);
          }
        },
      },
    );
    return res.data.job_id;
  } catch (e) {
    throw new Error(extractError(e));
  }
}

export async function getJobStatus(jobId: string): Promise<JobStatus> {
  const res = await client.get<JobStatus>(`/api/job/${jobId}`);
  return res.data;
}

export function getDownloadUrl(jobId: string): string {
  return `${API_BASE}/api/download/${jobId}`;
}
