import 'dart:math';

import '../logic/move_validator.dart';
import '../models/game_state.dart';
import '../models/move.dart';
import '../utils/constants.dart';
import 'ai_player.dart';
import 'evaluation.dart';

/// ミニマックスAI（中級〜上級）
/// アルファベータ枝刈りとムーブオーダリングで効率的に探索
///
/// 軍儀AIの戦略方針:
/// 1. 帥の安全を最優先（取られたら負け）
/// 2. 高価値駒の捕獲を狙う
/// 3. 中央支配と前線維持
/// 4. ツケ（スタック）を活用した攻防
class MinimaxAi implements AiPlayer {
  final int _depth;
  final Random _random;
  final Player _aiPlayer;
  final int _maxMovesToConsider;

  MinimaxAi({
    required Player aiPlayer,
    int depth = 3,
    int? seed,
    int maxMovesToConsider = 20,
  })  : _aiPlayer = aiPlayer,
        _depth = depth,
        _random = Random(seed),
        _maxMovesToConsider = maxMovesToConsider;

  @override
  AiDifficulty get difficulty =>
      _depth <= 2 ? AiDifficulty.medium : AiDifficulty.hard;

  @override
  String get name => _depth <= 2 ? '中級AI' : '上級AI';

  @override
  Future<Move> selectMove(GameState state) async {
    final validator = MoveValidator(state);
    final legalMoves = validator.generateAllLegalMoves();

    if (legalMoves.isEmpty) {
      throw StateError('合法手がありません');
    }

    // =========================================================================
    // 即座に勝利できる手があれば実行（帥を取る）
    // =========================================================================
    final captureSui = legalMoves.where((m) {
      if (m.type != MoveType.capture) return false;
      final target = state.board.getPiece(m.to);
      return target?.type == PieceType.sui;
    }).toList();

    if (captureSui.isNotEmpty) {
      return captureSui.first;
    }

    // =========================================================================
    // 手を戦略的優先度でソート（良い手を先に探索）
    // =========================================================================
    final sortedMoves = _orderMoves(legalMoves, state);

    // 探索する手数を制限（計算量削減）
    final movesToSearch = sortedMoves.take(_maxMovesToConsider).toList();

    // =========================================================================
    // ミニマックス探索で各手を評価
    // =========================================================================
    final moveScores = <Move, int>{};
    int alpha = -1000000;
    const beta = 1000000;

    for (int i = 0; i < movesToSearch.length; i++) {
      final move = movesToSearch[i];
      final newState = state.applyMove(move);
      final score = _minimax(newState, _depth - 1, alpha, beta, false);
      moveScores[move] = score;
      if (score > alpha) {
        alpha = score;
      }
      // 毎回UIスレッドに制御を返してアニメーションを継続
      await Future.delayed(const Duration(milliseconds: 1));
    }

    // 最高スコアの手を選択（同点の場合はランダム）
    final maxScore = moveScores.values.reduce(max);
    final bestMoves = moveScores.entries
        .where((e) => e.value == maxScore)
        .map((e) => e.key)
        .toList();

    return bestMoves[_random.nextInt(bestMoves.length)];
  }

  /// 手を戦略的優先度でソート（ムーブオーダリング）
  ///
  /// 良い手を先に探索することで、アルファベータ枝刈りの効率が上がる
  /// 優先順位:
  /// 1. 高価値駒の捕獲
  /// 2. 帥を脅かす手
  /// 3. 敵駒へのツケ（謀の寝返り含む）
  /// 4. 中央への進出
  /// 5. 前進
  List<Move> _orderMoves(List<Move> moves, GameState state) {
    return moves.toList()
      ..sort((a, b) {
        final scoreA = _getMoveOrderScore(a, state);
        final scoreB = _getMoveOrderScore(b, state);
        return scoreB.compareTo(scoreA); // 降順
      });
  }

