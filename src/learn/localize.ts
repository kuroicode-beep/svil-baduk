import type { Lang } from '../i18n/dict'
import { LESSONS, type Lesson } from './lessons'
import { PUZZLES, type Puzzle } from './puzzles'

type LessonPack = Record<string, { title: string; steps: { title: string; body: string; boardHint?: string }[] }>
type PuzzlePack = Record<string, { title: string; goalLabel: string; hint: string }>

const LESSON_EN: LessonPack = {
  basics: {
    title: '1. Board and stones',
    steps: [
      {
        title: 'The board',
        body: 'Place stones on intersections where lines meet. Choose 9×9, 13×13, or 19×19. In low-vision mode, legal points blink larger.',
        boardHint: 'Intersection = place to play',
      },
      {
        title: 'Black plays first',
        body: 'Black moves first, then White. Only one stone per intersection.',
        boardHint: 'Black → White → Black …',
      },
      {
        title: 'Liberties',
        body: 'Empty adjacent intersections (up/down/left/right) are liberties. When a group has no liberties, it is captured.',
        boardHint: '0 liberties = capture',
      },
    ],
  },
  capture: {
    title: '2. Capturing',
    steps: [
      {
        title: 'Capturing one stone',
        body: 'Fill all liberties of an opponent stone to capture it. Captured stones leave the board and add to your captive count.',
      },
      {
        title: 'Connections',
        body: 'Same-color stones that touch orthogonally form a group and share liberties.',
      },
      {
        title: 'No suicide',
        body: 'You may not play a move that leaves your own group with zero liberties, unless that move captures the opponent.',
      },
    ],
  },
  ko: {
    title: '3. Ko',
    steps: [
      {
        title: 'What is ko?',
        body: 'After a single-stone capture, an immediate recapture that loops forever is forbidden (the ko rule).',
      },
      {
        title: 'Ko threats',
        body: 'To win a ko, play elsewhere so the opponent must answer, then take the ko back.',
      },
    ],
  },
  end: {
    title: '4. Endgame and territory',
    steps: [
      {
        title: 'Territory',
        body: 'Empty points surrounded by your stones are territory. When neither side gains, both pass.',
      },
      {
        title: 'Two passes',
        body: 'Consecutive passes by Black and White end the game. (Formal scoring rules may be refined later.)',
      },
    ],
  },
}

const PUZZLE_EN: PuzzlePack = {
  'cap-corner': {
    title: 'Capture 1 — near the corner',
    goalLabel: 'Goal: capture the White stone',
    hint: 'Block White’s last liberty (to the right).',
  },
  'cap-side': {
    title: 'Capture 2 — on the side',
    goalLabel: 'Goal: capture the White stone',
    hint: 'The empty point above White is the last liberty.',
  },
  'cap-two': {
    title: 'Capture 3 — two stones',
    goalLabel: 'Goal: capture two White stones',
    hint: 'Fill the empty point in the White group.',
  },
  atari: {
    title: 'Capture 4 — atari',
    goalLabel: 'Goal: capture White in atari',
    hint: 'White has only one liberty. Play there.',
  },
  'cap-edge': {
    title: 'Capture 5 — on the edge',
    goalLabel: 'Goal: capture the White stone',
    hint: 'Block White’s liberty below.',
  },
}

const LESSON_JA: LessonPack = {
  basics: {
    title: '1. 盤と石',
    steps: [
      {
        title: '碁盤',
        body: '線が交わる点に石を置きます。9路・13路・19路を選べます。ロービジョンモードでは着手点が大きく点滅します。',
        boardHint: '交点 = 着手点',
      },
      {
        title: '黒番から',
        body: '黒が先手、白が後手です。一つの交点に石は一つだけ置けます。',
        boardHint: '黒 → 白 → 黒 …',
      },
      {
        title: '呼吸点（ダメ）',
        body: '石の上下左右の空き点が呼吸点です。呼吸点がゼロになると取れます。',
        boardHint: 'ダメ0 = 取り',
      },
    ],
  },
  capture: {
    title: '2. 取り',
    steps: [
      { title: '一子取り', body: '相手の石の呼吸点をすべて塞ぐとその石を取ります。取った石は盤外へ出てアゲハマになります。' },
      { title: '連結', body: '同じ色の石が上下左右で接すると一つの連になり、呼吸点を共有します。' },
      { title: '自殺手禁止', body: '自分の連の呼吸点がゼロになる着手はできません。ただしそれで相手を取れる場合は可です。' },
    ],
  },
  ko: {
    title: '3. コウ',
    steps: [
      { title: 'コウとは', body: '一子を取った直後に同じ点を取り返し無限に繰り返すのを防ぐため、即座の取り返しは禁止です。' },
      { title: 'コウ材', body: 'コウを勝つには他に打って相手に応じさせ、その後コウを取り返します。' },
    ],
  },
  end: {
    title: '4. 終局と地',
    steps: [
      { title: '地', body: '自分の石で囲んだ空き点が地です。双方に得がないと思えばパスします。' },
      { title: '二回パス', body: '黒白が連続でパスすると終局です。（正式な計算法は今後強化）' },
    ],
  },
}

