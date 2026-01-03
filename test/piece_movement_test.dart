// 駒移動ロジックの単体テスト
import 'package:flutter_test/flutter_test.dart';
import 'package:gungi/logic/piece_movement.dart';
import 'package:gungi/models/position.dart';
import 'package:gungi/utils/constants.dart';

void main() {
  group('Direction（移動方向）のテスト', () {
    test('基本方向が正しく定義されている', () {
      expect(Direction.up.dr, 1);
      expect(Direction.up.dc, 0);
      expect(Direction.down.dr, -1);
      expect(Direction.down.dc, 0);
      expect(Direction.left.dr, 0);
      expect(Direction.left.dc, -1);
      expect(Direction.right.dr, 0);
      expect(Direction.right.dc, 1);
    });

    test('斜め方向が正しく定義されている', () {
      expect(Direction.upLeft.dr, 1);
      expect(Direction.upLeft.dc, -1);
      expect(Direction.upRight.dr, 1);
      expect(Direction.upRight.dc, 1);
      expect(Direction.downLeft.dr, -1);
      expect(Direction.downLeft.dc, -1);
      expect(Direction.downRight.dr, -1);
      expect(Direction.downRight.dc, 1);
    });

    test('桂馬風の動きが正しく定義されている', () {
      expect(Direction.knightUpLeft.dr, 2);
      expect(Direction.knightUpLeft.dc, -1);
      expect(Direction.knightUpRight.dr, 2);
      expect(Direction.knightUpRight.dc, 1);
      expect(Direction.knightDownLeft.dr, -2);
      expect(Direction.knightDownLeft.dc, -1);
      expect(Direction.knightDownRight.dr, -2);
      expect(Direction.knightDownRight.dc, 1);
    });
  });

  group('帥（sui）の移動テスト', () {
    test('帥は全方向1マスに移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.sui,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      // 全方向8マスに移動可能
      expect(positions.length, 8);
      expect(positions.contains(Position(5, 4)), true); // 上
      expect(positions.contains(Position(3, 4)), true); // 下
      expect(positions.contains(Position(4, 3)), true); // 左
      expect(positions.contains(Position(4, 5)), true); // 右
      expect(positions.contains(Position(5, 3)), true); // 左上
      expect(positions.contains(Position(5, 5)), true); // 右上
      expect(positions.contains(Position(3, 3)), true); // 左下
      expect(positions.contains(Position(3, 5)), true); // 右下
    });

    test('帥はスタック高さで移動距離が伸びない', () {
      final positions1 = PieceMovement.getLegalPositions(
        type: PieceType.sui,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      final positions2 = PieceMovement.getLegalPositions(
        type: PieceType.sui,
        from: Position(4, 4),
        stackHeight: 2,
        owner: Player.white,
      );

      final positions3 = PieceMovement.getLegalPositions(
        type: PieceType.sui,
        from: Position(4, 4),
        stackHeight: 3,
        owner: Player.white,
      );

      // 帥は段数に関係なく1マスのみ
      expect(positions1.length, positions2.length);
      expect(positions2.length, positions3.length);
    });

    test('帥は盤面端でも正しく移動候補を生成する', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.sui,
        from: Position(0, 0),
        stackHeight: 1,
        owner: Player.white,
      );

      // 角では3マスのみ
      expect(positions.length, 3);
      expect(positions.contains(Position(1, 0)), true);
      expect(positions.contains(Position(0, 1)), true);
      expect(positions.contains(Position(1, 1)), true);
    });
  });

  group('兵（hei）の移動テスト', () {
    test('白の兵は前方（row+）に1マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.hei,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 1);
      expect(positions.first, Position(5, 4));
    });

    test('黒の兵は前方（row-）に1マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.hei,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.black,
      );

      expect(positions.length, 1);
      expect(positions.first, Position(3, 4));
    });

    test('兵はスタック高さ2で2マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.hei,
        from: Position(4, 4),
        stackHeight: 2,
        owner: Player.white,
      );

      expect(positions.length, 2);
      expect(positions.contains(Position(5, 4)), true);
      expect(positions.contains(Position(6, 4)), true);
    });

    test('兵はスタック高さ3で3マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.hei,
        from: Position(4, 4),
        stackHeight: 3,
        owner: Player.white,
      );

      expect(positions.length, 3);
      expect(positions.contains(Position(5, 4)), true);
      expect(positions.contains(Position(6, 4)), true);
      expect(positions.contains(Position(7, 4)), true);
    });
  });

  group('大（dai）の移動テスト', () {
    test('白の大は前方向と斜め後ろに移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.dai,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 5);
      expect(positions.contains(Position(5, 4)), true); // 上
      expect(positions.contains(Position(5, 3)), true); // 左上
      expect(positions.contains(Position(5, 5)), true); // 右上
      expect(positions.contains(Position(3, 3)), true); // 左下
      expect(positions.contains(Position(3, 5)), true); // 右下
    });

    test('黒の大は方向が反転する', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.dai,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.black,
      );

      expect(positions.length, 5);
      expect(positions.contains(Position(3, 4)), true); // 下（黒の前）
      expect(positions.contains(Position(3, 3)), true); // 左下（黒の左前）
      expect(positions.contains(Position(3, 5)), true); // 右下（黒の右前）
      expect(positions.contains(Position(5, 3)), true); // 左上（黒の左後）
      expect(positions.contains(Position(5, 5)), true); // 右上（黒の右後）
    });
  });

  group('中（chu）の移動テスト', () {
    test('中は縦横に1マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.chu,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 4);
      expect(positions.contains(Position(5, 4)), true); // 上
      expect(positions.contains(Position(3, 4)), true); // 下
      expect(positions.contains(Position(4, 3)), true); // 左
      expect(positions.contains(Position(4, 5)), true); // 右
    });
  });

  group('小（sho）の移動テスト', () {
    test('白の小は前と斜め前に1マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.sho,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 3);
      expect(positions.contains(Position(5, 4)), true); // 前
      expect(positions.contains(Position(5, 3)), true); // 左前
      expect(positions.contains(Position(5, 5)), true); // 右前
    });
  });

  group('侍（samurai）の移動テスト', () {
    test('侍は斜め4方向に1マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.samurai,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 4);
      expect(positions.contains(Position(5, 3)), true); // 左上
      expect(positions.contains(Position(5, 5)), true); // 右上
      expect(positions.contains(Position(3, 3)), true); // 左下
      expect(positions.contains(Position(3, 5)), true); // 右下
    });
  });

  group('忍（shinobi）の移動テスト', () {
    test('白の忍は桂馬風の動きと斜め前に移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.shinobi,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 4);
      // 桂馬風
      expect(positions.contains(Position(6, 3)), true);
      expect(positions.contains(Position(6, 5)), true);
      // 斜め前
      expect(positions.contains(Position(5, 3)), true);
      expect(positions.contains(Position(5, 5)), true);
    });
  });

  group('槍（yari）の移動テスト', () {
    test('白の槍は前後に1マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.yari,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 2);
      expect(positions.contains(Position(5, 4)), true); // 前
      expect(positions.contains(Position(3, 4)), true); // 後
    });

    test('槍はスタック高さ2で前後2マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.yari,
        from: Position(4, 4),
        stackHeight: 2,
        owner: Player.white,
      );

      expect(positions.length, 4);
      expect(positions.contains(Position(5, 4)), true);
      expect(positions.contains(Position(6, 4)), true);
      expect(positions.contains(Position(3, 4)), true);
      expect(positions.contains(Position(2, 4)), true);
    });
  });

  group('馬（uma）の移動テスト', () {
    test('馬は縦横に1マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.uma,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 4);
      expect(positions.contains(Position(5, 4)), true);
      expect(positions.contains(Position(3, 4)), true);
      expect(positions.contains(Position(4, 3)), true);
      expect(positions.contains(Position(4, 5)), true);
    });
  });

  group('砦（toride）の移動テスト', () {
    test('砦は移動できない', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.toride,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.isEmpty, true);
    });

    test('canMoveで砦は移動不可と判定される', () {
      expect(PieceMovement.canMove(PieceType.toride), false);
    });

    test('canMoveで他の駒は移動可能と判定される', () {
      expect(PieceMovement.canMove(PieceType.sui), true);
      expect(PieceMovement.canMove(PieceType.hei), true);
      expect(PieceMovement.canMove(PieceType.dai), true);
    });
  });

  group('弓（yumi）の移動テスト', () {
    test('白の弓は斜め前方に無制限に移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.yumi,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      // 斜め左上: (5,3), (6,2), (7,1), (8,0) = 4マス
      // 斜め右上: (5,5), (6,6), (7,7), (8,8) = 4マス
      expect(positions.length, 8);
      expect(positions.contains(Position(5, 3)), true);
      expect(positions.contains(Position(8, 0)), true);
      expect(positions.contains(Position(5, 5)), true);
      expect(positions.contains(Position(8, 8)), true);
    });
  });

  group('砲（hou）の移動テスト', () {
    test('白の砲は前方に3マス直進できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.hou,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 3);
      expect(positions.contains(Position(5, 4)), true);
      expect(positions.contains(Position(6, 4)), true);
      expect(positions.contains(Position(7, 4)), true);
    });

    test('砲はスタック高さ2で4マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.hou,
        from: Position(4, 4),
        stackHeight: 2,
        owner: Player.white,
      );

      expect(positions.length, 4);
      expect(positions.contains(Position(8, 4)), true);
    });
  });

  group('筒（tsutsu）の移動テスト', () {
    test('筒は横方向に無制限に移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.tsutsu,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      // 左: (4,3), (4,2), (4,1), (4,0) = 4マス
      // 右: (4,5), (4,6), (4,7), (4,8) = 4マス
      expect(positions.length, 8);
      expect(positions.contains(Position(4, 0)), true);
      expect(positions.contains(Position(4, 8)), true);
    });
  });

  group('謀（bou）の移動テスト', () {
    test('謀は全方向に1マス移動できる', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.bou,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      expect(positions.length, 8);
    });

    test('謀はスタック高さで移動距離が伸びる', () {
      final positions1 = PieceMovement.getLegalPositions(
        type: PieceType.bou,
        from: Position(4, 4),
        stackHeight: 1,
        owner: Player.white,
      );

      final positions2 = PieceMovement.getLegalPositions(
        type: PieceType.bou,
        from: Position(4, 4),
        stackHeight: 2,
        owner: Player.white,
      );

      // スタック高さ2で2マス移動可能になる
      expect(positions2.length, greaterThan(positions1.length));
    });
  });

  group('盤面端での移動テスト', () {
    test('盤面端では有効な移動先のみ返される', () {
      // 左上角からの移動
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.sui,
        from: Position(8, 0),
        stackHeight: 1,
        owner: Player.white,
      );

      // 角では3マスのみ有効
      expect(positions.length, 3);
      for (final pos in positions) {
        expect(pos.isValid, true);
      }
    });

    test('無制限移動の駒も盤面外には出ない', () {
      final positions = PieceMovement.getLegalPositions(
        type: PieceType.tsutsu,
        from: Position(4, 0), // 左端
        stackHeight: 1,
        owner: Player.white,
      );

      // 右方向のみ8マス
      expect(positions.length, 8);
      for (final pos in positions) {
        expect(pos.isValid, true);
        expect(pos.col, greaterThan(0));
      }
    });
  });
}
