import '../utils/constants.dart';
import 'piece.dart';
import 'position.dart';

/// 指し手の種類
enum MoveType {
  move, // 移動
  capture, // 捕獲
  stack, // ツケ（自駒の上に乗る）
  attackStack, // ツケ（敵駒の上に乗る）
  drop, // 新（手駒から配置）
}

/// 指し手クラス
class Move {
  final MoveType type;
  final Piece piece;
  final Position? from; // 移動元（dropの場合はnull）
  final Position to; // 移動先
  final Player player;

  const Move({
    required this.type,
    required this.piece,
    this.from,
    required this.to,
    required this.player,
  });

  /// 移動の指し手を作成
  factory Move.move({
    required Piece piece,
    required Position from,
    required Position to,
    required Player player,
  }) {
    return Move(
      type: MoveType.move,
      piece: piece,
      from: from,
      to: to,
      player: player,
    );
  }

  /// 捕獲の指し手を作成
  factory Move.capture({
    required Piece piece,
    required Position from,
    required Position to,
    required Player player,
  }) {
    return Move(
      type: MoveType.capture,
      piece: piece,
      from: from,
      to: to,
      player: player,
    );
  }

  /// ツケ（スタック）の指し手を作成
  factory Move.stack({
    required Piece piece,
    required Position from,
    required Position to,
    required Player player,
    required bool isAttack,
  }) {
    return Move(
      type: isAttack ? MoveType.attackStack : MoveType.stack,
      piece: piece,
      from: from,
      to: to,
      player: player,
    );
  }

  /// 新（ドロップ）の指し手を作成
  factory Move.drop({
    required Piece piece,
    required Position to,
    required Player player,
  }) {
    return Move(
      type: MoveType.drop,
      piece: piece,
      from: null,
      to: to,
      player: player,
    );
  }

  /// 棋譜表記
  String toNotation() {
    final typeStr = switch (type) {
      MoveType.move => '',
      MoveType.capture => 'x',
      MoveType.stack => '+',
      MoveType.attackStack => '+x',
      MoveType.drop => '*',
    };

    if (type == MoveType.drop) {
      return '${piece.kanji}$typeStr${to.toNotation()}';
    } else {
      return '${piece.kanji}${from!.toNotation()}$typeStr${to.toNotation()}';
    }
  }

  @override
  String toString() => toNotation();
}
