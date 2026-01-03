import '../utils/constants.dart';

/// 盤上の座標
class Position {
  final int row; // 0-8（0が先手側）
  final int col; // 0-8

  const Position(this.row, this.col);

  /// 盤内かどうか
  bool get isValid =>
      row >= 0 && row < boardSize && col >= 0 && col < boardSize;

  /// 相対移動
  Position offset(int dr, int dc) => Position(row + dr, col + dc);

  @override
  bool operator ==(Object other) =>
      other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => row * boardSize + col;

  @override
  String toString() => '($row, $col)';

  /// 棋譜表記用（1-indexed）
  String toNotation() => '${col + 1}${row + 1}';
}