  /// 手の優先度スコア（高いほど先に探索）
  int _getMoveOrderScore(Move move, GameState state) {
    int score = 0;

    // =========================================================================
    // 捕獲の評価（高価値駒を取るほど優先）
    // =========================================================================
    if (move.type == MoveType.capture) {
      score += 2000; // 捕獲は基本的に良い手

      final target = state.board.getPiece(move.to);
      if (target != null) {
        // 取る駒の価値を加算
        // 例: 大(900)を取る > 兵(100)を取る
        score += Evaluation.pieceValues[target.type] ?? 0;

        // 自分より価値の低い駒で高価値駒を取れれば大きなボーナス
        // （駒得になる交換）
        final myValue = Evaluation.pieceValues[move.piece.type] ?? 0;
        final targetValue = Evaluation.pieceValues[target.type] ?? 0;
        if (targetValue > myValue) {
          score += (targetValue - myValue); // 駒得ボーナス
        }
      }
    }

    // =========================================================================
    // ツケ（スタック）の評価
    // =========================================================================
    if (move.type == MoveType.attackStack) {
      // 敵駒へのツケ
      score += 1000;

      // 謀による寝返りは非常に強力
      // 敵駒を自軍に変えられる唯一の手段
      if (move.piece.type == PieceType.bou) {
        score += 1500; // 謀のツケは最優先級
      }
    }

    if (move.type == MoveType.stack) {
      // 味方駒へのツケ
      score += 300;

      // 帥の上にツケ = 守りを固める
      final targetStack = state.board.getStack(move.to);
      for (final piece in targetStack.pieces) {
        if (piece.type == PieceType.sui && piece.owner == _aiPlayer) {
          score += 500; // 帥を守るツケは高優先
        }
      }
    }

    // =========================================================================
    // 帥への脅威（チェック）
    // =========================================================================
    final opponentSuiPos = state.board.findSui(_aiPlayer.opponent);
    if (opponentSuiPos != null) {
      // 敵の帥に隣接できる手は脅威になる
      final distToSui = (move.to.row - opponentSuiPos.row).abs() +
          (move.to.col - opponentSuiPos.col).abs();
      if (distToSui == 1) {
        score += 800; // 帥に隣接 = 非常に危険な位置
      } else if (distToSui == 2) {
        score += 300; // 帥に近づく
      }
    }

    // =========================================================================
    // 中央支配（盤面の要所を押さえる）
    // =========================================================================
    final centerDist = (move.to.row - 4).abs() + (move.to.col - 4).abs();
    // 中央に近いほどボーナス
    // 中央を支配すると、どの方向にも展開しやすく有利
    score += (8 - centerDist) * 15;

    // =========================================================================
    // 前進（前線を押し上げて「新」の範囲を広げる）
    // =========================================================================
    if (_aiPlayer == Player.black) {
      // 後手はrow小さい方が前進（敵陣に向かう）
      score += (8 - move.to.row) * 10;
    } else {
      // 先手はrow大きい方が前進
      score += move.to.row * 10;
    }

    // =========================================================================
    // 高機動駒の活用
    // =========================================================================
    // 大・中・馬などの高機動駒を動かすことを優先
    // これらの駒は攻守に活躍できる
    if (move.piece.type == PieceType.dai ||
        move.piece.type == PieceType.chu ||
        move.piece.type == PieceType.uma) {
      score += 50;
    }

    // =========================================================================
    // 新（手駒からの配置）
    // =========================================================================
    if (move.type == MoveType.drop) {
      // 手駒配置は状況による
      score += 100;

      // 帥の近くに配置して守りを固める
      final mySuiPos = state.board.findSui(_aiPlayer);
      if (mySuiPos != null) {
        final distToMySui =
            (move.to.row - mySuiPos.row).abs() + (move.to.col - mySuiPos.col).abs();
        if (distToMySui <= 2) {
          score += 150; // 帥の護衛
        }
      }

      // 敵陣に新を打つのは攻撃的
      if (_aiPlayer == Player.black && move.to.row <= 3) {
        score += 100;
      } else if (_aiPlayer == Player.white && move.to.row >= 5) {
        score += 100;
      }
    }

    return score;
  }

  /// ミニマックス探索（アルファベータ枝刈り）
  ///
  /// - isMaximizing=true: AIの手番（スコアを最大化）
  /// - isMaximizing=false: 相手の手番（スコアを最小化）
  int _minimax(
    GameState state,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
  ) {
    // 終局または深さ0で評価
    if (depth == 0 || state.phase == GamePhase.finished) {
      return Evaluation.evaluate(state, _aiPlayer);
    }

    final validator = MoveValidator(state);
    var legalMoves = validator.generateAllLegalMoves();

    if (legalMoves.isEmpty) {
      return Evaluation.evaluate(state, _aiPlayer);
    }

    // 深い探索では手を制限（計算量削減）
    // 浅い層ではより多くの手を検討
    final moveLimit = depth >= _depth - 1 ? 20 : 12;
    legalMoves = _orderMoves(legalMoves, state).take(moveLimit).toList();

    if (isMaximizing) {
      int maxEval = -1000000;
      for (final move in legalMoves) {
        final newState = state.applyMove(move);
        final eval = _minimax(newState, depth - 1, alpha, beta, false);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break; // ベータカット（相手はこれより良い手がある）
      }
      return maxEval;
    } else {
      int minEval = 1000000;
      for (final move in legalMoves) {
        final newState = state.applyMove(move);
        final eval = _minimax(newState, depth - 1, alpha, beta, true);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break; // アルファカット（自分はこれより良い手がある）
      }
      return minEval;
    }
  }
}