const LESSON_ZH: LessonPack = {
  basics: {
    title: '1. 棋盘与棋子',
    steps: [
      {
        title: '棋盘',
        body: '在线条交叉点落子。可选 9/13/19 路。低视力模式下，可落子点会明显闪烁。',
        boardHint: '交叉点 = 落子点',
      },
      {
        title: '黑先',
        body: '黑棋先行，白棋后行。每个交叉点只能有一子。',
        boardHint: '黑 → 白 → 黑 …',
      },
      {
        title: '气',
        body: '棋子上下左右的空交叉点叫气。气数为零则被提掉。',
        boardHint: '气 0 = 提子',
      },
    ],
  },
  capture: {
    title: '2. 提子',
    steps: [
      { title: '提一子', body: '堵住对方棋子的所有气即可提掉，提子离开棋盘并计入提子数。' },
      { title: '连接', body: '同色棋子上下左右相连成为一个块，共享气。' },
      { title: '禁止自杀', body: '不能下出导致己方没气的棋，除非同时提掉对方。' },
    ],
  },
  ko: {
    title: '3. 劫',
    steps: [
      { title: '什么是劫', body: '提一子后立刻在同点反提会造成无限循环，因此禁止立即回提（劫）。' },
      { title: '劫材', body: '要赢劫，先在别处下手迫使对方应对，再回头提劫。' },
    ],
  },
  end: {
    title: '4. 终局与目',
    steps: [
      { title: '目', body: '被己方棋子围住的空点是目。双方都无利可图时依次停着。' },
      { title: '两手停着', body: '黑白连续停着则终局。（正式点目规则后续加强）' },
    ],
  },
}

const LESSON_VI: LessonPack = {
  basics: {
    title: '1. Bàn và quân',
    steps: [
      {
        title: 'Bàn cờ',
        body: 'Đặt quân tại giao điểm. Chọn 9/13/19. Ở chế độ khiếm thị, điểm hợp lệ nhấp nháy lớn hơn.',
        boardHint: 'Giao điểm = chỗ đánh',
      },
      {
        title: 'Đen đi trước',
        body: 'Đen trước, Trắng sau. Mỗi giao điểm chỉ một quân.',
        boardHint: 'Đen → Trắng → Đen …',
      },
      {
        title: 'Khí',
        body: 'Các ô trống trên-dưới-trái-phải là khí. Hết khí thì bị bắt.',
        boardHint: '0 khí = bắt',
      },
    ],
  },
  capture: {
    title: '2. Bắt quân',
    steps: [
      { title: 'Bắt một quân', body: 'Chặn hết khí của đối phương để bắt. Quân bị bắt rời bàn và tính vào số bắt.' },
      { title: 'Liên kết', body: 'Quân cùng màu chạm nhau theo cạnh tạo nhóm và chia sẻ khí.' },
      { title: 'Cấm tự sát', body: 'Không được đánh nước làm nhóm mình hết khí, trừ khi đồng thời bắt đối phương.' },
    ],
  },
  ko: {
    title: '3. Ko',
    steps: [
      { title: 'Ko là gì?', body: 'Sau khi bắt một quân, cấm bắt lại ngay cùng điểm để tránh lặp vô hạn.' },
      { title: 'Đe dọa ko', body: 'Muốn thắng ko, đánh chỗ khác buộc đối phương trả lời rồi mới bắt lại.' },
    ],
  },
  end: {
    title: '4. Kết thúc và đất',
    steps: [
      { title: 'Đất', body: 'Ô trống bị quân mình bao quanh là đất. Khi không còn lợi thì lần lượt bỏ lượt.' },
      { title: 'Hai lần bỏ lượt', body: 'Đen và Trắng bỏ lượt liên tiếp thì ván kết thúc.' },
    ],
  },
}

