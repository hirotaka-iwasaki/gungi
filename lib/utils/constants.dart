/// 盤面サイズ
const int boardSize = 9;

/// 最大スタック高さ（上級ルール）
const int maxStackHeight = 3;

/// プレイヤー識別
enum Player {
  white, // 先手
  black; // 後手

  Player get opponent => this == white ? black : white;
}

/// 駒の種類（14種類）
enum PieceType {
  sui('帥', 1), // 帥（王将相当）
  dai('大', 1),
  chu('中', 1),
  sho('小', 2),
  samurai('侍', 2),
  shinobi('忍', 2),
  hei('兵', 4),
  yari('槍', 3),
  uma('馬', 2),
  toride('砦', 2),
  yumi('弓', 2), // 特殊駒
  hou('砲', 1), // 特殊駒
  tsutsu('筒', 1), // 特殊駒
  bou('謀', 1); // 特殊駒（寝返り）

  final String kanji;
  final int count; // 各プレイヤーの所持数

  const PieceType(this.kanji, this.count);

  /// 特殊駒かどうか
  bool get isSpecial =>
      this == yumi || this == hou || this == tsutsu || this == bou;
}

/// ルールレベル
enum RuleLevel {
  beginner, // 入門編：固定配置、特殊駒なし、最大2段
  elementary, // 初級編：固定配置、特殊駒なし、最大2段
  intermediate, // 中級編：自由配置、特殊駒なし、最大2段
  advanced; // 上級編：自由配置、全駒使用、最大3段

  /// 最大スタック高さ
  int get maxHeight => this == advanced ? 3 : 2;

  /// 特殊駒を使用するか
  bool get useSpecialPieces => this == advanced;

  /// 自由配置か
  bool get freeSetup => this == intermediate || this == advanced;
}
