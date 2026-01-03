import '../models/game_state.dart';
import '../models/move.dart';
import '../models/position.dart';
import '../utils/constants.dart';
import 'piece_movement.dart';

/// 合法手生成・検証クラス
class MoveValidator {
  final GameState state;

  MoveValidator(this.state);

  /// 現在のプレイヤーの全合法手を生成
  List<Move> generateAllLegalMoves() {
    final moves = <Move>[];
    final player = state.currentPlayer;

    // 盤上の駒の移動
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final pos = Position(r, c);
        final stack = state.board.getStack(pos);

        if (stack.isNotEmpty && stack.controller == player) {
          moves.addAll(_generateMovesForPiece(pos));
        }
      }
    }

    // 手駒からの配置（新）
    moves.addAll(_generateDropMoves());

    return moves;
  }

  /// 指定位置の駒の合法手を生成
  List<Move> _generateMovesForPiece(Position from) {
    final moves = <Move>[];
    final stack = state.board.getStack(from);
    final piece = stack.top!;
    final player = piece.owner;
    final height = stack.height;

    // 移動不可の駒
    if (!PieceMovement.canMove(piece.type)) return moves;

    // 移動可能な位置を取得
    final targets = PieceMovement.getLegalPositions(
      type: piece.type,
      from: from,
      stackHeight: height,
      owner: player,
    );

    for (final to in targets) {
      final targetStack = state.board.getStack(to);

      if (targetStack.isEmpty) {
        // 空マスへの移動
        moves.add(Move.move(
          piece: piece,
          from: from,
          to: to,
          player: player,
        ));
      } else {
        final targetOwner = targetStack.controller!;
        final targetHeight = targetStack.height;

        // 高さチェック：自分と同じ段数以下にしか攻撃できない
        if (height >= targetHeight) {
          if (targetOwner == player) {
            // 自駒へのツケ（スタック高さ制限チェック）
            if (targetHeight + 1 <= state.ruleLevel.maxHeight) {
              moves.add(Move.stack(
                piece: piece,
                from: from,
                to: to,
                player: player,
                isAttack: false,
              ));
            }
          } else {
            // 敵駒への捕獲またはツケ
            moves.add(Move.capture(
              piece: piece,
              from: from,
              to: to,
              player: player,
            ));

            // 敵駒へのツケ（スタック高さ制限チェック）
            if (targetHeight + 1 <= state.ruleLevel.maxHeight) {
              moves.add(Move.stack(
                piece: piece,
                from: from,
                to: to,
                player: player,
                isAttack: true,
              ));
            }
          }
        }
      }
    }

    // 経路上の障害物チェック（飛び駒以外）
    return _filterBlockedMoves(moves, from);
  }

  /// 経路上の障害物による移動制限をフィルタ
  List<Move> _filterBlockedMoves(List<Move> moves, Position from) {
    final filtered = <Move>[];
    final stack = state.board.getStack(from);
    final piece = stack.top!;
    final height = stack.height;

    // 飛び駒（忍の桂馬動き）は障害物を無視
    if (piece.type == PieceType.shinobi) {
      // 桂馬動きは障害物無視、斜め動きは通常通り
      for (final move in moves) {
        final dr = (move.to.row - from.row).abs();
        if (dr == 2) {
          // 桂馬動き
          filtered.add(move);
        } else {
          // 斜め動きは経路チェック
          if (!_isPathBlocked(from, move.to, height)) {
            filtered.add(move);
          }
        }
      }
      return filtered;
    }

    for (final move in moves) {
      if (!_isPathBlocked(from, move.to, height)) {
        filtered.add(move);
      }
    }

    return filtered;
  }

  /// 経路が塞がれているかチェック
  bool _isPathBlocked(Position from, Position to, int myHeight) {
    final dr = (to.row - from.row).sign;
    final dc = (to.col - from.col).sign;

    // 隣接マスへの移動は経路チェック不要
    if ((to.row - from.row).abs() <= 1 && (to.col - from.col).abs() <= 1) {
      return false;
    }

    var current = from.offset(dr, dc);
    while (current != to && current.isValid) {
      final stack = state.board.getStack(current);
      if (stack.isNotEmpty) {
        // 経路上に自分より高い駒があれば通過不可
        if (stack.height > myHeight) {
          return true;
        }
      }
      current = current.offset(dr, dc);
    }

    return false;
  }

  /// 手駒からの配置（新）の合法手を生成
  List<Move> _generateDropMoves() {
    final moves = <Move>[];
    final player = state.currentPlayer;
    final handPieces = state.handPieces[player] ?? [];

    if (handPieces.isEmpty) return moves;

    // 最前線を取得
    final frontLine = state.board.getFrontLine(player);

    for (final piece in handPieces) {
      for (int r = 0; r < boardSize; r++) {
        // 最前線より前には置けない
        if (player == Player.white && r > frontLine) continue;
        if (player == Player.black && r < frontLine) continue;

        for (int c = 0; c < boardSize; c++) {
          final pos = Position(r, c);
          final stack = state.board.getStack(pos);

          if (stack.isEmpty) {
            // 空マスへの配置
            moves.add(Move.drop(
              piece: piece,
              to: pos,
              player: player,
            ));
          } else if (stack.controller == player) {
            // 自駒の上への配置（スタック高さ制限チェック）
            if (stack.height + 1 <= state.ruleLevel.maxHeight) {
              moves.add(Move.drop(
                piece: piece,
                to: pos,
                player: player,
              ));
            }
          }
          // 敵駒の上への新は不可
        }
      }
    }

    return moves;
  }

  /// 指定の指し手が合法かチェック
  bool isLegalMove(Move move) {
    final legalMoves = generateAllLegalMoves();
    return legalMoves.any((m) =>
        m.piece.id == move.piece.id &&
        m.from == move.from &&
        m.to == move.to &&
        m.type == move.type);
  }
}