const PUZZLE_JA: PuzzlePack = {
  'cap-corner': { title: '取り1 — 隅付近', goalLabel: '目標: 白を取る', hint: '白の最後のダメ（右）を塞ぎます。' },
  'cap-side': { title: '取り2 — 辺', goalLabel: '目標: 白を取る', hint: '白の上の空きが最後のダメです。' },
  'cap-two': { title: '取り3 — 二子', goalLabel: '目標: 白二子を取る', hint: '白連の空きを埋めます。' },
  atari: { title: '取り4 — アタリ', goalLabel: '目標: アタリの白を取る', hint: '白のダメは一つです。' },
  'cap-edge': { title: '取り5 — 辺で取る', goalLabel: '目標: 白を取る', hint: '白の下のダメを塞ぎます。' },
}

const PUZZLE_ZH: PuzzlePack = {
  'cap-corner': { title: '提子1 — 角附近', goalLabel: '目标：提白子', hint: '堵住白棋最后一口气（右侧）。' },
  'cap-side': { title: '提子2 — 边上', goalLabel: '目标：提白子', hint: '白棋上方空点是最后一口气。' },
  'cap-two': { title: '提子3 — 两子', goalLabel: '目标：提两白子', hint: '填上白块里的空点。' },
  atari: { title: '提子4 — 打吃', goalLabel: '目标：提被打吃的白', hint: '白棋只剩一口气。' },
  'cap-edge': { title: '提子5 — 边上提', goalLabel: '目标：提白子', hint: '堵住白棋下方的气。' },
}

const PUZZLE_VI: PuzzlePack = {
  'cap-corner': { title: 'Bắt 1 — gần góc', goalLabel: 'Mục tiêu: bắt quân Trắng', hint: 'Chặn khí cuối của Trắng (bên phải).' },
  'cap-side': { title: 'Bắt 2 — cạnh bàn', goalLabel: 'Mục tiêu: bắt quân Trắng', hint: 'Ô trống phía trên là khí cuối.' },
  'cap-two': { title: 'Bắt 3 — hai quân', goalLabel: 'Mục tiêu: bắt hai quân Trắng', hint: 'Lấp ô trống trong nhóm Trắng.' },
  atari: { title: 'Bắt 4 — chiếu', goalLabel: 'Mục tiêu: bắt Trắng đang chiếu', hint: 'Trắng chỉ còn một khí.' },
  'cap-edge': { title: 'Bắt 5 — ở cạnh', goalLabel: 'Mục tiêu: bắt quân Trắng', hint: 'Chặn khí phía dưới của Trắng.' },
}

function pickLessonPack(lang: Lang): LessonPack | null {
  if (lang === 'en') return LESSON_EN
  if (lang === 'ja') return LESSON_JA
  if (lang === 'zh') return LESSON_ZH
  if (lang === 'vi') return LESSON_VI
  return null
}

function pickPuzzlePack(lang: Lang): PuzzlePack | null {
  if (lang === 'en') return PUZZLE_EN
  if (lang === 'ja') return PUZZLE_JA
  if (lang === 'zh') return PUZZLE_ZH
  if (lang === 'vi') return PUZZLE_VI
  return null
}

export function lessonsFor(lang: Lang): Lesson[] {
  const pack = pickLessonPack(lang)
  if (!pack) return LESSONS
  return LESSONS.map((lesson) => {
    const loc = pack[lesson.id]
    if (!loc) return lesson
    return {
      ...lesson,
      title: loc.title,
      steps: lesson.steps.map((step, i) => ({
        ...step,
        title: loc.steps[i]?.title ?? step.title,
        body: loc.steps[i]?.body ?? step.body,
        boardHint: loc.steps[i]?.boardHint ?? step.boardHint,
      })),
    }
  })
}

export function puzzlesFor(lang: Lang): Puzzle[] {
  const pack = pickPuzzlePack(lang)
  if (!pack) return PUZZLES
  return PUZZLES.map((p) => {
    const loc = pack[p.id]
    if (!loc) return p
    return { ...p, ...loc }
  })
}
