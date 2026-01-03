import '../logic/move_validator.dart';
import '../models/game_state.dart';
import '../models/position.dart';
import '../utils/constants.dart';

/// 局面評価関数
/// 軍儀の戦略理論に基づいた評価を行う
class Evaluation {
  // =========================================================================
  // 駒の基本価値
  // =========================================================================
  /// 駒の基本価値
  /// - 帥は最高価値（これを取られたら負け）
  /// - 大・中・馬は高機動力で攻守に優れる
  /// - 謀は寝返り能力で敵駒を奪えるため高価値
  /// - 砦は移動できないが防御の要
  static const Map<PieceType, int> pieceValues = {
    PieceType.sui: 10000, // 帥：王将相当、絶対守るべき駒
    PieceType.dai: 900, // 大：全方向に移動可能、最強の攻撃駒
    PieceType.chu: 700, // 中：大に次ぐ機動力
    PieceType.sho: 500, // 小：中距離の機動力
    PieceType.samurai: 600, // 侍：斜め方向に強い
    PieceType.shinobi: 550, // 忍：桂馬跳びで障害物を越える特殊能力
    PieceType.hei: 100, // 兵：最弱だが数が多く前線維持に重要
    PieceType.yari: 400, // 槍：前方向に長い攻撃範囲
    PieceType.uma: 650, // 馬：斜め方向の機動力が高い
    PieceType.toride: 300, // 砦：移動不可だが守りの要、ツケの土台として優秀
    PieceType.yumi: 500, // 弓：飛び駒、障害物を越えて攻撃可能
    PieceType.hou: 600, // 砲：3マス直進、奇襲に有効
    PieceType.tsutsu: 450, // 筒：特殊な動き
    PieceType.bou: 800, // 謀：敵駒の上にツケて寝返らせる唯一の駒、戦況を一変させる
  };

  // =========================================================================
  // 戦略的評価
  // =========================================================================

  /// 局面を評価（指定プレイヤー視点）
  /// 正の値 = 有利、負の値 = 不利
  static int evaluate(GameState state, Player player) {
    // 終局判定
    if (state.phase == GamePhase.finished) {
      if (state.winner == player) {
        return 100000; // 勝ち
      } else if (state.winner != null) {
        return -100000; // 負け
      }
      return 0; // 引き分け
    }

    int score = 0;
    final opponent = player.opponent;

    // 1. 駒の価値と位置評価
    score += _evaluatePieces(state, player, opponent);

    // 2. 手駒の評価
    score += _evaluateHandPieces(state, player, opponent);

    // 3. 帥の安全性（非常に重要）
    score += _evaluateSuiSafety(state, player) * 2;
    score -= _evaluateSuiSafety(state, opponent) * 2;

    // 4. 前線の支配（新の配置範囲に影響）
    score += _evaluateFrontLine(state, player);
    score -= _evaluateFrontLine(state, opponent);

    // 5. 中央支配（盤面の要所）
    score += _evaluateCenterControl(state, player);
    score -= _evaluateCenterControl(state, opponent);

    // 6. 機動力（選択肢の多さ）
    score += _evaluateMobility(state, player);

    // 7. 駒の連携（相互防御）
    score += _evaluatePieceCoordination(state, player);
    score -= _evaluatePieceCoordination(state, opponent);

    // 8. スタックの戦略的価値
    score += _evaluateStackStrategy(state, player);
    score -= _evaluateStackStrategy(state, opponent);

    return score;
  }

