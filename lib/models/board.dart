import '../utils/constants.dart';
import 'piece.dart';
import 'position.dart';

/// 盤面クラス
class Board {
  /// 9x9のセル（各セルはPieceStack）
  final List<List<PieceStack>> _cells;

  Board()
      : _cells = List.generate(
          boardSize,
          (_) => List.generate(boardSize, (_) => PieceStack()),
        );

  Board._fromCells(this._cells);

  /// 指定位置のスタックを取得
  PieceStack getStack(Position pos) {
    if (!pos.isValid) {
      throw ArgumentError('Invalid position: $pos');
    }
    return _cells[pos.row][pos.col];
  }

  /// 指定位置の最上部の駒を取得
  Piece? getPiece(Position pos) => getStack(pos).top;

  /// 指定位置のスタック高さを取得
  int getHeight(Position pos) => getStack(pos).height;

  /// 指定位置が空かどうか
  bool isEmpty(Position pos) => getStack(pos).isEmpty;

  /// 指定位置に駒を配置
  void placePiece(Position pos, Piece piece) {
    getStack(pos).push(piece);
  }

  /// 指定位置の最上部の駒を取り除く
  Piece? removePiece(Position pos) {
    return getStack(pos).pop();
  }

  /// 指定位置の全ての駒を取り除く（捕獲）
  List<Piece> captureStack(Position pos) {
    return getStack(pos).clear();
  }

  /// 駒を移動
  void movePiece(Position from, Position to) {
    final piece = removePiece(from);
    if (piece != null) {
      placePiece(to, piece);
    }
  }

  /// スタック全体を移動（ツケで一体化した駒）
  void moveStack(Position from, Position to) {
    final stack = getStack(from);
    final pieces = stack.clear();
    final targetStack = getStack(to);
    for (final piece in pieces) {
      targetStack.push(piece);
    }
  }

  /// 指定プレイヤーの帥の位置を取得
  /// スタック内の全ての駒を探索（帥がツケられていても見つける）
  Position? findSui(Player player) {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final pos = Position(r, c);
        final stack = getStack(pos);
        // スタック内の全ての駒をチェック
        for (final piece in stack.pieces) {
          if (piece.type == PieceType.sui && piece.owner == player) {
            return pos;
          }
        }
      }
    }
    return null;
  }

  /// 指定プレイヤーの最前線の行を取得
  int getFrontLine(Player player) {
    if (player == Player.white) {
      // 先手: row 0から探して最も大きいrow
      for (int r = boardSize - 1; r >= 0; r--) {
        for (int c = 0; c < boardSize; c++) {
          final piece = getPiece(Position(r, c));
          if (piece != null && piece.owner == player) {
            return r;
          }
        }
      }
      return 0;
    } else {
      // 後手: row 8から探して最も小さいrow
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          final piece = getPiece(Position(r, c));
          if (piece != null && piece.owner == player) {
            return r;
          }
        }
      }
      return boardSize - 1;
    }
  }

  /// 盤面をコピー
  Board copy() {
    final newCells = List.generate(
      boardSize,
      (r) => List.generate(boardSize, (c) => _cells[r][c].copy()),
    );
    return Board._fromCells(newCells);
  }

  /// デバッグ用：盤面を文字列で表示
  String toDebugString() {
    final buffer = StringBuffer();
    buffer.writeln('  1 2 3 4 5 6 7 8 9');
    for (int r = boardSize - 1; r >= 0; r--) {
      buffer.write('${r + 1} ');
      for (int c = 0; c < boardSize; c++) {
        final stack = _cells[r][c];
        if (stack.isEmpty) {
          buffer.write('・');
        } else {
          buffer.write(stack.top!.kanji);
        }
        buffer.write(' ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
