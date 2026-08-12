// src/data/backup.ts — 사용자 데이터 내보내기/가져오기
//
// Flutter 클라이언트로 데이터를 옮기는 **유일한 경로**다.
// WebView2 의 localStorage 를 직접 파헤치는 대신, 양쪽 앱이 읽고 쓰는
// 버전 있는 JSON 한 덩어리를 정본으로 삼는다.
//
// 진행 중인 대국(solo-snapshot)은 일부러 제외한다 — GameState 는 엔진 내부
// 표현이라 두 구현 사이에서 호환을 보장할 수 없고, 옮겨봐야 이어두기 어렵다.

export const BACKUP_FORMAT = 'svil-baduk-backup'
export const BACKUP_VERSION = 1

/** 백업에 담는 localStorage 키 — 진행 중 대국은 제외 */
export const BACKUP_KEYS = [
  'svil-baduk-settings',
  'svil-baduk-profile',
  'svil-baduk-learn-progress',
  'svil-baduk-solo-prefs',
] as const

export type BackupKey = (typeof BACKUP_KEYS)[number]

export interface BackupFile {
  format: typeof BACKUP_FORMAT
  version: number
  /** 내보낸 앱 버전 — 가져오는 쪽이 판단 근거로 쓴다 */
  appVersion: string
  savedAt: string
  data: Partial<Record<BackupKey, unknown>>
}

export type ImportResult =
  | { ok: true; restored: BackupKey[]; skipped: BackupKey[] }
  | { ok: false; reason: 'not_json' | 'not_backup' | 'unsupported_version' }

/** 현재 저장된 사용자 데이터를 한 덩어리로 모은다 */
export function buildBackup(appVersion: string): BackupFile {
  const data: Partial<Record<BackupKey, unknown>> = {}
  for (const key of BACKUP_KEYS) {
    const raw = localStorage.getItem(key)
    if (raw === null) continue
    try {
      data[key] = JSON.parse(raw)
    } catch {
      // 손상된 값은 조용히 건너뛴다 — 백업이 실패하는 것보다 낫다
    }
  }
  return {
    format: BACKUP_FORMAT,
    version: BACKUP_VERSION,
    appVersion,
    savedAt: new Date().toISOString(),
    data,
  }
}

/**
 * 백업을 되돌린다. 각 키는 원래 로더가 검증·마이그레이션하므로
 * 여기서는 형태만 확인하고 그대로 써 넣는다.
 */
export function restoreBackup(text: string): ImportResult {
  let parsed: unknown
  try {
    parsed = JSON.parse(text)
  } catch {
    return { ok: false, reason: 'not_json' }
  }
  if (!parsed || typeof parsed !== 'object') return { ok: false, reason: 'not_backup' }

  const file = parsed as Partial<BackupFile>
  if (file.format !== BACKUP_FORMAT) return { ok: false, reason: 'not_backup' }
  if (typeof file.version !== 'number' || file.version > BACKUP_VERSION) {
    return { ok: false, reason: 'unsupported_version' }
  }
  if (!file.data || typeof file.data !== 'object') return { ok: false, reason: 'not_backup' }

  const restored: BackupKey[] = []
  const skipped: BackupKey[] = []
  for (const key of BACKUP_KEYS) {
    const value = (file.data as Record<string, unknown>)[key]
    if (value === undefined) {
      skipped.push(key)
      continue
    }
    localStorage.setItem(key, JSON.stringify(value))
    restored.push(key)
  }
  return { ok: true, restored, skipped }
}

export function backupFilename(appVersion: string, now = new Date()): string {
  const stamp = now.toISOString().slice(0, 19).replace(/[:T]/g, '-')
  return `svil-baduk-backup-${appVersion}-${stamp}.json`
}

/** 브라우저에서 파일로 내려받기 */
export function downloadBackup(file: BackupFile): void {
  const blob = new Blob([JSON.stringify(file, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = backupFilename(file.appVersion, new Date(file.savedAt))
  a.click()
  URL.revokeObjectURL(url)
}