  /// 駒の価値と位置評価
  static int _evaluatePieces(GameState state, Player player, Player opponent) {
    int score = 0;

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final pos = Position(r, c);
        final stack = state.board.getStack(pos);

        if (stack.isEmpty) continue;

        for (int i = 0; i < stack.height; i++) {
          final piece = stack.pieceAt(i)!;
          final baseValue = pieceValues[piece.type] ?? 0;

          if (piece.owner == player) {
            score += baseValue;
            score += _positionBonus(pos, player, piece.type);
            if (i == stack.height - 1) {
              score += _heightBonus(stack.height);
            }
          } else {
            score -= baseValue;
            score -= _positionBonus(pos, opponent, piece.type);
            if (i == stack.height - 1) {
              score -= _heightBonus(stack.height);
            }
          }
        }
      }
    }

    return score;
  }

  /// 位置ボーナス
  /// - 中央に近いほど有利（どの方向にも展開しやすい）
  /// - 駒の種類によって最適な位置が異なる
  static int _positionBonus(Position pos, Player player, PieceType type) {
    int bonus = 0;

    // 中央に近いほどボーナス（盤面制圧に有利）
    final centerRow = 4;
    final centerCol = 4;
    final centerDistance =
        (pos.row - centerRow).abs() + (pos.col - centerCol).abs();
    bonus += (8 - centerDistance) * 5;

    // 駒タイプ別の位置評価
    switch (type) {
      case PieceType.sui:
        // 帥は後方にいるほど安全
        // 先手(white)はrow小さい方が後方、後手(black)はrow大きい方が後方
        if (player == Player.white) {
          bonus += (3 - pos.row) * 15; // row 0-2が安全地帯
        } else {
          bonus += (pos.row - 5) * 15; // row 6-8が安全地帯
        }
        break;

      case PieceType.hei:
      case PieceType.yari:
        // 兵・槍は前進するほど価値が高い（前線維持）
        if (player == Player.white) {
          bonus += pos.row * 8;
        } else {
          bonus += (8 - pos.row) * 8;
        }
        break;

      case PieceType.dai:
      case PieceType.chu:
      case PieceType.uma:
        // 攻撃駒は中央付近が最も活躍できる
        bonus += (8 - centerDistance) * 8;
        break;

      case PieceType.toride:
        // 砦は後方（自陣）にいると防御力が高い
        // 帥の近くにあることが多いため、後方配置にボーナス
        if (player == Player.white) {
          bonus += (3 - pos.row) * 10; // 先手は後方（row小さい）
        } else {
          bonus += (pos.row - 5) * 10; // 後手は後方（row大きい）
        }
        break;

      default:
        // その他の駒は軽い前進ボーナス
        if (player == Player.white) {
          bonus += pos.row * 3;
        } else {
          bonus += (8 - pos.row) * 3;
        }
    }

    return bonus;
  }

  /// 高さボーナス
  /// - スタックが高いほど移動距離が伸びる
  /// - 高さ2で+1マス、高さ3で+2マス移動可能
  /// - 高い駒は低い駒から攻撃されにくい
  static int _heightBonus(int height) {
    // 高さ1: 0, 高さ2: 60, 高さ3: 150
    return switch (height) {
      1 => 0,
      2 => 60, // 移動距離+1、低い駒からの攻撃回避
      3 => 150, // 移動距離+2、非常に強力
      _ => 0,
    };
  }

  /// 手駒の評価
  /// - 手駒は盤上より価値が低い（まだ配置されていないため）
  /// - ただし「新」で好きな位置に配置できる柔軟性がある
  static int _evaluateHandPieces(
      GameState state, Player player, Player opponent) {
    int score = 0;

    for (final piece in state.handPieces[player] ?? []) {
      // 手駒は盤上の80%の価値（配置の柔軟性を考慮）
      score += (pieceValues[piece.type] ?? 0) * 80 ~/ 100;
    }
    for (final piece in state.handPieces[opponent] ?? []) {
      score -= (pieceValues[piece.type] ?? 0) * 80 ~/ 100;
    }

    return score;
  }

  /// 帥の安全性評価
  /// - 軍儀で最も重要な評価項目
  /// - 帥を守ることが勝利への第一歩
  static int _evaluateSuiSafety(GameState state, Player player) {
    final suiPos = state.board.findSui(player);
    if (suiPos == null) return -10000; // 帥がない = 負け確定

    int safety = 0;

    // 1. 帥が後方にいるほど安全
    if (player == Player.white) {
      safety += (3 - suiPos.row) * 20;
    } else {
      safety += (suiPos.row - 5) * 20;
    }

    // 2. 周囲に味方の駒があるほど安全（護衛）
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final neighbor = suiPos.offset(dr, dc);
        if (!neighbor.isValid) continue;
        final stack = state.board.getStack(neighbor);
        if (stack.isNotEmpty && stack.controller == player) {
          safety += 25; // 護衛1枚につき+25
        }
      }
    }

    // 3. 帥がスタックの下にいる場合は非常に安全
    // （上の駒を取らないと帥に触れない）
    final suiStack = state.board.getStack(suiPos);
    if (suiStack.height >= 2) {
      // 帥が最上部でなければ守られている
      bool suiOnTop = suiStack.top?.type == PieceType.sui;
      if (!suiOnTop) {
        safety += 100; // 帥の上に駒がある = 非常に安全
      }
    }

    // 4. 帥の周囲に敵駒がいると危険
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final neighbor = suiPos.offset(dr, dc);
        if (!neighbor.isValid) continue;
        final stack = state.board.getStack(neighbor);
        if (stack.isNotEmpty && stack.controller != player) {
          safety -= 40; // 敵が隣接 = 危険
        }
      }
    }

    // 5. 角にいると逃げ場が少ない（ペナルティ）
    final isCorner = (suiPos.row == 0 || suiPos.row == 8) &&
        (suiPos.col == 0 || suiPos.col == 8);
    if (isCorner) {
      safety -= 30;
    }

    // 6. 端にいると逃げ場が制限される（軽いペナルティ）
    final isEdge = suiPos.row == 0 ||
        suiPos.row == 8 ||
        suiPos.col == 0 ||
        suiPos.col == 8;
    if (isEdge && !isCorner) {
      safety -= 15;
    }

    return safety;
  }

  /// 前線評価
  /// - 前線が押し上がっているほど「新」の配置範囲が広がる
  /// - 敵陣に食い込むと攻撃の選択肢が増える
  static int _evaluateFrontLine(GameState state, Player player) {
    final frontLine = state.board.getFrontLine(player);
    int bonus = 0;

    if (player == Player.white) {
      // 先手は前線が高いほど良い（row大きい = 敵陣に近い）
      bonus = frontLine * 15;
    } else {
      // 後手は前線が低いほど良い（row小さい = 敵陣に近い）
      bonus = (8 - frontLine) * 15;
    }

    return bonus;
  }

  /// 中央支配評価
  /// - 中央（4,4を中心とした3x3）を支配すると盤面全体に影響力を持つ
  /// - 将棋でいう「玉は囲え、飛車角を使え、中央を制圧せよ」に相当
  static int _evaluateCenterControl(GameState state, Player player) {
    int controlScore = 0;

    // 中央の3x3マス
    for (int r = 3; r <= 5; r++) {
      for (int c = 3; c <= 5; c++) {
        final pos = Position(r, c);
        final stack = state.board.getStack(pos);
        if (stack.isNotEmpty && stack.controller == player) {
          // 中央に駒がある
          controlScore += 30;
          // 高さがあるとさらにボーナス
          controlScore += stack.height * 10;
        }
      }
    }

    return controlScore;
  }

  /// 機動力評価
  /// - 合法手が多いほど選択肢が豊富で有利
  /// - 相手の手を制限しつつ、自分の手を増やすのが理想
  static int _evaluateMobility(GameState state, Player player) {
    // 現在の手番のプレイヤーの機動力のみ評価（計算コスト削減）
    if (state.currentPlayer != player) return 0;

    final validator = MoveValidator(state);
    final moves = validator.generateAllLegalMoves();

    // 合法手数に応じたボーナス（上限あり）
    final moveCount = moves.length;
    return (moveCount * 2).clamp(0, 100);
  }

  /// 駒の連携評価
  /// - 駒同士が守り合う配置は堅固
  /// - 相手の駒を複数の駒で狙える状況は有利
  static int _evaluatePieceCoordination(GameState state, Player player) {
    int coordination = 0;

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final pos = Position(r, c);
        final stack = state.board.getStack(pos);
        if (stack.isEmpty || stack.controller != player) continue;

        // 隣接する味方駒の数をカウント
        int adjacentAllies = 0;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final neighbor = pos.offset(dr, dc);
            if (!neighbor.isValid) continue;
            final neighborStack = state.board.getStack(neighbor);
            if (neighborStack.isNotEmpty && neighborStack.controller == player) {
              adjacentAllies++;
            }
          }
        }

        // 連携している駒にボーナス
        coordination += adjacentAllies * 5;
      }
    }

    return coordination;
  }

  /// スタック戦略評価
  /// - ツケ（スタック）は軍儀特有の重要な戦術
  /// - 適切なスタックは攻防両面で有利
  static int _evaluateStackStrategy(GameState state, Player player) {
    int stackScore = 0;

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final pos = Position(r, c);
        final stack = state.board.getStack(pos);
        if (stack.isEmpty || stack.controller != player) continue;

        if (stack.height >= 2) {
          // スタックがある

          // 1. 帥の上にツケ = 守りの形
          bool hasSuiBelow = false;
          for (int i = 0; i < stack.height - 1; i++) {
            if (stack.pieceAt(i)?.type == PieceType.sui) {
              hasSuiBelow = true;
              break;
            }
          }
          if (hasSuiBelow) {
            stackScore += 80; // 帥を守るスタック
          }

          // 2. 砦の上にツケ = 防御の拠点
          if (stack.pieceAt(0)?.type == PieceType.toride) {
            stackScore += 40; // 砦は動けないが土台として優秀
          }

          // 3. 攻撃駒が上にいる高スタック = 攻撃力が高い
          final topPiece = stack.top;
          if (topPiece != null) {
            final isAttacker = topPiece.type == PieceType.dai ||
                topPiece.type == PieceType.chu ||
                topPiece.type == PieceType.uma;
            if (isAttacker && stack.height >= 2) {
              stackScore += 30 * stack.height; // 高い攻撃駒は脅威
            }
          }
        }
      }
    }

    return stackScore;
  }
}
