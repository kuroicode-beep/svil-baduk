# spikes/board_a11y/run_measurement.ps1
#
# 접근성 스파이크 실측 준비 — NVDA 음성 뷰어와 스파이크 앱을 함께 띄운다.
# 이 파일은 UTF-8 BOM 으로 저장한다 (PS 5.1 이 CP949 로 오독하는 것 방지).
#
# 왜 사람이 실행해야 하나:
#   NVDA 는 대화형 데스크톱 세션에 붙어야 동작한다. 도구가 띄우는 분리된
#   프로세스에서는 화면을 후킹하지도, 세션 로그를 쓰지도 못한다(실측 확인).
#   그래서 이 스크립트는 자동 측정이 아니라 **준비**만 한다.

$ErrorActionPreference = 'Stop'

$nvda  = 'D:\C_Backup\nvda-portable\app\nvda.exe'
$spike = Join-Path $PSScriptRoot 'build\windows\x64\runner\Release\board_a11y.exe'

if (-not (Test-Path $spike)) {
    throw "스파이크 빌드가 없습니다: $spike`n먼저 이 폴더에서 'flutter build windows --release' 를 실행하세요."
}

if (-not (Test-Path $nvda)) {
    Write-Warning "NVDA 포터블이 없습니다: $nvda"
    Write-Host   "정식 설치본: D:\C_Backup\nvda-portable\nvda_2026.1.1.exe"
    Write-Host   "또는 https://www.nvaccess.org/download/ 에서 받으세요."
} else {
    if (-not (Get-Process nvda -ErrorAction SilentlyContinue)) {
        Write-Host 'NVDA 시작...'
        Start-Process $nvda
        Start-Sleep -Seconds 8
    } else {
        Write-Host 'NVDA 이미 실행 중'
    }
    Write-Host ''
    Write-Host '── NVDA 음성 뷰어를 켜세요 ──────────────────'
    Write-Host '  NVDA 메뉴(Insert+N) → 도구 → 음성 뷰어'
    Write-Host '  낭독된 문장이 그 창에 텍스트로 쌓입니다. 그걸로 셉니다.'
    Write-Host ''
}

Write-Host '스파이크 실행...'
Start-Process $spike

Write-Host ''
Write-Host '── 측정 항목 (docs/reports 의 스파이크 보고서에 기록) ──'
Write-Host '  6번이 가장 중요합니다. 이 하나가 바둑판 설계의 분기점입니다.'
Write-Host ''
Write-Host '  1. Tab 으로 판에 닿으면 판 크기 + 조작 힌트가 낭독되는가'
Write-Host '  2. 화살표를 초당 2회씩 20번 → 좌표가 정확히 20번 낭독되는가'
Write-Host '  3. 초당 8회씩 30번 → 마지막 입력 후 500ms 안에 최종 좌표가 나오는가'
Write-Host '  4. 좌표칸에 D16 + Enter → 1초 안에 결과가 낭독되고 포커스가 유지되는가'
Write-Host '  5. I5 · Z99 를 넣으면 오류 사유가 낭독되는가'
Write-Host '  6. ★ 포커스가 좌표칸 안에 있을 때 반칙 오류가 낭독되는가'
Write-Host '  7. 포커스가 좌표칸에 있어도 상대 착수가 1초 안에 낭독되는가'
Write-Host '  8. Tab · Esc 로 판에서 빠져나올 수 있는가 (포커스가 갇히지 않는가)'
Write-Host '  9. 커서 읽어주기 문구가 배율 100% · 200% 에서 잘리지 않는가'
Write-Host ''
Write-Host '6번이 실패하면: 오류도 value 채널로 미러링하도록 바꿔야 합니다.'
Write-Host '1 · 4 · 8 이 실패하면: Flutter 로는 이 제품의 스크린리더 경로를'
Write-Host '   Windows 에서 담을 수 없다는 뜻이라, 설계를 다시 잡아야 합니다.'
