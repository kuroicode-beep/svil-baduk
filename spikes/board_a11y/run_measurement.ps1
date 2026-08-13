# spikes/board_a11y/run_measurement.ps1
#
# 접근성 스파이크 실측 — NVDA 와 스파이크 앱을 함께 띄운다.
# 이 파일은 UTF-8 BOM 으로 저장한다 (PS 5.1 이 CP949 로 오독하는 것 방지).
#
# 끝나면 read_measurement.ps1 을 돌려 발화 기록을 사람이 읽을 수 있는
# 형태로 뽑아낸다. NVDA 로그에 낭독된 문장이 시각과 함께 전부 남는다.

$ErrorActionPreference = 'Stop'

$nvdaDir = 'D:\C_Backup\nvda-portable\app'
$nvda    = Join-Path $nvdaDir 'nvda.exe'
$ini     = Join-Path $nvdaDir 'userConfig\nvda.ini'
$spike   = Join-Path $PSScriptRoot 'build\windows\x64\runner\Release\board_a11y.exe'

if (-not (Test-Path $spike)) {
    throw "스파이크 빌드가 없습니다: $spike`n먼저 이 폴더에서 'flutter build windows --release' 를 실행하세요."
}

# ── 무음 설정 방지 ────────────────────────────────────────────────
# 자동 측정용으로 synth=silence 를 넣어두면 사람이 켰을 때 아무 말도
# 하지 않는다. 실제로 한 번 그렇게 나가서 측정이 통째로 날아갔다.
if (Test-Path $ini) {
    $conf = Get-Content $ini -Raw -Encoding UTF8
    if ($conf -match 'synth\s*=\s*silence') {
        Write-Host '무음 합성기가 설정돼 있어 되돌립니다.' -ForegroundColor Yellow
        $conf = $conf -replace 'synth\s*=\s*silence', 'synth = oneCore'
        [System.IO.File]::WriteAllText($ini, $conf, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# 이전 기록과 섞이지 않게 로그를 비운다
Remove-Item "$env:TEMP\nvda.log" -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $nvda)) {
    Write-Warning "NVDA 포터블이 없습니다: $nvda"
    Write-Host   '정식 설치본: D:\C_Backup\nvda-portable\nvda_2026.1.1.exe'
} else {
    if (-not (Get-Process nvda -ErrorAction SilentlyContinue)) {
        Write-Host 'NVDA 시작... (소리가 나야 정상입니다)'
        Start-Process $nvda -ArgumentList '--log-level=IO'
        Start-Sleep -Seconds 10
    } else {
        Write-Host 'NVDA 이미 실행 중'
    }
}

Write-Host ''
Write-Host '── 소리가 안 나면 여기서 멈추세요 ──────────────────────' -ForegroundColor Yellow
Write-Host '  NVDA 메뉴(Insert+N) → 설정 → 음성 → 합성기 에서 확인.'
Write-Host '  소리 없이는 측정이 안 됩니다.'
Write-Host ''
Write-Host '── 음성 뷰어를 켜세요 ─────────────────────────────────'
Write-Host '  NVDA 메뉴(Insert+N) → 도구 → 음성 뷰어'
Write-Host '  낭독된 문장이 그 창에 쌓입니다. 눈으로 세기 편합니다.'
Write-Host ''

Start-Process $spike
Write-Host '스파이크를 띄웠습니다.'
Write-Host ''
Write-Host '── 측정 순서 ──────────────────────────────────────────'
Write-Host '  0. 스파이크 창을 클릭해 앞으로 가져옵니다.'
Write-Host '  1. Tab 을 눌러 판에 포커스를 줍니다.'
Write-Host '       → 판 크기와 조작 힌트가 낭독되나요?'
Write-Host '  2. 화살표를 천천히(초당 2회) 20번 누릅니다.'
Write-Host '       → 좌표가 정확히 20번 낭독되나요? 누락은 없나요?'
Write-Host '  3. 화살표를 빠르게(초당 8회) 30번 누릅니다.'
Write-Host '       → 손을 뗀 뒤 0.5초 안에 최종 좌표가 나오나요?'
Write-Host '  4. Ctrl+L 로 좌표칸에 가서 D16 + Enter.'
Write-Host '       → 1초 안에 결과가 낭독되고 포커스가 그대로인가요?'
Write-Host '  5. 같은 칸에 I5, 그다음 Z99 를 넣어 봅니다.'
Write-Host '       → 왜 안 되는지 낭독되나요?'
Write-Host '  6. ★ 좌표칸에 포커스를 둔 채 이미 돌이 있는 자리를 넣습니다.'
Write-Host '       → 반칙 오류가 낭독되나요?  ← 이 하나가 설계 분기점입니다'
Write-Host '  7. 좌표칸에 포커스를 둔 채 상대 착수를 기다립니다.'
Write-Host '       → 1초 안에 낭독되나요?'
Write-Host '  8. Tab 과 Esc 로 판에서 빠져나올 수 있나요?'
Write-Host '  9. 화면 배율을 200% 로 올렸을 때 읽어주기 문구가 잘리나요?'
Write-Host ''
Write-Host '다 하셨으면 이 폴더의 read_measurement.ps1 을 실행하세요.'
Write-Host '낭독 기록이 시각과 함께 정리돼 나옵니다.'
