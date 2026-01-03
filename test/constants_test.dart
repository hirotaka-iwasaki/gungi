// 定数・enum定義の単体テスト
import 'package:flutter_test/flutter_test.dart';
import 'package:gungi/utils/constants.dart';

void main() {
  group('Player enumのテスト', () {
    test('Playerは2種類のみ', () {
      expect(Player.values.length, 2);
    });

    test('opponentで相手プレイヤーを取得できる', () {
      expect(Player.white.opponent, Player.black);
      expect(Player.black.opponent, Player.white);
    });

    test('opponentは対称的', () {
      expect(Player.white.opponent.opponent, Player.white);
      expect(Player.black.opponent.opponent, Player.black);
    });
  });

  group('PieceType enumのテスト', () {
    test('PieceTypeは14種類', () {
      expect(PieceType.values.length, 14);
    });

    test('各駒の漢字表記が正しい', () {
      expect(PieceType.sui.kanji, '帥');
      expect(PieceType.dai.kanji, '大');
      expect(PieceType.chu.kanji, '中');
      expect(PieceType.sho.kanji, '小');
      expect(PieceType.samurai.kanji, '侍');
      expect(PieceType.shinobi.kanji, '忍');
      expect(PieceType.hei.kanji, '兵');
      expect(PieceType.yari.kanji, '槍');
      expect(PieceType.uma.kanji, '馬');
      expect(PieceType.toride.kanji, '砦');
      expect(PieceType.yumi.kanji, '弓');
      expect(PieceType.hou.kanji, '砲');
      expect(PieceType.tsutsu.kanji, '筒');
      expect(PieceType.bou.kanji, '謀');
    });

    test('各駒の所持数が正しい', () {
      expect(PieceType.sui.count, 1);
      expect(PieceType.dai.count, 1);
      expect(PieceType.chu.count, 1);
      expect(PieceType.sho.count, 2);
      expect(PieceType.samurai.count, 2);
      expect(PieceType.shinobi.count, 2);
      expect(PieceType.hei.count, 4);
      expect(PieceType.yari.count, 3);
      expect(PieceType.uma.count, 2);
      expect(PieceType.toride.count, 2);
      expect(PieceType.yumi.count, 2);
      expect(PieceType.hou.count, 1);
      expect(PieceType.tsutsu.count, 1);
      expect(PieceType.bou.count, 1);
    });

    test('総駒数は25枚', () {
      int totalCount = 0;
      for (final type in PieceType.values) {
        totalCount += type.count;
      }
      expect(totalCount, 25);
    });

    test('特殊駒は4種類（弓・砲・筒・謀）', () {
      final specialPieces =
          PieceType.values.where((t) => t.isSpecial).toList();
      expect(specialPieces.length, 4);
      expect(PieceType.yumi.isSpecial, true);
      expect(PieceType.hou.isSpecial, true);
      expect(PieceType.tsutsu.isSpecial, true);
      expect(PieceType.bou.isSpecial, true);
    });

    test('非特殊駒は10種類', () {
      final normalPieces =
          PieceType.values.where((t) => !t.isSpecial).toList();
      expect(normalPieces.length, 10);
      expect(PieceType.sui.isSpecial, false);
      expect(PieceType.dai.isSpecial, false);
      expect(PieceType.hei.isSpecial, false);
    });

    test('特殊駒を除いた駒数は20枚', () {
      int normalCount = 0;
      for (final type in PieceType.values) {
        if (!type.isSpecial) {
          normalCount += type.count;
        }
      }
      expect(normalCount, 20);
    });
  });

  group('RuleLevel enumのテスト', () {
    test('RuleLevelは4種類', () {
      expect(RuleLevel.values.length, 4);
    });

    test('入門・初級・中級は最大スタック高さ2', () {
      expect(RuleLevel.beginner.maxHeight, 2);
      expect(RuleLevel.elementary.maxHeight, 2);
      expect(RuleLevel.intermediate.maxHeight, 2);
    });

    test('上級は最大スタック高さ3', () {
      expect(RuleLevel.advanced.maxHeight, 3);
    });

    test('上級のみ特殊駒を使用', () {
      expect(RuleLevel.beginner.useSpecialPieces, false);
      expect(RuleLevel.elementary.useSpecialPieces, false);
      expect(RuleLevel.intermediate.useSpecialPieces, false);
      expect(RuleLevel.advanced.useSpecialPieces, true);
    });

    test('中級・上級は自由配置', () {
      expect(RuleLevel.beginner.freeSetup, false);
      expect(RuleLevel.elementary.freeSetup, false);
      expect(RuleLevel.intermediate.freeSetup, true);
      expect(RuleLevel.advanced.freeSetup, true);
    });
  });

  group('定数のテスト', () {
    test('盤面サイズは9x9', () {
      expect(boardSize, 9);
    });

    test('最大スタック高さは3', () {
      expect(maxStackHeight, 3);
    });
  });
}
