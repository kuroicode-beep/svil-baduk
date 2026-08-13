# spikes/board_a11y/read_measurement.ps1
#
# NVDA 로그에서 스파이크가 낭독한 내용만 뽑아 시각과 함께 정리한다.
# 음성 뷰어를 눈으로 세는 것과 같은 내용을 파일로 남겨, 나중에(다른 세션·다른 사람이)
# 그대로 읽고 판정할 수 있게 하는 것이 목적이다.
#
# 이 파일은 UTF-8 BOM 으로 저장한다.

$ErrorActionPreference = 'Stop'

$log = "$env:TEMP\nvda.log"
if (-not (Test-Path $log)) {
    throw "NVDA 로그가 없습니다: $log`nrun_measurement.ps1 로 NVDA 를 먼저 띄우세요."
}

$out = Join-Path $PSScriptRoot 'measurement-transcript.txt'
$lines = Get-Content $log -Encoding UTF8

$rows = New-Object System.Collections.Generic.List[string]
$prev = $null

for ($i = 0; $i -lt $lines.Count - 1; $i++) {
    if ($lines[$i] -notmatch 'IO - speech\.speech\.speak \((\d\d:\d\d:\d\d\.\d+)\)') { continue }
    $time = $Matches[1]
    $sp = $lines[$i + 1]
    if ($sp -notmatch '^Speaking') { continue }

    # NVDA 내부 표현을 사람이 읽는 문장으로
    $text = $sp -replace '^Speaking \[', '' -replace '\]$', ''
    $text = $text -replace "LangChangeCommand \('[^']*'\), ", ''
    $text = $text -replace ', CancellableSpeech \([^)]*\)', ''
    $text = $text -replace 'CharacterModeCommand\((True|False)\), ?', ''
    $text = $text -replace "^'|'$", ''
    $text = $text -replace "', '", ' · '
    $text = $text.Trim()
    if (-not $text) { continue }

    # 직전 발화와의 간격 — 응답 시간 판정에 쓴다
    $gap = ''
    if ($prev) {
        # NVDA 는 밀리초 자릿수가 일정하지 않다 — 형식을 고정하지 않고 파싱한다
        $t1 = [datetime]::MinValue; $t2 = [datetime]::MinValue
        $ok1 = [datetime]::TryParse($time, [ref]$t1)
        $ok2 = [datetime]::TryParse($prev, [ref]$t2)
        $d = if ($ok1 -and $ok2) { ($t1 - $t2).TotalMilliseconds } else { -1 }
        if ($d -ge 0 -and $d -lt 60000) { $gap = '{0,6:N0}ms' -f $d }
    }
    $prev = $time

    $rows.Add(('{0}  {1,-9}  {2}' -f $time, $gap, $text))
}

$header = @(
    'NVDA 낭독 기록',
    ('추출 시각 : ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
    ('원본 로그 : ' + $log),
    ('발화 건수 : ' + $rows.Count),
    '',
    '왼쪽부터 시각 · 직전 발화와의 간격 · 낭독된 내용.',
    '간격은 응답 시간 판정(3번 500ms, 4·7번 1000ms)에 그대로 쓸 수 있다.',
    ('-' * 78)
)

($header + $rows) | Set-Content $out -Encoding UTF8

Write-Host "정리 완료: $out"
Write-Host "발화 $($rows.Count)건"
Write-Host ''
Write-Host '── 판 관련 발화만 미리보기 ───────────────────────────'
$rows | Where-Object { $_ -match '바둑판|좌표|줄 판|착수|흑|백|빈 점|화점|둘 수 없' } |
    Select-Object -First 25 | ForEach-Object { "  $_" }
