import '../models/game_state.dart';
import '../models/move.dart';

/// AI難易度
enum AiDifficulty {
  easy, // ランダム
  medium, // ミニマックス（浅い探索）
  hard, // ミニマックス（深い探索）
}

/// AIプレイヤーの抽象インターフェース
abstract class AiPlayer {
  /// AI難易度
  AiDifficulty get difficulty;

  /// 次の手を選択
  Future<Move> selectMove(GameState state);

  /// AIの名前
  String get name;
}
