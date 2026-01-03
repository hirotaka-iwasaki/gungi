// 合法手判定の単体テスト
import 'package:flutter_test/flutter_test.dart';
import 'package:gungi/logic/move_validator.dart';
import 'package:gungi/models/board.dart';
import 'package:gungi/models/game_state.dart';
import 'package:gungi/models/move.dart';
import 'package:gungi/models/piece.dart';
import 'package:gungi/models/position.dart';
import 'package:gungi/utils/constants.dart';

void main() {
  group('経路ブロックのテスト', () {
    test('弓は経路上の高い駒に遮られる', () {
      final board = Board();
      final yumi = Piece(type: PieceType.yumi, owner: Player.white, id: 1);
      // 2段スタックの障害物
      final blocker1 = Piece(type: PieceType.hei, owner: Player.black, id: 2);
      final blocker2 = Piece(type: PieceType.hei, owner: Player.black, id: 3);

      board.placePiece(Position(0, 0), yumi);
      board.placePiece(Position(1, 1), blocker1);
      board.placePiece(Position(1, 1), blocker2); // 2段の障害物

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.advanced,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 1段の弓は2段の障害物を超えられない
      final yumiMoves = moves.where((m) => m.piece.id == 1).toList();
      expect(yumiMoves.any((m) => m.to == Position(2, 2)), false);
    });

    test('同じ高さ以下の駒は経路をブロックしない', () {
      final board = Board();
      final yumi = Piece(type: PieceType.yumi, owner: Player.white, id: 1);
      final blocker = Piece(type: PieceType.hei, owner: Player.black, id: 2);

      board.placePiece(Position(0, 0), yumi);
      board.placePiece(Position(1, 1), blocker); // 1段の障害物

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.advanced,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 同じ高さの障害物は通過可能（弓は(2,2)以降に移動可能）
      final yumiMoves = moves.where((m) => m.piece.id == 1).toList();
      expect(yumiMoves.any((m) => m.to == Position(2, 2)), true);
    });

    test('高いスタックは低い障害物を通過できる', () {
      final board = Board();
      final hei = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final yumi = Piece(type: PieceType.yumi, owner: Player.white, id: 2);
      final blocker = Piece(type: PieceType.hei, owner: Player.black, id: 3);

      // 2段スタック（弓が上）
      board.placePiece(Position(0, 0), hei);
      board.placePiece(Position(0, 0), yumi); // 弓が上
      // 1段の障害物
      board.placePiece(Position(1, 1), blocker);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.advanced,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 2段スタックは1段の障害物を超えて移動可能
      final stackMoves = moves.where((m) => m.from == Position(0, 0)).toList();
      expect(stackMoves.any((m) => m.to == Position(2, 2)), true);
    });
  });

  group('忍の桂馬動きテスト', () {
    test('忍の桂馬動きは障害物を飛び越える', () {
      final board = Board();
      final shinobi = Piece(type: PieceType.shinobi, owner: Player.white, id: 1);
      final blocker = Piece(type: PieceType.hei, owner: Player.black, id: 2);

      board.placePiece(Position(0, 4), shinobi);
      board.placePiece(Position(1, 4), blocker); // 前方に障害物

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.advanced,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 桂馬動きで(2,3)と(2,5)に移動可能
      final shinobiMoves = moves.where((m) => m.piece.id == 1).toList();
      expect(shinobiMoves.any((m) => m.to == Position(2, 3)), true);
      expect(shinobiMoves.any((m) => m.to == Position(2, 5)), true);
    });
  });

  group('新（drop）のテスト', () {
    test('最前線より前には配置できない', () {
      final board = Board();
      // 白の最前線は row=2
      board.placePiece(Position(2, 4), Piece(type: PieceType.hei, owner: Player.white, id: 1));

      final dropPiece = Piece(type: PieceType.hei, owner: Player.white, id: 2);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {
          Player.white: [dropPiece],
          Player.black: [],
        },
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      final dropMoves = moves.where((m) => m.type == MoveType.drop).toList();

      // row > 2 には配置できない
      for (final move in dropMoves) {
        expect(move.to.row, lessThanOrEqualTo(2));
      }
    });

    test('敵駒の上には新できない', () {
      final board = Board();
      board.placePiece(Position(0, 4), Piece(type: PieceType.hei, owner: Player.white, id: 1));
      board.placePiece(Position(1, 4), Piece(type: PieceType.hei, owner: Player.black, id: 2));

      final dropPiece = Piece(type: PieceType.hei, owner: Player.white, id: 3);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {
          Player.white: [dropPiece],
          Player.black: [],
        },
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      final dropMoves = moves.where((m) => m.type == MoveType.drop).toList();

      // (1,4)への新がないことを確認
      expect(dropMoves.any((m) => m.to == Position(1, 4)), false);
    });

    test('自駒の上に新できる（スタック制限内）', () {
      final board = Board();
      board.placePiece(Position(0, 4), Piece(type: PieceType.hei, owner: Player.white, id: 1));

      final dropPiece = Piece(type: PieceType.hei, owner: Player.white, id: 2);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {
          Player.white: [dropPiece],
          Player.black: [],
        },
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary, // maxHeight = 2
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      final dropMoves = moves.where((m) => m.type == MoveType.drop).toList();

      // (0,4)への新が可能
      expect(dropMoves.any((m) => m.to == Position(0, 4)), true);
    });

    test('スタック高さ制限を超えて新できない', () {
      final board = Board();
      board.placePiece(Position(0, 4), Piece(type: PieceType.hei, owner: Player.white, id: 1));
      board.placePiece(Position(0, 4), Piece(type: PieceType.hei, owner: Player.white, id: 2));

      final dropPiece = Piece(type: PieceType.hei, owner: Player.white, id: 3);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {
          Player.white: [dropPiece],
          Player.black: [],
        },
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary, // maxHeight = 2
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      final dropMoves = moves.where((m) => m.type == MoveType.drop).toList();

      // (0,4)への新は不可（既に2段）
      expect(dropMoves.any((m) => m.to == Position(0, 4)), false);
    });
  });

  group('捕獲とツケの選択テスト', () {
    test('敵駒に対して捕獲と攻撃ツケ両方が選択肢にある', () {
      final board = Board();
      final whitePiece = Piece(type: PieceType.dai, owner: Player.white, id: 1);
      final blackPiece = Piece(type: PieceType.hei, owner: Player.black, id: 2);

      board.placePiece(Position(4, 4), whitePiece);
      board.placePiece(Position(5, 4), blackPiece);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      final toBlack = moves.where((m) => m.to == Position(5, 4)).toList();

      // 捕獲と攻撃ツケの両方がある
      expect(toBlack.any((m) => m.type == MoveType.capture), true);
      expect(toBlack.any((m) => m.type == MoveType.attackStack), true);
    });
  });

  group('高さ優位のテスト', () {
    test('低い駒は高い敵駒を捕獲できない', () {
      final board = Board();
      final whitePiece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final blackPiece1 = Piece(type: PieceType.hei, owner: Player.black, id: 2);
      final blackPiece2 = Piece(type: PieceType.hei, owner: Player.black, id: 3);

      // 白兵（1段）
      board.placePiece(Position(4, 4), whitePiece);
      // 黒兵（2段スタック）
      board.placePiece(Position(5, 4), blackPiece1);
      board.placePiece(Position(5, 4), blackPiece2);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // (5,4)への移動がない（高さ優位で攻撃不可）
      final toBlack = moves.where((m) => m.to == Position(5, 4)).toList();
      expect(toBlack.isEmpty, true);
    });

    test('同じ高さなら捕獲可能', () {
      final board = Board();
      final whitePiece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final blackPiece = Piece(type: PieceType.hei, owner: Player.black, id: 2);

      board.placePiece(Position(4, 4), whitePiece);
      board.placePiece(Position(5, 4), blackPiece);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // (5,4)への捕獲が可能
      final toBlack = moves.where((m) => m.to == Position(5, 4)).toList();
      expect(toBlack.any((m) => m.type == MoveType.capture), true);
    });

    test('高い駒は低い敵駒を捕獲できる', () {
      final board = Board();
      final whitePiece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final whitePiece2 = Piece(type: PieceType.hei, owner: Player.white, id: 2);
      final blackPiece = Piece(type: PieceType.hei, owner: Player.black, id: 3);

      // 白兵（2段スタック）
      board.placePiece(Position(4, 4), whitePiece1);
      board.placePiece(Position(4, 4), whitePiece2);
      // 黒兵（1段）
      board.placePiece(Position(5, 4), blackPiece);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // (5,4)への捕獲が可能
      final toBlack = moves.where((m) => m.to == Position(5, 4)).toList();
      expect(toBlack.any((m) => m.type == MoveType.capture), true);
    });
  });

  group('isLegalMoveテスト', () {
    test('合法手はtrueを返す', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      board.placePiece(Position(0, 4), piece);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final move = Move.move(
        piece: piece,
        from: Position(0, 4),
        to: Position(1, 4),
        player: Player.white,
      );

      expect(validator.isLegalMove(move), true);
    });

    test('非合法手はfalseを返す', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      board.placePiece(Position(0, 4), piece);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      // 兵は後ろに動けない
      final move = Move.move(
        piece: piece,
        from: Position(0, 4),
        to: Position(0, 3),
        player: Player.white,
      );

      expect(validator.isLegalMove(move), false);
    });
  });

  group('砦のテスト', () {
    test('砦は移動できない', () {
      final board = Board();
      final toride = Piece(type: PieceType.toride, owner: Player.white, id: 1);
      board.placePiece(Position(0, 4), toride);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.advanced,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 砦の移動がない
      final torideMoves = moves.where((m) => m.piece.id == 1 && m.type == MoveType.move).toList();
      expect(torideMoves.isEmpty, true);
    });
  });

  group('複数駒の合法手生成テスト', () {
    test('複数の駒から合法手が生成される', () {
      final board = Board();
      board.placePiece(Position(0, 0), Piece(type: PieceType.hei, owner: Player.white, id: 1));
      board.placePiece(Position(0, 8), Piece(type: PieceType.hei, owner: Player.white, id: 2));
      board.placePiece(Position(4, 4), Piece(type: PieceType.dai, owner: Player.white, id: 3));

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 3つの駒からの移動がある
      expect(moves.where((m) => m.piece.id == 1).isNotEmpty, true);
      expect(moves.where((m) => m.piece.id == 2).isNotEmpty, true);
      expect(moves.where((m) => m.piece.id == 3).isNotEmpty, true);
    });
  });

  group('スタック高さと移動距離のテスト', () {
    test('2段スタックで移動距離が+1される', () {
      final board = Board();
      final hei1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final hei2 = Piece(type: PieceType.hei, owner: Player.white, id: 2);

      board.placePiece(Position(0, 4), hei1);
      board.placePiece(Position(0, 4), hei2);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 2段の兵は2マス移動可能
      final heiMoves = moves.where((m) => m.type == MoveType.move).toList();
      expect(heiMoves.any((m) => m.to == Position(1, 4)), true);
      expect(heiMoves.any((m) => m.to == Position(2, 4)), true);
    });
  });
}
