import '../models/position.dart';
import '../utils/constants.dart';

/// 移動方向
class Direction {
  final int dr;
  final int dc;

  const Direction(this.dr, this.dc);

  static const up = Direction(1, 0);
  static const down = Direction(-1, 0);
  static const left = Direction(0, -1);
  static const right = Direction(0, 1);
  static const upLeft = Direction(1, -1);
  static const upRight = Direction(1, 1);
  static const downLeft = Direction(-1, -1);
  static const downRight = Direction(-1, 1);

  // 桂馬風の動き
  static const knightUpLeft = Direction(2, -1);
  static const knightUpRight = Direction(2, 1);
  static const knightDownLeft = Direction(-2, -1);
  static const knightDownRight = Direction(-2, 1);
}

/// 移動パターン
class MovePattern {
  final List<Direction> directions; // 移動方向
  final int baseRange; // 基本移動距離（0=無制限）
  final bool isJump; // 飛び越え可能か

  const MovePattern({
    required this.directions,
    this.baseRange = 1,
    this.isJump = false,
  });
}

/// 駒ごとの移動ルール定義
class PieceMovement {
  /// 各駒タイプの段数別移動パターン
  /// key: (PieceType, stackHeight) -> MovePattern list
  static final Map<PieceType, List<MovePattern>> _basePatterns = {
    // 帥: 全方向1マス（段数で変化なし）
    PieceType.sui: [
      MovePattern(
        directions: [
          Direction.up,
          Direction.down,
          Direction.left,
          Direction.right,
          Direction.upLeft,
          Direction.upRight,
          Direction.downLeft,
          Direction.downRight,
        ],
        baseRange: 1,
      ),
    ],

    // 大: 前方向と斜め後ろ
    PieceType.dai: [
      MovePattern(
        directions: [
          Direction.up,
          Direction.upLeft,
          Direction.upRight,
          Direction.downLeft,
          Direction.downRight,
        ],
        baseRange: 1,
      ),
    ],

    // 中: 縦横1マス
    PieceType.chu: [
      MovePattern(
        directions: [
          Direction.up,
          Direction.down,
          Direction.left,
          Direction.right,
        ],
        baseRange: 1,
      ),
    ],

    // 小: 前と斜め前1マス
    PieceType.sho: [
      MovePattern(
        directions: [
          Direction.up,
          Direction.upLeft,
          Direction.upRight,
        ],
        baseRange: 1,
      ),
    ],

    // 侍: 斜め4方向
    PieceType.samurai: [
      MovePattern(
        directions: [
          Direction.upLeft,
          Direction.upRight,
          Direction.downLeft,
          Direction.downRight,
        ],
        baseRange: 1,
      ),
    ],

    // 忍: 桂馬風の動き+斜め
    PieceType.shinobi: [
      MovePattern(
        directions: [
          Direction.knightUpLeft,
          Direction.knightUpRight,
        ],
        baseRange: 1,
        isJump: true,
      ),
      MovePattern(
        directions: [
          Direction.upLeft,
          Direction.upRight,
        ],
        baseRange: 1,
      ),
    ],

    // 兵: 前1マス
    PieceType.hei: [
      MovePattern(
        directions: [Direction.up],
        baseRange: 1,
      ),
    ],

    // 槍: 前後に動く
    PieceType.yari: [
      MovePattern(
        directions: [Direction.up, Direction.down],
        baseRange: 1,
      ),
    ],

    // 馬: 縦横に動く
    PieceType.uma: [
      MovePattern(
        directions: [
          Direction.up,
          Direction.down,
          Direction.left,
          Direction.right,
        ],
        baseRange: 1,
      ),
    ],

    // 砦: 移動不可（防御専用）
    PieceType.toride: [],

    // 弓: 斜め前方に飛ぶ
    PieceType.yumi: [
      MovePattern(
        directions: [
          Direction.upLeft,
          Direction.upRight,
        ],
        baseRange: 0, // 無制限
        isJump: false,
      ),
    ],

    // 砲: 前方に3マス直進
    PieceType.hou: [
      MovePattern(
        directions: [Direction.up],
        baseRange: 3,
        isJump: false,
      ),
    ],

    // 筒: 横方向に動く
    PieceType.tsutsu: [
      MovePattern(
        directions: [
          Direction.left,
          Direction.right,
        ],
        baseRange: 0, // 無制限
      ),
    ],

    // 謀: 全方向1マス
    PieceType.bou: [
      MovePattern(
        directions: [
          Direction.up,
          Direction.down,
          Direction.left,
          Direction.right,
          Direction.upLeft,
          Direction.upRight,
          Direction.downLeft,
          Direction.downRight,
        ],
        baseRange: 1,
      ),
    ],
  };

  /// 指定された駒タイプとスタック高さで移動可能な位置を計算
  static List<Position> getLegalPositions({
    required PieceType type,
    required Position from,
    required int stackHeight,
    required Player owner,
  }) {
    final positions = <Position>[];
    final patterns = _basePatterns[type] ?? [];

    // プレイヤーによる方向補正（後手は反転）
    final directionMultiplier = owner == Player.white ? 1 : -1;

    for (final pattern in patterns) {
      for (final dir in pattern.directions) {
        // 段数による移動距離の延長
        int range = pattern.baseRange;
        if (range > 0 && type != PieceType.sui) {
          // 帥以外は段数で延長
          range += (stackHeight - 1);
        }

        // 方向を補正
        final dr = dir.dr * directionMultiplier;
        final dc = dir.dc;

        if (range == 0) {
          // 無制限移動
          for (int i = 1; i < boardSize; i++) {
            final newPos = from.offset(dr * i, dc * i);
            if (!newPos.isValid) continue;
            positions.add(newPos);
          }
        } else {
          // 制限付き移動
          for (int i = 1; i <= range; i++) {
            final newPos = from.offset(dr * i, dc * i);
            if (!newPos.isValid) continue;
            positions.add(newPos);
          }
        }
      }
    }

    return positions;
  }

  /// 駒が移動可能かどうか
  static bool canMove(PieceType type) {
    return type != PieceType.toride;
  }
}
