// lib/i18n/strings.g.dart — 5개 언어 문자열
//
// 자동 생성 파일. 손으로 고치지 말 것.
// 원본: src/i18n/dict.ts · 생성: npm run i18n:export

enum Lang {
  ko('ko'),
  en('en'),
  ja('ja'),
  zh('zh'),
  vi('vi');

  const Lang(this.code);
  final String code;

  static Lang fromCode(String c) =>
      Lang.values.firstWhere((Lang l) => l.code == c, orElse: () => Lang.ko);
}

const Map<Lang, String> langLabels = <Lang, String>{
  Lang.ko: '한국어',
  Lang.en: 'English',
  Lang.ja: '日本語',
  Lang.zh: '中文',
  Lang.vi: 'Tiếng Việt',
};

/// 문자열 하나 — 언어별 값을 모두 갖는다
class LocString {
  const LocString(this.ko, this.en, this.ja, this.zh, this.vi);
  final String ko;
  final String en;
  final String ja;
  final String zh;
  final String vi;

  String call(Lang l) => switch (l) {
        Lang.ko => ko,
        Lang.en => en,
        Lang.ja => ja,
        Lang.zh => zh,
        Lang.vi => vi,
      };
}

/// 모든 문자열. 오타는 컴파일 오류가 된다.
abstract final class S {
  static const LocString appTitle = LocString("SVIL Baduk", "SVIL Baduk", "SVIL Baduk", "SVIL Baduk", "SVIL Baduk");
  static const LocString tagline = LocString("저시력자를 위한 고대비 바둑", "High-contrast Go for low vision", "ロービジョン向けハイコントラスト囲碁", "为低视力者设计的高对比围棋", "Cờ vây tương phản cao cho người khiếm thị");
  static const LocString learn = LocString("단계별 배우기", "Learn step by step", "段階学習", "分步学习", "Học từng bước");
  static const LocString learnBasics = LocString("기본 배우기", "Basics", "基礎", "基础", "Cơ bản");
  static const LocString learnFuseki = LocString("포석 배우기", "Openings", "布石", "布局", "Khai cục");
  static const LocString learnTsumego = LocString("사활 문제", "Life & death", "死活", "死活", "Sống chết");
  static const LocString learnStages = LocString("스테이지 목록", "Stages", "ステージ一覧", "关卡列表", "Danh sách màn");
  static const LocString learnTrackProgress = LocString("클리어", "Cleared", "クリア", "已通关", "Đã xong");
  static const LocString learnStageCleared = LocString("이 스테이지를 모두 클리어했습니다!", "Stage cleared!", "ステージクリア！", "本关已全部通关！", "Đã hoàn thành màn này!");
  static const LocString learnShowAnswer = LocString("정답 보기", "Show answer", "正解を見る", "查看答案", "Xem đáp án");
  static const LocString learnRetry = LocString("다시 시도", "Retry", "やり直す", "重试", "Thử lại");
  static const LocString learnCurriculumNote = LocString("유명한 입문 교재의 학습 순서를 참고한 오리지널 문제입니다(복제 아님). 스테이지를 순서대로 클리어하세요.", "Original drills inspired by classic beginner books (not copies). Clear stages in order.", "古典入門書の順序を参考にしたオリジナル問題です。ステージを順にクリアしてください。", "参考经典入门书顺序的原创题（非抄录）。请按关卡顺序通关。", "Bài tập gốc theo thứ tự sách nhập môn kinh điển. Hãy vượt màn theo thứ tự.");
  static const LocString solo = LocString("AI와 겨루기", "Play vs AI", "AIと対局", "与AI对弈", "Đấu với AI");
  static const LocString soloLead = LocString("난이도 1~10을 고르고 인공지능과 대국합니다", "Pick difficulty 1–10 and play against the AI", "難易度1〜10を選んでAIと対局", "选择难度1–10后与AI对局", "Chọn độ khó 1–10 và đấu với AI");
  static const LocString difficulty = LocString("난이도", "Difficulty", "難易度", "难度", "Độ khó");
  static const LocString opponentSummary = LocString("상대 AI", "AI opponent", "AI相手", "AI对手", "Đối thủ AI");
  static const LocString multi = LocString("상대랑 두기", "Play with friend", "対戦", "联机对弈", "Chơi với bạn");
  static const LocString settings = LocString("설정", "Settings", "設定", "设置", "Cài đặt");
  static const LocString profile = LocString("내 캐릭터", "My character", "マイキャラ", "我的角色", "Nhân vật");
  static const LocString profileLead = LocString("이름을 정하고 캐릭터를 만들면 대국 전적·레벨이 쌓입니다", "Create a character to track level, record, and high score", "キャラを作るとレベルと戦績が記録されます", "创建角色后可记录等级与战绩", "Tạo nhân vật để lưu cấp độ và thành tích");
  static const LocString profileName = LocString("이름", "Name", "名前", "名字", "Tên");
  static const LocString profileNamePlaceholder = LocString("예: 바둑이", "e.g. Baduk", "例: 碁好き", "例如：棋友", "VD: Baduk");
  static const LocString profileNameRequired = LocString("이름을 입력하세요", "Please enter a name", "名前を入力してください", "请输入名字", "Hãy nhập tên");
  static const LocString profileNameTooLong = LocString("이름은 20자 이내입니다", "Name must be 20 characters or fewer", "名前は20文字以内", "名字最多20字", "Tên tối đa 20 ký tự");
  static const LocString profileAvatar = LocString("상징", "Symbol", "シンボル", "象征", "Biểu tượng");
  static const LocString profileCreate = LocString("캐릭터 만들기", "Create character", "キャラ作成", "创建角色", "Tạo nhân vật");
  static const LocString profileSave = LocString("저장", "Save", "保存", "保存", "Lưu");
  static const LocString profileCreated = LocString("캐릭터를 만들었습니다", "Character created", "キャラを作成しました", "已创建角色", "Đã tạo nhân vật");
  static const LocString profileSaved = LocString("저장했습니다", "Saved", "保存しました", "已保存", "Đã lưu");
  static const LocString profileLevel = LocString("레벨", "Level", "レベル", "等级", "Cấp");
  static const LocString profileXp = LocString("경험치", "XP", "経験値", "经验", "XP");
  static const LocString profileRecord = LocString("전적", "Record", "戦績", "战绩", "Thành tích");
  static const LocString profileHighScore = LocString("최고 점수", "High score", "最高スコア", "最高分", "Điểm cao nhất");
  static const LocString profileBestAi = LocString("최고 격파 난이도", "Hardest AI beaten", "最高撃破難易度", "最高击败难度", "Độ khó AI đã thắng");
  static const LocString profileLevelUp = LocString("레벨 업!", "Level up!", "レベルアップ!", "升级！", "Lên cấp!");
  static const LocString profileXpGain = LocString("경험치", "XP gained", "経験値獲得", "获得经验", "Nhận XP");
  static const LocString profileNewHigh = LocString("최고 점수 갱신!", "New high score!", "ハイスコア更新!", "最高分更新！", "Kỷ lục mới!");
  static const LocString profileNeedChar = LocString("전적을 남기려면 먼저 캐릭터를 만드세요", "Create a character to keep your record", "戦績を残すにはキャラを作成", "请先创建角色以记录战绩", "Tạo nhân vật để lưu thành tích");
  static const LocString back = LocString("뒤로", "Back", "戻る", "返回", "Quay lại");
  static const LocString home = LocString("홈", "Home", "ホーム", "主页", "Trang chủ");
  static const LocString confirm = LocString("확인", "Confirm", "確認", "确认", "Xác nhận");
  static const LocString on = LocString("켬", "On", "オン", "开", "Bật");
  static const LocString katagoMobileUnavailable = LocString("이 기기에서는 KataGo를 쓸 수 없습니다. 내장 AI로 대국합니다.", "KataGo is not available on this device. Playing with the built-in AI.", "この端末ではKataGoを使えません。内蔵AIで対局します。", "此设备无法使用 KataGo，将使用内置 AI 对局。", "Thiết bị này không dùng được KataGo. Sẽ chơi với AI tích hợp.");
  static const LocString starPoint = LocString("화점", "star point", "星", "星位", "điểm sao");
  static const LocString liberties = LocString("활로", "liberties", "呼吸点", "气", "khí");
  static const LocString turnSuffix = LocString("차례", "to play", "番", "行棋", "lượt");
  static const LocString capturedSuffix = LocString("점 따냄", "captured", "子アゲ", "子被提", "quân bị bắt");
  static const LocString stoneCountSuffix = LocString("점", "stones", "子", "子", "quân");
  static const LocString noStones = LocString("돌 없음", "no stones", "石なし", "无子", "không có quân");
  static const LocString rowSuffix = LocString("줄", "line", "路", "路", "dòng");
  static const LocString noLastMove = LocString("직전 수 없음", "no last move", "直前の手なし", "无上一手", "chưa có nước đi");
  static const LocString territoryLabel = LocString("집", "territory", "地", "目", "đất");
  static const LocString komiLabel = LocString("덤", "komi", "コミ", "贴目", "komi");
  static const LocString winsBy = LocString("집 승", " wins by", "目勝ち", "目胜", " thắng");
  static const LocString drawResult = LocString("무승부", "draw", "引き分け", "和棋", "hòa");
  static const LocString scoreEstimate = LocString("추정", "estimate", "推定", "估算", "ước tính");
  static const LocString hintLabel = LocString("추천", "hint", "候補", "推荐", "gợi ý");
  static const LocString undoneLabel = LocString("무름", "undone", "取り消し", "悔棋", "đã hoàn tác");
  static const LocString scoreRulesJapanese = LocString("일본룰 (집계법)", "Japanese (territory)", "日本ルール", "日本规则", "Luật Nhật");
  static const LocString scoreRulesChinese = LocString("중국룰 (영역법)", "Chinese (area)", "中国ルール", "中国规则", "Luật Trung");
  static const LocString scoreDeadStonesNote = LocString("사석을 자동으로 가려내지 못합니다. 죽은 돌이 판에 남아 있으면 결과가 달라집니다.", "Dead stones are not detected. If dead stones remain on the board the result will differ.", "死に石は自動判定しません。盤上に残っていると結果が変わります。", "不会自动判定死子。若死子仍在盘上，结果会有出入。", "Không tự nhận diện quân chết. Nếu quân chết còn trên bàn, kết quả sẽ khác.");
  static const LocString snapshotCorrupt = LocString("저장 파일이 손상되었습니다", "The saved file is damaged", "保存ファイルが壊れています", "存档已损坏", "Tệp lưu bị hỏng");
  static const LocString snapshotTooNew = LocString("더 새로운 버전에서 저장된 파일입니다", "Saved by a newer version", "新しいバージョンで保存されています", "由更新版本保存", "Được lưu bởi phiên bản mới hơn");
  static const LocString snapshotBadSize = LocString("지원하지 않는 판 크기입니다", "Unsupported board size", "対応していない盤サイズです", "不支持的棋盘大小", "Kích thước bàn không hỗ trợ");
  static const LocString snapshotReplayFailed = LocString("수순을 재생할 수 없습니다", "The move list could not be replayed", "手順を再生できません", "无法重放棋谱", "Không thể phát lại nước đi");
  static const LocString sgfNotSgf = LocString("SGF 파일이 아닙니다", "Not an SGF file", "SGFファイルではありません", "不是 SGF 文件", "Không phải tệp SGF");
  static const LocString sgfUnsupportedSize = LocString("지원하지 않는 판 크기입니다", "Unsupported board size", "対応していない盤サイズです", "不支持的棋盘大小", "Kích thước bàn không hỗ trợ");
  static const LocString sgfTurnMismatch = LocString("차례가 맞지 않습니다", "Move order does not alternate", "手番が合いません", "落子顺序不符", "Thứ tự đi không khớp");
  static const LocString sgfBadCoord = LocString("좌표를 읽을 수 없습니다", "Could not read a coordinate", "座標を読めません", "无法读取坐标", "Không đọc được tọa độ");
  static const LocString sgfIllegalMove = LocString("규칙에 어긋나는 수가 있습니다", "The file contains an illegal move", "ルール違反の手があります", "含有违规着法", "Có nước đi phạm luật");
  static const LocString boardLabel = LocString("바둑판", "board", "碁盤", "棋盘", "bàn cờ");
  static const LocString boardHint = LocString("화살표로 이동, 엔터로 착수, 물음표로 판 요약. 좌표 입력칸에 D16처럼 직접 칠 수도 있습니다", "Arrows move, Enter plays, ? summarises the board. You can also type a coordinate like D16.", "矢印で移動、エンターで着手、?で盤面要約。座標欄にD16のように入力もできます", "方向键移动，回车落子，? 查看棋盘摘要。也可在坐标框输入 D16。", "Mũi tên di chuyển, Enter đặt quân, ? tóm tắt bàn cờ. Cũng có thể gõ toạ độ như D16.");
  static const LocString coordInputLabel = LocString("좌표 입력", "Coordinate", "座標入力", "坐标输入", "Toạ độ");
  static const LocString coordInputHint = LocString("예: D16, 패스, ?", "e.g. D16, pass, ?", "例: D16、パス、?", "例：D16、停着、?", "VD: D16, bỏ lượt, ?");
  static const LocString coordInputHelper = LocString("엔터로 착수. ? 판 요약, ?D16 그 지점, ?16 그 줄, r 다시 듣기", "Enter to play. ? board summary, ?D16 that point, ?16 that line, r repeat", "エンターで着手。? 盤面要約、?D16 その点、?16 その路、r 再読", "回车落子。? 棋盘摘要，?D16 该点，?16 该路，r 重复", "Enter để đi. ? tóm tắt, ?D16 điểm đó, ?16 dòng đó, r nhắc lại");
  static const LocString errOccupied = LocString("둘 수 없음: 이미 돌이 있습니다", "illegal: already occupied", "着手不可: すでに石があります", "无法落子：该处已有子", "không hợp lệ: đã có quân");
  static const LocString errKo = LocString("둘 수 없음: 패입니다", "illegal: ko", "着手不可: コウです", "无法落子：打劫", "không hợp lệ: kiếp");
  static const LocString errSuperko = LocString("둘 수 없음: 같은 판이 반복됩니다", "illegal: repeats a position", "着手不可: 同形反復です", "无法落子：同形再现", "không hợp lệ: lặp thế cờ");
  static const LocString errSuicide = LocString("둘 수 없음: 자살수입니다", "illegal: suicide", "着手不可: 自殺手です", "无法落子：自杀手", "không hợp lệ: tự sát");
  static const LocString errGameEnded = LocString("대국이 끝났습니다", "the game has ended", "対局は終了しました", "对局已结束", "ván cờ đã kết thúc");
  static const LocString errOutOfBounds = LocString("판 밖입니다", "off the board", "盤外です", "棋盘之外", "ngoài bàn cờ");
  static const LocString errSkippedLetter = LocString("I 는 쓰지 않습니다. H 다음은 J 입니다", "the letter I is not used; H is followed by J", "I は使いません。H の次は J です", "不使用字母 I，H 之后是 J", "không dùng chữ I; sau H là J");
  static const LocString errBadColumn = LocString("없는 열입니다", "no such column", "存在しない列です", "没有该列", "không có cột đó");
  static const LocString errBadRow = LocString("범위 밖입니다", "out of range", "範囲外です", "超出范围", "ngoài phạm vi");
  static const LocString errEmptyInput = LocString("입력이 비어 있습니다", "the input is empty", "入力が空です", "输入为空", "chưa nhập gì");
  static const LocString errUnknownInput = LocString("알 수 없습니다. 예: D16, 패스, 물음표", "not recognised. e.g. D16, pass, ?", "認識できません。例: D16、パス、?", "无法识别。例：D16、停着、?", "không nhận ra. VD: D16, bỏ lượt, ?");
  static const LocString pointEmpty = LocString("빈 점", "empty", "空点", "空点", "điểm trống");
  static const LocString selectedPoint = LocString("선택됨", "selected", "選択中", "已选择", "đã chọn");
  static const LocString confirmPlace = LocString("착수 확정", "Place stone", "着手確定", "确认落子", "Đặt quân");
  static const LocString occupiedPoint = LocString("이미 돌이 있습니다", "A stone is already there", "すでに石があります", "该处已有棋子", "Đã có quân ở đó");
  static const LocString territoryBlack = LocString("흑집", "B", "黒地", "黑地", "Đất đen");
  static const LocString territoryWhite = LocString("백집", "W", "白地", "白地", "Đất trắng");
  static const LocString showCoords = LocString("좌표 눈금 표시", "Show coordinates", "座標を表示", "显示坐标", "Hiện tọa độ");
  static const LocString placeModeLabel = LocString("착수 방식", "Stone placement", "着手方法", "落子方式", "Cách đặt quân");
  static const LocString placeModeDirect = LocString("바로 두기", "Tap to play", "タップで着手", "点击即落子", "Chạm để đi");
  static const LocString placeModeConfirm = LocString("고른 뒤 확정 (오터치 방지)", "Select then confirm (avoids mis-taps)", "選んでから確定（誤タップ防止）", "先选择再确认（防误触）", "Chọn rồi xác nhận (tránh chạm nhầm)");
  static const LocString off = LocString("끔", "Off", "オフ", "关", "Tắt");
  static const LocString followSystem = LocString("시스템 설정 따름", "Follow system", "システム設定に従う", "跟随系统设置", "Theo hệ thống");
  static const LocString dataSection = LocString("데이터", "Data", "データ", "数据", "Dữ liệu");
  static const LocString exportData = LocString("내 데이터 내보내기", "Export my data", "データを書き出す", "导出我的数据", "Xuất dữ liệu");
  static const LocString importData = LocString("데이터 가져오기", "Import data", "データを読み込む", "导入数据", "Nhập dữ liệu");
  static const LocString backupNote = LocString("설정·내 캐릭터·배우기 진행을 파일 하나로 저장합니다. 진행 중인 대국은 포함되지 않습니다.", "Saves settings, profile and learning progress to one file. Games in progress are not included.", "設定・キャラクター・学習の進行を1つのファイルに保存します。進行中の対局は含まれません。", "将设置、角色与学习进度保存为一个文件。进行中的对局不包含在内。", "Lưu cài đặt, hồ sơ và tiến trình học vào một tệp. Ván đang chơi không được bao gồm.");
  static const LocString importFailedNotJson = LocString("가져오기 실패 — 파일을 읽을 수 없습니다.", "Import failed — the file could not be read.", "読み込み失敗 — ファイルを読めません。", "导入失败 — 无法读取文件。", "Nhập thất bại — không đọc được tệp.");
  static const LocString importFailedNotBackup = LocString("가져오기 실패 — SVIL Baduk 백업 파일이 아닙니다.", "Import failed — not an SVIL Baduk backup file.", "読み込み失敗 — SVIL Baduk のバックアップではありません。", "导入失败 — 不是 SVIL Baduk 备份文件。", "Nhập thất bại — không phải tệp sao lưu SVIL Baduk.");
  static const LocString importFailedVersion = LocString("가져오기 실패 — 더 새 버전에서 만든 백업입니다. 앱을 업데이트하세요.", "Import failed — the backup came from a newer version. Please update the app.", "読み込み失敗 — 新しいバージョンのバックアップです。アプリを更新してください。", "导入失败 — 该备份来自更新的版本，请先更新应用。", "Nhập thất bại — bản sao lưu từ phiên bản mới hơn. Hãy cập nhật ứng dụng.");
  static const LocString resetSettings = LocString("설정 초기화", "Reset settings", "設定を初期化", "重置设置", "Đặt lại cài đặt");
  static const LocString resetSettingsBody = LocString("모든 설정을 기본값으로 되돌립니다. 대국 기록과 학습 진행은 그대로 남습니다.", "Restores every setting to its default. Games and learning progress are kept.", "すべての設定を初期値に戻します。対局記録と学習の進行は残ります。", "将所有设置恢复为默认值。对局记录与学习进度会保留。", "Khôi phục mọi cài đặt về mặc định. Ván cờ và tiến trình học vẫn được giữ.");
  static const LocString cancel = LocString("취소", "Cancel", "キャンセル", "取消", "Hủy");
  static const LocString resignConfirmTitle = LocString("기권하시겠습니까?", "Resign this game?", "投了しますか？", "要认输吗？", "Xin thua ván này?");
  static const LocString resignConfirmBody = LocString("기권하면 이 대국은 즉시 끝나고 상대가 이깁니다. 되돌릴 수 없습니다.", "Resigning ends the game immediately and your opponent wins. This cannot be undone.", "投了すると対局はすぐ終わり、相手の勝ちになります。取り消せません。", "认输后对局立即结束，对手获胜。无法撤销。", "Xin thua sẽ kết thúc ván ngay và đối thủ thắng. Không thể hoàn tác.");
  static const LocString newGameConfirmTitle = LocString("새 대국을 시작할까요?", "Start a new game?", "新しい対局を始めますか？", "开始新对局？", "Bắt đầu ván mới?");
  static const LocString newGameConfirmBody = LocString("저장된 대국이 지워집니다. 이어하기를 쓰면 그대로 둘 수 있습니다.", "The saved game will be discarded. Use Resume to keep it.", "保存中の対局は消えます。「再開」を使えば残せます。", "已保存的对局将被清除。使用「继续」可保留。", "Ván đã lưu sẽ bị xóa. Dùng \"Tiếp tục\" để giữ lại.");
  static const LocString version = LocString("버전", "Version", "バージョン", "版本", "Phiên bản");
  static const LocString skipToMain = LocString("본문으로 건너뛰기", "Skip to main content", "本文へスキップ", "跳到主要内容", "Chuyển đến nội dung chính");
  static const LocString pass = LocString("패스", "Pass", "パス", "停着", "Bỏ lượt");
  static const LocString resign = LocString("기권", "Resign", "投了", "认输", "Bỏ cuộc");
  static const LocString scoreNow = LocString("계가", "Score", "計算", "点目", "Đếm điểm");
  static const LocString learnNoProblem = LocString("문제가 없습니다", "No problem loaded", "問題がありません", "没有题目", "Chưa có bài tập");
  static const LocString learnWrongPoint = LocString("그 자리가 아닙니다", "Not that point", "その場所ではありません", "不是这个点", "Không phải điểm đó");
  static const LocString learnIllegal = LocString("규칙에 어긋납니다", "That move is illegal", "ルール違反です", "这一手违规", "Nước đi phạm luật");
  static const LocString learnGoalUnmet = LocString("자리는 맞지만 목표를 이루지 못했습니다", "Right point, but the goal is not met", "場所は合っていますが目標を達成していません", "位置对了，但没有达成目标", "Đúng điểm nhưng chưa đạt mục tiêu");
  static const LocString learnCorrect = LocString("정답입니다", "Correct", "正解です", "正确", "Chính xác");
  static const LocString learnTrackCleared = LocString("이 과정을 모두 끝냈습니다", "Track complete", "このコースを修了しました", "本课程全部完成", "Hoàn thành toàn bộ khóa");
  static const LocString learnNextProblem = LocString("다음 문제", "Next problem", "次の問題", "下一题", "Bài tiếp theo");
  static const LocString learnPrevProblem = LocString("이전 문제", "Previous problem", "前の問題", "上一题", "Bài trước");
  static const LocString learnProgress = LocString("진행", "Progress", "進捗", "进度", "Tiến độ");
  static const LocString learnTryHint = LocString("두 번 틀렸습니다. 힌트를 들어보세요", "Two misses. Try the hint", "2回間違えました。ヒントを聞いてみてください", "错了两次，试试提示", "Sai hai lần. Hãy nghe gợi ý");
  static const LocString learnLocked = LocString("앞 단계를 먼저 끝내세요", "Finish the previous stage first", "前のステージを先に終えてください", "请先完成上一阶段", "Hãy hoàn thành chặng trước");
  static const LocString learnTrackBasics = LocString("기초", "Basics", "基礎", "基础", "Cơ bản");
  static const LocString learnTrackFuseki = LocString("포석", "Openings", "布石", "布局", "Khai cuộc");
  static const LocString learnTrackTsumego = LocString("사활", "Life and death", "詰碁", "死活", "Sống chết");
  static const LocString engineKataGo = LocString("KataGo", "KataGo", "KataGo", "KataGo", "KataGo");
  static const LocString katagoExeMissing = LocString("KataGo 실행 파일을 찾지 못했습니다", "KataGo executable not found", "KataGo の実行ファイルが見つかりません", "未找到 KataGo 可执行文件", "Không tìm thấy tệp thực thi KataGo");
  static const LocString katagoModelMissing = LocString("KataGo 신경망 파일을 찾지 못했습니다", "KataGo model file not found", "KataGo のモデルが見つかりません", "未找到 KataGo 模型文件", "Không tìm thấy tệp mô hình KataGo");
  static const LocString katagoConfigMissing = LocString("KataGo 설정 파일을 찾지 못했습니다", "KataGo config file not found", "KataGo の設定ファイルが見つかりません", "未找到 KataGo 配置文件", "Không tìm thấy tệp cấu hình KataGo");
  static const LocString katagoNotRunning = LocString("KataGo 가 실행 중이 아닙니다", "KataGo is not running", "KataGo が動作していません", "KataGo 未在运行", "KataGo chưa chạy");
  static const LocString katagoExited = LocString("KataGo 가 종료되었습니다. 내장 AI 로 이어서 둡니다", "KataGo exited. Continuing with the built-in AI", "KataGo が終了しました。内蔵AIで続けます", "KataGo 已退出，改用内置 AI 继续", "KataGo đã thoát. Tiếp tục với AI tích hợp");
  static const LocString katagoEmptyResponse = LocString("KataGo 가 응답을 보내지 않았습니다", "KataGo sent no response", "KataGo が応答を返しませんでした", "KataGo 没有返回响应", "KataGo không phản hồi");
  static const LocString katagoRejected = LocString("KataGo 가 명령을 거절했습니다", "KataGo rejected the command", "KataGo がコマンドを拒否しました", "KataGo 拒绝了该命令", "KataGo từ chối lệnh");
  static const LocString katagoTimeout = LocString("KataGo 응답이 시간을 넘겼습니다", "KataGo timed out", "KataGo の応答がタイムアウトしました", "KataGo 响应超时", "KataGo hết thời gian chờ");
  static const LocString katagoStartFailed = LocString("KataGo 를 시작하지 못했습니다", "Could not start KataGo", "KataGo を起動できませんでした", "无法启动 KataGo", "Không khởi động được KataGo");
  static const LocString katagoTuning = LocString("KataGo 가 처음 실행되어 GPU 최적화 중입니다. 몇 분 걸릴 수 있습니다", "KataGo is tuning for your GPU on first run. This can take a few minutes", "KataGo が初回のGPU最適化を行っています。数分かかる場合があります", "KataGo 首次运行正在针对 GPU 调优，可能需要几分钟", "KataGo đang tối ưu cho GPU lần đầu. Có thể mất vài phút");
  static const LocString resignWin = LocString("기권승", "Win by resignation", "投了勝ち", "中盘胜", "Thắng do đối thủ bỏ cuộc");
  static const LocString yourTurn = LocString("당신 차례", "Your turn", "あなたの番", "轮到你", "Lượt của bạn");
  static const LocString aiTurn = LocString("AI 생각 중…", "AI thinking…", "AI思考中…", "AI思考中…", "AI đang nghĩ…");
  static const LocString black = LocString("흑", "Black", "黒", "黑", "Đen");
  static const LocString white = LocString("백", "White", "白", "白", "Trắng");
  static const LocString captures = LocString("딴 돌", "Captures", "アゲハマ", "提子", "Quân bắt");
  static const LocString boardSize = LocString("판 크기", "Board size", "盤の大きさ", "棋盘大小", "Cỡ bàn");
  static const LocString rank = LocString("난이도", "Difficulty", "難易度", "难度", "Độ khó");
  static const LocString startGame = LocString("대국 시작", "Start game", "対局開始", "开始对局", "Bắt đầu");
  static const LocString newGame = LocString("새 대국", "New game", "新規対局", "新对局", "Ván mới");
  static const LocString resumeGame = LocString("이어서 두기", "Resume game", "続きから", "继续对局", "Chơi tiếp");
  static const LocString movesShort = LocString("수", " moves", "手", "手", " nước");
  static const LocString playAs = LocString("내 색깔", "My color", "自分の色", "我的颜色", "Màu của tôi");
  static const LocString blackStoneColor = LocString("흑돌 색", "Black stone color", "黒石の色", "黑子颜色", "Màu quân đen");
  static const LocString whiteStoneColor = LocString("백돌 색", "White stone color", "白石の色", "白子颜色", "Màu quân trắng");
  static const LocString liveScoreNote = LocString("집·합계는 진행 중 추정(공배·사활 미확정 포함). 종료 후 최종 계가.", "Territory/totals are live estimates. Final score after the game ends.", "地・合計は進行中の推定です。終局後に最終計計算。", "目数与合计为进行中估算，终局后为最终结果。", "Đất/tổng là ước lượng. Điểm cuối sau khi kết thúc.");
  static const LocString blinkHelp = LocString("착수 가능 교차점이 깜빡입니다. Tab으로 이동, Enter로 둡니다.", "Legal intersections blink. Tab to move, Enter to place.", "着手可能な交点が点滅します。Tabで移動、Enterで着手。", "可落子交叉点会闪烁。Tab移动，Enter落子。", "Điểm hợp lệ nhấp nháy. Tab để chọn, Enter để đánh.");
  static const LocString hostRoom = LocString("방 만들기", "Create room", "部屋を作る", "创建房间", "Tạo phòng");
  static const LocString joinRoom = LocString("방 참가", "Join room", "部屋に入る", "加入房间", "Vào phòng");
  static const LocString yourId = LocString("내 방 ID", "My room ID", "自分の部屋ID", "我的房间ID", "ID phòng của tôi");
  static const LocString peerId = LocString("상대 방 ID", "Friend room ID", "相手の部屋ID", "对方房间ID", "ID phòng bạn");
  static const LocString copyId = LocString("ID 복사", "Copy ID", "IDをコピー", "复制ID", "Sao chép ID");
  static const LocString waiting = LocString("상대 연결 대기 중…", "Waiting for friend…", "相手の接続待ち…", "等待对手连接…", "Đang chờ bạn…");
  static const LocString connected = LocString("연결됨", "Connected", "接続済み", "已连接", "Đã kết nối");
  static const LocString font = LocString("글꼴", "Font", "フォント", "字体", "Phông chữ");
  static const LocString fontSize = LocString("글자 크기", "Text size", "文字サイズ", "文字大小", "Cỡ chữ");
  static const LocString language = LocString("언어", "Language", "言語", "语言", "Ngôn ngữ");
  static const LocString history = LocString("히스토리", "History", "履歴", "更新历史", "Lịch sử");
  static const LocString sizeSmall = LocString("작음", "Small", "小", "小", "Nhỏ");
  static const LocString sizeMedium = LocString("보통", "Medium", "中", "中", "Vừa");
  static const LocString sizeLarge = LocString("큼", "Large", "大", "大", "Lớn");
  static const LocString blinkOn = LocString("착수점 깜빡임: 켜짐", "Intersection blink: On", "交点点滅: オン", "交叉点闪烁: 开", "Nhấp nháy: Bật");
  static const LocString blinkOff = LocString("착수점 깜빡임: 꺼짐", "Intersection blink: Off", "交点点滅: オフ", "交叉点闪烁: 关", "Nhấp nháy: Tắt");
  static const LocString highContrast = LocString("최대 대비 보드", "Max contrast board", "最大コントラスト盤", "最大对比棋盘", "Bàn tương phản tối đa");
  static const LocString strongButtonContrast = LocString("버튼 대비 확실하게 (글자·테두리 강화)", "Strong button contrast (text & border)", "ボタンコントラストをはっきり", "按钮对比更清晰（文字与边框）", "Độ tương phản nút rõ ràng (chữ & viền)");
  static const LocString next = LocString("다음", "Next", "次へ", "下一步", "Tiếp");
  static const LocString prev = LocString("이전", "Previous", "前へ", "上一步", "Trước");
  static const LocString lessonDone = LocString("학습 완료 — AI와 겨루기로 연습해 보세요", "Lesson done — try Play vs AI", "学習完了 — AI対局で練習", "学习完成 — 试试与AI对弈", "Xong bài — thử đấu với AI");
  static const LocString gameOver = LocString("대국 종료", "Game over", "終局", "终局", "Kết thúc");
  static const LocString katagoStatus = LocString("KataGo", "KataGo", "KataGo", "KataGo", "KataGo");
  static const LocString katagoOff = LocString("내장 AI (KataGo 미연결)", "Built-in AI (KataGo offline)", "内蔵AI（KataGo未接続）", "内置AI（未连接KataGo）", "AI tích hợp (chưa KataGo)");
  static const LocString aiEngineBuiltin = LocString("엔진: 내장 휴리스틱 (급단에 따라 랜덤 비율 조절)", "Engine: built-in heuristic (rank controls randomness)", "エンジン: 内蔵ヒューリスティック", "引擎：内置启发式", "Engine: heuristic tích hợp");
  static const LocString aiEngineKatago = LocString("엔진: KataGo (로컬 GTP · visits", "Engine: KataGo (local GTP · visits", "エンジン: KataGo (ローカルGTP · visits", "引擎：KataGo（本地 GTP · visits", "Engine: KataGo (GTP cục bộ · visits");
  static const LocString aiBuiltinForEasy = LocString("입문~초급+: 내장 AI(약한 랜덤). KataGo는 중급(5)부터", "Lv1–4: weak built-in AI. KataGo from level 5+", "入門〜初級+: 弱い内蔵AI。KataGoは中級(5)から", "入门~初级+: 弱内置AI。KataGo从中级(5)起", "Lv1–4: AI tích hợp yếu. KataGo từ cấp 5+");
  static const LocString illegal = LocString("둘 수 없는 자리입니다", "Illegal move", "禁じ手です", "非法落子", "Nước đi không hợp lệ");
  static const LocString superko = LocString("슈퍼코 — 같은 국면으로 돌아갈 수 없습니다", "Superko — cannot repeat a past position", "スーパーコウ — 同一局面への再生は禁止", "超劫 — 不能重复已出现过的局面", "Siêu ko — không được lặp lại thế trận cũ");
  static const LocString lastMove = LocString("직전 수", "Last move", "直前の手", "上一手", "Nước vừa rồi");
  static const LocString disconnected = LocString("연결이 끊어졌습니다. 로비로 돌아갑니다.", "Disconnected. Returning to lobby.", "切断されました。ロビーに戻ります。", "连接已断开，返回大厅。", "Mất kết nối. Quay lại sảnh.");
  static const LocString connectFailed = LocString("연결에 실패했습니다. 방 ID·네트워크(방화벽/NAT)를 확인하세요.", "Connection failed. Check room ID and network (firewall/NAT).", "接続に失敗しました。部屋IDとネットワークを確認してください。", "连接失败。请检查房间ID和网络（防火墙/NAT）。", "Kết nối thất bại. Kiểm tra ID phòng và mạng (firewall/NAT).");
  static const LocString returnLobby = LocString("로비로 돌아가기", "Back to lobby", "ロビーへ", "返回大厅", "Về sảnh");
  static const LocString reinitPeer = LocString("연결 다시 준비", "Reset connection", "接続をやり直す", "重置连接", "Thiết lập lại kết nối");
  static const LocString p2pHint = LocString("서버리스 WebRTC P2P (PeerJS 시그널링). 같은 Wi‑Fi가 아니면 연결이 실패할 수 있습니다.", "Serverless WebRTC P2P (PeerJS signaling). Connection may fail across strict NAT.", "サーバーレスWebRTC P2P。厳格なNATでは失敗することがあります。", "无服务器 WebRTC P2P。严格 NAT 下可能失败。", "P2P WebRTC không server. NAT nghiêm có thể thất bại.");
  static const LocString hostLabel = LocString("호스트", "Host", "ホスト", "房主", "Chủ phòng");
  static const LocString score = LocString("계가(초보)", "Score (beginner)", "終局計算(初級)", "点目(入门)", "Đếm điểm (cơ bản)");
  static const LocString territory = LocString("집", "Territory", "地", "目", "Đất");
  static const LocString komi = LocString("덤", "Komi", "コミ", "贴目", "Komi");
  static const LocString goRules = LocString("룰", "Rules", "ルール", "规则", "Luật");
  static const LocString settingsVision = LocString("보기", "Vision", "表示", "显示", "Hiển thị");
  static const LocString settingsBoard = LocString("바둑판", "Board", "碁盤", "棋盘", "Bàn cờ");
  static const LocString settingsGame = LocString("대국", "Game", "対局", "对局", "Ván cờ");
  static const LocString settingsSpeech = LocString("낭독", "Speech", "読み上げ", "朗读", "Đọc");
  static const LocString contrastProfile = LocString("대비", "Contrast", "コントラスト", "对比度", "Tương phản");
  static const LocString contrastHigh = LocString("고대비 (기본)", "High (default)", "高 (既定)", "高 (默认)", "Cao (mặc định)");
  static const LocString contrastMax = LocString("최대 대비", "Maximum", "最大", "最大", "Tối đa");
  static const LocString contrastInverted = LocString("반전 (밝은 판)", "Inverted (light board)", "反転 (明るい盤)", "反色 (亮底)", "Đảo (nền sáng)");
  static const LocString focusRingLabel = LocString("포커스 테두리 색", "Focus ring colour", "フォーカス枠の色", "焦点框颜色", "Màu viền tiêu điểm");
  static const LocString focusRingAmber = LocString("호박색 (기본)", "Amber (default)", "琥珀 (既定)", "琥珀 (默认)", "Hổ phách (mặc định)");
  static const LocString focusRingYellow = LocString("노랑 (최대 대비)", "Yellow (max contrast)", "黄 (最大)", "黄 (最大)", "Vàng (tối đa)");
  static const LocString paletteLabel = LocString("판 색", "Board colours", "盤の配色", "棋盘配色", "Màu bàn cờ");
  static const LocString verbosityLabel = LocString("낭독 상세도", "Speech detail", "読み上げの詳しさ", "朗读详细度", "Mức chi tiết");
  static const LocString verbosityTerse = LocString("간단히", "Brief", "簡潔", "简洁", "Ngắn gọn");
  static const LocString verbosityFull = LocString("자세히", "Detailed", "詳しく", "详细", "Chi tiết");
  static const LocString coordModeLabel = LocString("좌표 눈금", "Coordinate labels", "座標表示", "坐标标注", "Nhãn tọa độ");
  static const LocString coordAuto = LocString("자동", "Auto", "自動", "自动", "Tự động");
  static const LocString coordOn = LocString("항상 표시", "Always", "常に表示", "始终显示", "Luôn hiện");
  static const LocString coordOff = LocString("숨김", "Never", "非表示", "隐藏", "Ẩn");
  static const LocString opponentLabel = LocString("상대", "Opponent", "対戦相手", "对手", "Đối thủ");
  static const LocString opponentNone = LocString("없음 (양쪽 다 내가)", "None (play both sides)", "なし (両方自分で)", "无 (自己下两边)", "Không (tự đi cả hai");
  static const LocString opponentBuiltin = LocString("내장 AI", "Built-in AI", "内蔵AI", "内置 AI", "AI tích hợp");
  static const LocString opponentKataGo = LocString("KataGo", "KataGo", "KataGo", "KataGo", "KataGo");
  static const LocString reduceMotionSystem = LocString("시스템 설정 따름", "Follow system", "システムに従う", "跟随系统", "Theo hệ thống");
  static const LocString onLabel = LocString("켜기", "On", "オン", "开", "Bật");
  static const LocString offLabel = LocString("끄기", "Off", "オフ", "关", "Tắt");
  static const LocString goRulesJapanese = LocString("일본룰 (집계법)", "Japanese (territory)", "日本ルール", "日本规则", "Luật Nhật");
  static const LocString goRulesChinese = LocString("중국룰 (영역법)", "Chinese (area)", "中国ルール", "中国规则", "Luật Trung");
  static const LocString sgfExport = LocString("기보 내보내기", "Export SGF", "棋譜を書き出す", "导出棋谱", "Xuất kỳ phổ");
  static const LocString sgfImport = LocString("기보 불러오기", "Import SGF", "棋譜を読み込む", "导入棋谱", "Nhập kỳ phổ");
  static const LocString sgfSaved = LocString("기보를 저장했습니다", "Game record saved", "棋譜を保存しました", "棋谱已保存", "Đã lưu kỳ phổ");
  static const LocString sgfCancelled = LocString("취소했습니다", "Cancelled", "キャンセルしました", "已取消", "Đã hủy");
  static const LocString sgfWriteFailed = LocString("파일을 저장하지 못했습니다", "Could not save the file", "ファイルを保存できませんでした", "无法保存文件", "Không lưu được tệp");
  static const LocString sgfReadFailed = LocString("파일을 읽지 못했습니다", "Could not read the file", "ファイルを読めませんでした", "无法读取文件", "Không đọc được tệp");
  static const LocString contrastStandard = LocString("표준", "Standard", "標準", "标准", "Tiêu chuẩn");
  static const LocString paletteClassic = LocString("기본", "Classic", "標準", "经典", "Cổ điển");
  static const LocString paletteMaxContrast = LocString("최대 대비", "Max contrast", "最大コントラスト", "最大对比", "Tương phản tối đa");
  static const LocString paletteAmberBlue = LocString("호박·파랑", "Amber and blue", "琥珀・青", "琥珀·蓝", "Hổ phách và xanh");
  static const LocString paletteWarmGray = LocString("따뜻한 회색", "Warm gray", "暖かいグレー", "暖灰", "Xám ấm");
  static const LocString paletteInverted = LocString("반전 (밝은 판)", "Inverted (light board)", "反転 (明るい盤)", "反色 (亮底)", "Đảo (nền sáng)");
  static const LocString rulesJapanese = LocString("일본식 (집+사석+덤)", "Japanese (territory + captives + komi)", "日本式（地+アゲハマ+コミ）", "日式（目+提子+贴目）", "Nhật (đất + quân bắt + komi)");
  static const LocString rulesChinese = LocString("중국식 (집+돌수+덤)", "Chinese (area + stones + komi)", "中国式（地+石数+コミ）", "中式（目+子数+贴目）", "Trung (đất + số quân + komi)");
  static const LocString total = LocString("합계", "Total", "合計", "合计", "Tổng");
  static const LocString blackWins = LocString("흑 승", "Black wins", "黒勝ち", "黑胜", "Đen thắng");
  static const LocString whiteWins = LocString("백 승", "White wins", "白勝ち", "白胜", "Trắng thắng");
  static const LocString draw = LocString("무승부", "Draw", "引き分け", "和棋", "Hòa");
  static const LocString scoreNote = LocString("둘러싼 빈 점+딴 돌+덤. 사활·빅은 아직 자동 처리하지 않습니다.", "Surrounded empties + captives + komi. Life/death & seki not auto-resolved.", "囲んだ空点+アゲハマ+コミ。死活・セキは未自動判定。", "围住的空点+提子+贴目。死活/双活暂不自动判定。", "Ô trống bao quanh + quân bắt + komi. Chưa xử lý sống chết/seki.");
  static const LocString moveSoundOn = LocString("착수 소리: 켜짐", "Move sound: On", "着手音: オン", "落子声: 开", "Âm nước đi: Bật");
  static const LocString moveSoundOff = LocString("착수 소리: 꺼짐", "Move sound: Off", "着手音: オフ", "落子声: 关", "Âm nước đi: Tắt");
  static const LocString boardScale = LocString("돌·칸 크기", "Stone / grid size", "石・マスの大きさ", "子与格大小", "Cỡ quân / ô");
  static const LocString lineWeight = LocString("선 굵기", "Line thickness", "線の太さ", "线宽", "Độ dày đường");
  static const LocString lineThin = LocString("얇게", "Thin", "細い", "细", "Mỏng");
  static const LocString lineNormal = LocString("보통", "Normal", "普通", "中", "Vừa");
  static const LocString lineThick = LocString("굵게", "Thick", "太い", "粗", "Dày");
  static const LocString reduceMotionLabel = LocString("움직임 줄이기 (깜빡임 정지)", "Reduce motion (stop blink)", "動きを減らす（点滅停止）", "减少动态（停止闪烁）", "Giảm chuyển động (tắt nhấp nháy)");
  static const LocString katagoBridge = LocString("KataGo 브리지 URL", "KataGo bridge URL", "KataGoブリッジURL", "KataGo 桥接 URL", "URL cầu KataGo");
  static const LocString katagoConnect = LocString("KataGo 브리지 연결", "Connect KataGo bridge", "KataGoブリッジ接続", "连接 KataGo 桥接", "Kết nối cầu KataGo");
  static const LocString katagoDisconnect = LocString("KataGo 연결 해제", "Disconnect KataGo", "KataGo切断", "断开 KataGo", "Ngắt KataGo");
  static const LocString katagoOn = LocString("KataGo: 연결됨", "KataGo: connected", "KataGo: 接続中", "KataGo: 已连接", "KataGo: đã kết nối");
  static const LocString katagoAuto = LocString("시작 시 브리지 자동 연결 시도", "Auto-connect bridge on start", "起動時にブリッジ自動接続", "启动时自动连接桥接", "Tự kết nối cầu khi mở");
  static const LocString katagoPathHint = LocString("경로 비우면 브리지 기본값(katago/bin, models) 사용", "Leave paths empty to use bridge defaults", "空欄ならブリッジ既定パスを使用", "留空则使用桥接默认路径", "Để trống để dùng đường dẫn mặc định");
  static const LocString computeDetect = LocString("이 PC 연산 장치(추정)", "Detected compute (estimate)", "このPCの計算装置(推定)", "本机算力(估计)", "Thiết bị tính toán (ước lượng)");
  static const LocString saveSgf = LocString("기보 저장", "Save SGF", "棋譜保存", "保存棋谱", "Lưu SGF");
  static const LocString loadSgf = LocString("기보 불러오기", "Load SGF", "棋譜読込", "载入棋谱", "Mở SGF");
  static const LocString undoMove = LocString("한 수 뒤로", "Undo", "一手戻る", "上一手", "Lùi một nước");
  static const LocString redoMove = LocString("한 수 앞으로", "Redo", "一手進む", "下一手", "Tới một nước");
  static const LocString review = LocString("복기", "Review", "検討", "复盘", "Xem lại");
  static const LocString sgfLoaded = LocString("기보를 불러왔습니다", "SGF loaded", "棋譜を読み込みました", "已载入棋谱", "Đã mở SGF");
  static const LocString sgfFailed = LocString("기보를 읽지 못했습니다", "Failed to load SGF", "棋譜の読込に失敗", "棋谱载入失败", "Không mở được SGF");
  static const LocString askHint = LocString("AI 힌트", "AI hint", "AIヒント", "AI提示", "Gợi ý AI");
  static const LocString hintReady = LocString("추천 수 표시 — 라벨 「힌트」", "Suggested move marked — label “힌트”", "推奨着手を表示（「힌트」）", "已标出推荐点（「힌트」）", "Đã đánh dấu nước gợi ý");
  static const LocString hintPass = LocString("AI 추천: 패스", "AI suggests: pass", "AI推奨: パス", "AI建议：停着", "AI gợi ý: bỏ lượt");
  static const LocString hintBusy = LocString("힌트 계산 중…", "Computing hint…", "ヒント計算中…", "正在计算提示…", "Đang tính gợi ý…");
}

