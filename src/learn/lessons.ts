export interface LessonStep {
  title: string
  body: string
  boardHint?: string
}

export interface Lesson {
  id: string
  title: string
  steps: LessonStep[]
}

export const LESSONS: Lesson[] = [
  {
    id: 'basics',
    title: '1. 바둑판과 돌',
    steps: [
      {
        title: '바둑판',
        body: '가로·세로 선이 만나는 교차점에 돌을 둡니다. 9줄·13줄·19줄 판을 고를 수 있습니다. 저시력 모드에서는 교차점이 크게 깜빡여 착수 위치를 알려 줍니다.',
        boardHint: '교차점 = 착수점',
      },
      {
        title: '흑이 먼저',
        body: '흑이 먼저 두고, 백이 이어서 둡니다. 한 점에는 한 개의 돌만 둘 수 있습니다.',
        boardHint: '흑 → 백 → 흑 …',
      },
      {
        title: '활로(자유점)',
        body: '돌의 상하좌우 빈 교차점을 활로라고 합니다. 활로가 모두 막히면 돌은 잡혀 들어갑니다(따냄).',
        boardHint: '활로 0 = 따냄',
      },
    ],
  },
  {
    id: 'capture',
    title: '2. 따내기',
    steps: [
      {
        title: '한 점 따내기',
        body: '상대 돌의 활로를 모두 막으면 그 돌을 따냅니다. 따낸 돌은 판에서 제거되고 포획 수에 더해집니다.',
      },
      {
        title: '연결',
        body: '같은 색 돌이 상하좌우로 붙으면 하나의 덩어리(그룹)가 됩니다. 그룹은 활로를 공유합니다.',
      },
      {
        title: '자살수 금지',
        body: '자기 돌의 활로가 하나도 남지 않는 수는 둘 수 없습니다. 다만 그 수로 상대를 따내면 허용됩니다.',
      },
    ],
  },
  {
    id: 'ko',
    title: '3. 패(劫)',
    steps: [
      {
        title: '패란?',
        body: '한 점을 따낸 직후, 상대가 바로 그 자리를 되따내 무한 반복이 될 수 있습니다. 이를 막기 위해 바로 되따내기는 금지합니다(패의 규칙).',
      },
      {
        title: '패감',
        body: '패를 이기려면 다른 곳에 두어 상대가 응수하게 만든 뒤, 다시 패를 따냅니다.',
      },
    ],
  },
  {
    id: 'end',
    title: '4. 끝내기와 집',
    steps: [
      {
        title: '집',
        body: '자기 돌로 둘러싼 빈 점이 집입니다. 양쪽이 더 이상 이득이 없다고 생각하면 차례로 패스합니다.',
      },
      {
        title: '두 번 패스',
        body: '흑·백이 연속으로 패스하면 대국이 끝납니다. (정식 계가는 이후 버전에서 보강)',
      },
    ],
  },
]
