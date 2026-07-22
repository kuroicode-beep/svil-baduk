export type Lang = 'ko' | 'en' | 'ja' | 'zh' | 'vi'

export const LANG_LABELS: Record<Lang, string> = {
  ko: '한국어',
  en: 'English',
  ja: '日本語',
  zh: '中文',
  vi: 'Tiếng Việt',
}

const dict = {
  appTitle: {
    ko: 'SVIL Baduk',
    en: 'SVIL Baduk',
    ja: 'SVIL Baduk',
    zh: 'SVIL Baduk',
    vi: 'SVIL Baduk',
  },
  tagline: {
    ko: '저시력자를 위한 고대비 바둑',
    en: 'High-contrast Go for low vision',
    ja: 'ロービジョン向けハイコントラスト囲碁',
    zh: '为低视力者设计的高对比围棋',
    vi: 'Cờ vây tương phản cao cho người khiếm thị',
  },
  learn: { ko: '단계별 배우기', en: 'Learn step by step', ja: '段階学習', zh: '分步学习', vi: 'Học từng bước' },
  solo: { ko: '혼자서 두기', en: 'Play alone', ja: 'ひとりで打つ', zh: '单人对弈', vi: 'Chơi một mình' },
  multi: { ko: '상대랑 두기', en: 'Play with friend', ja: '対戦', zh: '联机对弈', vi: 'Chơi với bạn' },
  settings: { ko: '설정', en: 'Settings', ja: '設定', zh: '设置', vi: 'Cài đặt' },
  back: { ko: '뒤로', en: 'Back', ja: '戻る', zh: '返回', vi: 'Quay lại' },
  pass: { ko: '패스', en: 'Pass', ja: 'パス', zh: '停着', vi: 'Bỏ lượt' },
  resign: { ko: '기권', en: 'Resign', ja: '投了', zh: '认输', vi: 'Bỏ cuộc' },
  yourTurn: { ko: '당신 차례', en: 'Your turn', ja: 'あなたの番', zh: '轮到你', vi: 'Lượt của bạn' },
  aiTurn: { ko: 'AI 생각 중…', en: 'AI thinking…', ja: 'AI思考中…', zh: 'AI思考中…', vi: 'AI đang nghĩ…' },
  black: { ko: '흑', en: 'Black', ja: '黒', zh: '黑', vi: 'Đen' },
  white: { ko: '백', en: 'White', ja: '白', zh: '白', vi: 'Trắng' },
  captures: { ko: '딴 돌', en: 'Captures', ja: 'アゲハマ', zh: '提子', vi: 'Quân bắt' },
  boardSize: { ko: '판 크기', en: 'Board size', ja: '盤の大きさ', zh: '棋盘大小', vi: 'Cỡ bàn' },
  rank: { ko: '상대 급수/단수', en: 'Opponent rank', ja: '相手の級・段', zh: '对手段级', vi: 'Cấp đối thủ' },
  startGame: { ko: '대국 시작', en: 'Start game', ja: '対局開始', zh: '开始对局', vi: 'Bắt đầu' },
  playAs: { ko: '내 색깔', en: 'My color', ja: '自分の色', zh: '我的颜色', vi: 'Màu của tôi' },
  blinkHelp: {
    ko: '착수 가능 교차점이 깜빡입니다. Tab으로 이동, Enter로 둡니다.',
    en: 'Legal intersections blink. Tab to move, Enter to place.',
    ja: '着手可能な交点が点滅します。Tabで移動、Enterで着手。',
    zh: '可落子交叉点会闪烁。Tab移动，Enter落子。',
    vi: 'Điểm hợp lệ nhấp nháy. Tab để chọn, Enter để đánh.',
  },
  hostRoom: { ko: '방 만들기', en: 'Create room', ja: '部屋を作る', zh: '创建房间', vi: 'Tạo phòng' },
  joinRoom: { ko: '방 참가', en: 'Join room', ja: '部屋に入る', zh: '加入房间', vi: 'Vào phòng' },
  yourId: { ko: '내 방 ID', en: 'My room ID', ja: '自分の部屋ID', zh: '我的房间ID', vi: 'ID phòng của tôi' },
  peerId: { ko: '상대 방 ID', en: 'Friend room ID', ja: '相手の部屋ID', zh: '对方房间ID', vi: 'ID phòng bạn' },
  copyId: { ko: 'ID 복사', en: 'Copy ID', ja: 'IDをコピー', zh: '复制ID', vi: 'Sao chép ID' },
  waiting: { ko: '상대 연결 대기 중…', en: 'Waiting for friend…', ja: '相手の接続待ち…', zh: '等待对手连接…', vi: 'Đang chờ bạn…' },
  connected: { ko: '연결됨', en: 'Connected', ja: '接続済み', zh: '已连接', vi: 'Đã kết nối' },
  font: { ko: '글꼴', en: 'Font', ja: 'フォント', zh: '字体', vi: 'Phông chữ' },
  fontSize: { ko: '글자 크기', en: 'Text size', ja: '文字サイズ', zh: '文字大小', vi: 'Cỡ chữ' },
  language: { ko: '언어', en: 'Language', ja: '言語', zh: '语言', vi: 'Ngôn ngữ' },
  history: { ko: '히스토리', en: 'History', ja: '履歴', zh: '更新历史', vi: 'Lịch sử' },
  sizeSmall: { ko: '작음', en: 'Small', ja: '小', zh: '小', vi: 'Nhỏ' },
  sizeMedium: { ko: '보통', en: 'Medium', ja: '中', zh: '中', vi: 'Vừa' },
  sizeLarge: { ko: '큼', en: 'Large', ja: '大', zh: '大', vi: 'Lớn' },
  blinkOn: { ko: '착수점 깜빡임: 켜짐', en: 'Intersection blink: On', ja: '交点点滅: オン', zh: '交叉点闪烁: 开', vi: 'Nhấp nháy: Bật' },
  blinkOff: { ko: '착수점 깜빡임: 꺼짐', en: 'Intersection blink: Off', ja: '交点点滅: オフ', zh: '交叉点闪烁: 关', vi: 'Nhấp nháy: Tắt' },
  highContrast: { ko: '최대 대비 보드', en: 'Max contrast board', ja: '最大コントラスト盤', zh: '最大对比棋盘', vi: 'Bàn tương phản tối đa' },
  next: { ko: '다음', en: 'Next', ja: '次へ', zh: '下一步', vi: 'Tiếp' },
  prev: { ko: '이전', en: 'Previous', ja: '前へ', zh: '上一步', vi: 'Trước' },
  lessonDone: { ko: '학습 완료 — 혼자서 두기로 연습해 보세요', en: 'Lesson done — try Play alone', ja: '学習完了 — ひとり対局で練習', zh: '学习完成 — 试试单人对弈', vi: 'Xong bài — thử chơi một mình' },
  gameOver: { ko: '대국 종료', en: 'Game over', ja: '終局', zh: '终局', vi: 'Kết thúc' },
  katagoStatus: { ko: 'KataGo', en: 'KataGo', ja: 'KataGo', zh: 'KataGo', vi: 'KataGo' },
  katagoOff: { ko: '내장 AI (KataGo 미연결)', en: 'Built-in AI (KataGo offline)', ja: '内蔵AI（KataGo未接続）', zh: '内置AI（未连接KataGo）', vi: 'AI tích hợp (chưa KataGo)' },
  illegal: { ko: '둘 수 없는 자리입니다', en: 'Illegal move', ja: '禁じ手です', zh: '非法落子', vi: 'Nước đi không hợp lệ' },
  lastMove: { ko: '직전 수', en: 'Last move', ja: '直前の手', zh: '上一手', vi: 'Nước vừa rồi' },
} as const

export type DictKey = keyof typeof dict

export function t(lang: Lang, key: DictKey): string {
  return dict[key][lang]
}