/// 완전성 테스트용 — 생성된 문자열 개수
const int generatedStringCount = 272;

/// 완전성 테스트용 — 키 이름과 값 목록
const Map<String, LocString> allStrings = <String, LocString>{
  "appTitle": S.appTitle,
  "tagline": S.tagline,
  "learn": S.learn,
  "learnBasics": S.learnBasics,
  "learnFuseki": S.learnFuseki,
  "learnTsumego": S.learnTsumego,
  "learnStages": S.learnStages,
  "learnTrackProgress": S.learnTrackProgress,
  "learnStageCleared": S.learnStageCleared,
  "learnShowAnswer": S.learnShowAnswer,
  "learnRetry": S.learnRetry,
  "learnCurriculumNote": S.learnCurriculumNote,
  "solo": S.solo,
  "soloLead": S.soloLead,
  "difficulty": S.difficulty,
  "opponentSummary": S.opponentSummary,
  "multi": S.multi,
  "settings": S.settings,
  "profile": S.profile,
  "profileLead": S.profileLead,
  "profileName": S.profileName,
  "profileNamePlaceholder": S.profileNamePlaceholder,
  "profileNameRequired": S.profileNameRequired,
  "profileNameTooLong": S.profileNameTooLong,
  "profileAvatar": S.profileAvatar,
  "profileCreate": S.profileCreate,
  "profileSave": S.profileSave,
  "profileCreated": S.profileCreated,
  "profileSaved": S.profileSaved,
  "profileLevel": S.profileLevel,
  "profileXp": S.profileXp,
  "profileRecord": S.profileRecord,
  "profileHighScore": S.profileHighScore,
  "profileBestAi": S.profileBestAi,
  "profileLevelUp": S.profileLevelUp,
  "profileXpGain": S.profileXpGain,
  "profileNewHigh": S.profileNewHigh,
  "profileNeedChar": S.profileNeedChar,
  "back": S.back,
  "home": S.home,
  "confirm": S.confirm,
  "on": S.on,
  "katagoMobileUnavailable": S.katagoMobileUnavailable,
  "starPoint": S.starPoint,
  "liberties": S.liberties,
  "turnSuffix": S.turnSuffix,
  "capturedSuffix": S.capturedSuffix,
  "stoneCountSuffix": S.stoneCountSuffix,
  "noStones": S.noStones,
  "rowSuffix": S.rowSuffix,
  "noLastMove": S.noLastMove,
  "territoryLabel": S.territoryLabel,
  "komiLabel": S.komiLabel,
  "winsBy": S.winsBy,
  "drawResult": S.drawResult,
  "scoreEstimate": S.scoreEstimate,
  "hintLabel": S.hintLabel,
  "undoneLabel": S.undoneLabel,
  "scoreRulesJapanese": S.scoreRulesJapanese,
  "scoreRulesChinese": S.scoreRulesChinese,
  "scoreDeadStonesNote": S.scoreDeadStonesNote,
  "snapshotCorrupt": S.snapshotCorrupt,
  "snapshotTooNew": S.snapshotTooNew,
  "snapshotBadSize": S.snapshotBadSize,
  "snapshotReplayFailed": S.snapshotReplayFailed,
  "sgfNotSgf": S.sgfNotSgf,
  "sgfUnsupportedSize": S.sgfUnsupportedSize,
  "sgfTurnMismatch": S.sgfTurnMismatch,
  "sgfBadCoord": S.sgfBadCoord,
  "sgfIllegalMove": S.sgfIllegalMove,
  "boardLabel": S.boardLabel,
  "boardHint": S.boardHint,
  "coordInputLabel": S.coordInputLabel,
  "coordInputHint": S.coordInputHint,
  "coordInputHelper": S.coordInputHelper,
  "errOccupied": S.errOccupied,
  "errKo": S.errKo,
  "errSuperko": S.errSuperko,
  "errSuicide": S.errSuicide,
  "errGameEnded": S.errGameEnded,
  "errOutOfBounds": S.errOutOfBounds,
  "errSkippedLetter": S.errSkippedLetter,
  "errBadColumn": S.errBadColumn,
  "errBadRow": S.errBadRow,
  "errEmptyInput": S.errEmptyInput,
  "errUnknownInput": S.errUnknownInput,
  "pointEmpty": S.pointEmpty,
  "selectedPoint": S.selectedPoint,
  "confirmPlace": S.confirmPlace,
  "occupiedPoint": S.occupiedPoint,
  "territoryBlack": S.territoryBlack,
  "territoryWhite": S.territoryWhite,
  "showCoords": S.showCoords,
  "placeModeLabel": S.placeModeLabel,
  "placeModeDirect": S.placeModeDirect,
  "placeModeConfirm": S.placeModeConfirm,
  "off": S.off,
  "followSystem": S.followSystem,
  "dataSection": S.dataSection,
  "exportData": S.exportData,
  "importData": S.importData,
  "backupNote": S.backupNote,
  "importFailedNotJson": S.importFailedNotJson,
  "importFailedNotBackup": S.importFailedNotBackup,
  "importFailedVersion": S.importFailedVersion,
  "resetSettings": S.resetSettings,
  "resetSettingsBody": S.resetSettingsBody,
  "cancel": S.cancel,
  "resignConfirmTitle": S.resignConfirmTitle,
  "resignConfirmBody": S.resignConfirmBody,
  "newGameConfirmTitle": S.newGameConfirmTitle,
  "newGameConfirmBody": S.newGameConfirmBody,
  "version": S.version,
  "skipToMain": S.skipToMain,
  "pass": S.pass,
  "resign": S.resign,
  "scoreNow": S.scoreNow,
  "learnNoProblem": S.learnNoProblem,
  "learnWrongPoint": S.learnWrongPoint,
  "learnIllegal": S.learnIllegal,
  "learnGoalUnmet": S.learnGoalUnmet,
  "learnCorrect": S.learnCorrect,
  "learnTrackCleared": S.learnTrackCleared,
  "learnNextProblem": S.learnNextProblem,
  "learnPrevProblem": S.learnPrevProblem,
  "learnProgress": S.learnProgress,
  "learnTryHint": S.learnTryHint,
  "learnLocked": S.learnLocked,
  "learnTrackBasics": S.learnTrackBasics,
  "learnTrackFuseki": S.learnTrackFuseki,
  "learnTrackTsumego": S.learnTrackTsumego,
  "engineKataGo": S.engineKataGo,
  "katagoExeMissing": S.katagoExeMissing,
  "katagoModelMissing": S.katagoModelMissing,
  "katagoConfigMissing": S.katagoConfigMissing,
  "katagoNotRunning": S.katagoNotRunning,
  "katagoExited": S.katagoExited,
  "katagoEmptyResponse": S.katagoEmptyResponse,
  "katagoRejected": S.katagoRejected,
  "katagoTimeout": S.katagoTimeout,
  "katagoStartFailed": S.katagoStartFailed,
  "katagoTuning": S.katagoTuning,
  "resignWin": S.resignWin,
  "yourTurn": S.yourTurn,
  "aiTurn": S.aiTurn,
  "black": S.black,
  "white": S.white,
  "captures": S.captures,
  "boardSize": S.boardSize,
  "rank": S.rank,
  "startGame": S.startGame,
  "newGame": S.newGame,
  "resumeGame": S.resumeGame,
  "movesShort": S.movesShort,
  "playAs": S.playAs,
  "blackStoneColor": S.blackStoneColor,
  "whiteStoneColor": S.whiteStoneColor,
  "liveScoreNote": S.liveScoreNote,
  "blinkHelp": S.blinkHelp,
  "hostRoom": S.hostRoom,
  "joinRoom": S.joinRoom,
  "yourId": S.yourId,
  "peerId": S.peerId,
  "copyId": S.copyId,
  "waiting": S.waiting,
  "connected": S.connected,
  "font": S.font,
  "fontSize": S.fontSize,
  "language": S.language,
  "history": S.history,
  "sizeSmall": S.sizeSmall,
  "sizeMedium": S.sizeMedium,
  "sizeLarge": S.sizeLarge,
  "blinkOn": S.blinkOn,
  "blinkOff": S.blinkOff,
  "highContrast": S.highContrast,
  "strongButtonContrast": S.strongButtonContrast,
  "next": S.next,
  "prev": S.prev,
  "lessonDone": S.lessonDone,
  "gameOver": S.gameOver,
  "katagoStatus": S.katagoStatus,
  "katagoOff": S.katagoOff,
  "aiEngineBuiltin": S.aiEngineBuiltin,
  "aiEngineKatago": S.aiEngineKatago,
  "aiBuiltinForEasy": S.aiBuiltinForEasy,
  "illegal": S.illegal,
  "superko": S.superko,
  "lastMove": S.lastMove,
  "disconnected": S.disconnected,
  "connectFailed": S.connectFailed,
  "returnLobby": S.returnLobby,
  "reinitPeer": S.reinitPeer,
  "p2pHint": S.p2pHint,
  "hostLabel": S.hostLabel,
  "score": S.score,
  "territory": S.territory,
  "komi": S.komi,
  "goRules": S.goRules,
  "settingsVision": S.settingsVision,
  "settingsBoard": S.settingsBoard,
  "settingsGame": S.settingsGame,
  "settingsSpeech": S.settingsSpeech,
  "contrastProfile": S.contrastProfile,
  "contrastHigh": S.contrastHigh,
  "contrastMax": S.contrastMax,
  "contrastInverted": S.contrastInverted,
  "focusRingLabel": S.focusRingLabel,
  "focusRingAmber": S.focusRingAmber,
  "focusRingYellow": S.focusRingYellow,
  "paletteLabel": S.paletteLabel,
  "verbosityLabel": S.verbosityLabel,
  "verbosityTerse": S.verbosityTerse,
  "verbosityFull": S.verbosityFull,
  "coordModeLabel": S.coordModeLabel,
  "coordAuto": S.coordAuto,
  "coordOn": S.coordOn,
  "coordOff": S.coordOff,
  "opponentLabel": S.opponentLabel,
  "opponentNone": S.opponentNone,
  "opponentBuiltin": S.opponentBuiltin,
  "opponentKataGo": S.opponentKataGo,
  "reduceMotionSystem": S.reduceMotionSystem,
  "onLabel": S.onLabel,
  "offLabel": S.offLabel,
  "goRulesJapanese": S.goRulesJapanese,
  "goRulesChinese": S.goRulesChinese,
  "sgfExport": S.sgfExport,
  "sgfImport": S.sgfImport,
  "sgfSaved": S.sgfSaved,
  "sgfCancelled": S.sgfCancelled,
  "sgfWriteFailed": S.sgfWriteFailed,
  "sgfReadFailed": S.sgfReadFailed,
  "contrastStandard": S.contrastStandard,
  "paletteClassic": S.paletteClassic,
  "paletteMaxContrast": S.paletteMaxContrast,
  "paletteAmberBlue": S.paletteAmberBlue,
  "paletteWarmGray": S.paletteWarmGray,
  "paletteInverted": S.paletteInverted,
  "rulesJapanese": S.rulesJapanese,
  "rulesChinese": S.rulesChinese,
  "total": S.total,
  "blackWins": S.blackWins,
  "whiteWins": S.whiteWins,
  "draw": S.draw,
  "scoreNote": S.scoreNote,
  "moveSoundOn": S.moveSoundOn,
  "moveSoundOff": S.moveSoundOff,
  "boardScale": S.boardScale,
  "lineWeight": S.lineWeight,
  "lineThin": S.lineThin,
  "lineNormal": S.lineNormal,
  "lineThick": S.lineThick,
  "reduceMotionLabel": S.reduceMotionLabel,
  "katagoBridge": S.katagoBridge,
  "katagoConnect": S.katagoConnect,
  "katagoDisconnect": S.katagoDisconnect,
  "katagoOn": S.katagoOn,
  "katagoAuto": S.katagoAuto,
  "katagoPathHint": S.katagoPathHint,
  "computeDetect": S.computeDetect,
  "saveSgf": S.saveSgf,
  "loadSgf": S.loadSgf,
  "undoMove": S.undoMove,
  "redoMove": S.redoMove,
  "review": S.review,
  "sgfLoaded": S.sgfLoaded,
  "sgfFailed": S.sgfFailed,
  "askHint": S.askHint,
  "hintReady": S.hintReady,
  "hintPass": S.hintPass,
  "hintBusy": S.hintBusy,
};
