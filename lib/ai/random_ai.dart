import 'dart:math';

import '../logic/move_validator.dart';
import '../models/game_state.dart';
import '../models/move.dart';
import '../utils/constants.dart';
import 'ai_player.dart';

/// ランダムAI（初級）
/// 合法手からランダムに選択する
class RandomAi implements AiPlayer {
  final Random _random;

  RandomAi({int? seed}) : _random = Random(seed);

  @override
  AiDifficulty get difficulty => AiDifficulty.easy;

  @override
  String get name => 'ランダムAI';

  @override
  Future<Move> selectMove(GameState state) async {
    final validator = MoveValidator(state);
    final legalMoves = validator.generateAllLegalMoves();

    if (legalMoves.isEmpty) {
      throw StateError('合法手がありません');
    }

    // 帥を取れる手があれば優先
    final captureSui = legalMoves.where((m) {
      if (m.type != MoveType.capture) return false;
      final target = state.board.getPiece(m.to);
      return target?.type == PieceType.sui;
    }).toList();

    if (captureSui.isNotEmpty) {
      return captureSui[_random.nextInt(captureSui.length)];
    }

    // ランダムに選択
    return legalMoves[_random.nextInt(legalMoves.length)];
  }
}
