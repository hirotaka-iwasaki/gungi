// ゲーム状態ロジックの単体テスト
import 'package:flutter_test/flutter_test.dart';
import 'package:gungi/models/board.dart';
import 'package:gungi/models/game_state.dart';
import 'package:gungi/models/move.dart';
import 'package:gungi/models/piece.dart';
import 'package:gungi/models/position.dart';
import 'package:gungi/utils/constants.dart';

void main() {
  group('GameState初期化テスト', () {
    test('デフォルトで先手が手番', () {
      final state = GameState(
        ruleLevel: RuleLevel.elementary,
        phase: GamePhase.playing,
      );
      expect(state.currentPlayer, Player.white);
    });

    test('デフォルトで配置フェーズ', () {
      final state = GameState(
        ruleLevel: RuleLevel.elementary,
      );
      expect(state.phase, GamePhase.setup);
    });

    test('手駒は空で初期化される', () {
      final state = GameState(
        ruleLevel: RuleLevel.elementary,
      );
      expect(state.handPieces[Player.white]?.isEmpty, true);
      expect(state.handPieces[Player.black]?.isEmpty, true);
    });

    test('勝者は最初はnull', () {
      final state = GameState(
        ruleLevel: RuleLevel.elementary,
      );
      expect(state.winner, null);
    });

    test('setupFinishedは両者false', () {
      final state = GameState(
        ruleLevel: RuleLevel.elementary,
      );
      expect(state.isSetupFinished(Player.white), false);
      expect(state.isSetupFinished(Player.black), false);
      expect(state.bothSetupFinished, false);
    });
  });

  group('createPieceテスト', () {
    test('新しい駒を生成できる', () {
      final state = GameState(ruleLevel: RuleLevel.elementary);

      final piece1 = state.createPiece(PieceType.hei, Player.white);
      final piece2 = state.createPiece(PieceType.hei, Player.white);

      expect(piece1.type, PieceType.hei);
      expect(piece1.owner, Player.white);
      expect(piece1.id, 0);
      expect(piece2.id, 1); // IDは自動インクリメント
    });
  });

  group('initializePiecesテスト', () {
    test('上級ルールで全25枚が生成される', () {
      final state = GameState(ruleLevel: RuleLevel.advanced);
      state.initializePieces();

      expect(state.handPieces[Player.white]!.length, 25);
      expect(state.handPieces[Player.black]!.length, 25);
    });

    test('初級ルールで特殊駒が除外される', () {
      final state = GameState(ruleLevel: RuleLevel.elementary);
      state.initializePieces();

      // 特殊駒（弓2、砲1、筒1、謀1）= 5枚が除外
      expect(state.handPieces[Player.white]!.length, 20);
      expect(state.handPieces[Player.black]!.length, 20);

      // 特殊駒がないことを確認
      for (final piece in state.handPieces[Player.white]!) {
        expect(piece.type.isSpecial, false);
      }
    });

    test('駒の種類と枚数が正しい', () {
      final state = GameState(ruleLevel: RuleLevel.advanced);
      state.initializePieces();

      final whitePieces = state.handPieces[Player.white]!;

      // 各駒タイプの数をカウント
      final counts = <PieceType, int>{};
      for (final piece in whitePieces) {
        counts[piece.type] = (counts[piece.type] ?? 0) + 1;
      }

      expect(counts[PieceType.sui], 1);
      expect(counts[PieceType.dai], 1);
      expect(counts[PieceType.chu], 1);
      expect(counts[PieceType.sho], 2);
      expect(counts[PieceType.hei], 4);
      expect(counts[PieceType.yari], 3);
    });
  });

  group('applyMove - 移動テスト', () {
    test('通常移動が正しく適用される', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      board.placePiece(Position(0, 4), piece);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final move = Move.move(
        piece: piece,
        from: Position(0, 4),
        to: Position(1, 4),
        player: Player.white,
      );

      final newState = state.applyMove(move);

      expect(newState.board.isEmpty(Position(0, 4)), true);
      expect(newState.board.getPiece(Position(1, 4)), piece);
      expect(newState.currentPlayer, Player.black); // 手番交代
    });
  });

  group('applyMove - 捕獲テスト', () {
    test('捕獲が正しく適用される', () {
      final board = Board();
      final whitePiece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final blackPiece = Piece(type: PieceType.hei, owner: Player.black, id: 2);
      board.placePiece(Position(0, 4), whitePiece);
      board.placePiece(Position(1, 4), blackPiece);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final move = Move.capture(
        piece: whitePiece,
        from: Position(0, 4),
        to: Position(1, 4),
        player: Player.white,
      );

      final newState = state.applyMove(move);

      expect(newState.board.getPiece(Position(1, 4)), whitePiece);
      expect(newState.board.isEmpty(Position(0, 4)), true);
    });

    test('帥を捕獲すると勝利', () {
      final board = Board();
      final whitePiece = Piece(type: PieceType.dai, owner: Player.white, id: 1);
      final blackSui = Piece(type: PieceType.sui, owner: Player.black, id: 2);
      final whiteSui = Piece(type: PieceType.sui, owner: Player.white, id: 3);
      board.placePiece(Position(0, 4), whitePiece);
      board.placePiece(Position(1, 4), blackSui);
      board.placePiece(Position(0, 0), whiteSui);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final move = Move.capture(
        piece: whitePiece,
        from: Position(0, 4),
        to: Position(1, 4),
        player: Player.white,
      );

      final newState = state.applyMove(move);

      expect(newState.phase, GamePhase.finished);
      expect(newState.winner, Player.white);
    });
  });

  group('applyMove - ツケテスト', () {
    test('自駒へのツケが正しく適用される', () {
      final board = Board();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);
      board.placePiece(Position(0, 4), piece1);
      board.placePiece(Position(1, 4), piece2);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final move = Move.stack(
        piece: piece2,
        from: Position(1, 4),
        to: Position(0, 4),
        player: Player.white,
        isAttack: false,
      );

      final newState = state.applyMove(move);

      expect(newState.board.getHeight(Position(0, 4)), 2);
      expect(newState.board.getPiece(Position(0, 4)), piece2);
      expect(newState.board.isEmpty(Position(1, 4)), true);
    });
  });

  group('applyMove - 新（drop）テスト', () {
    test('手駒からの配置が正しく適用される', () {
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);

      final state = GameState(
        board: Board(),
        currentPlayer: Player.white,
        handPieces: {
          Player.white: [piece],
          Player.black: [],
        },
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final move = Move.drop(
        piece: piece,
        to: Position(1, 4),
        player: Player.white,
      );

      final newState = state.applyMove(move);

      expect(newState.board.getPiece(Position(1, 4)), piece);
      expect(newState.handPieces[Player.white]!.isEmpty, true);
    });
  });

  group('指し手履歴テスト', () {
    test('指し手が履歴に追加される', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      board.placePiece(Position(0, 4), piece);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final move = Move.move(
        piece: piece,
        from: Position(0, 4),
        to: Position(1, 4),
        player: Player.white,
      );

      final newState = state.applyMove(move);

      expect(newState.moveHistory.length, 1);
      expect(newState.moveHistory.first, move);
    });
  });

  group('finishPlayerSetupテスト', () {
    test('片方のプレイヤーが配置完了すると手番交代', () {
      final state = GameState(
        currentPlayer: Player.white,
        phase: GamePhase.setup,
        ruleLevel: RuleLevel.intermediate,
      );

      final newState = state.finishPlayerSetup(Player.white);

      expect(newState.isSetupFinished(Player.white), true);
      expect(newState.isSetupFinished(Player.black), false);
      expect(newState.currentPlayer, Player.black);
      expect(newState.phase, GamePhase.setup); // まだsetup
    });

    test('両方が配置完了すると対局開始', () {
      final state = GameState(
        currentPlayer: Player.black,
        phase: GamePhase.setup,
        ruleLevel: RuleLevel.intermediate,
        setupFinished: {
          Player.white: true,
          Player.black: false,
        },
      );

      final newState = state.finishPlayerSetup(Player.black);

      expect(newState.isSetupFinished(Player.white), true);
      expect(newState.isSetupFinished(Player.black), true);
      expect(newState.bothSetupFinished, true);
      expect(newState.currentPlayer, Player.white); // 先手から開始
      expect(newState.phase, GamePhase.playing);
    });
  });

  group('startGameテスト', () {
    test('対局フェーズに移行する', () {
      final state = GameState(
        phase: GamePhase.setup,
        ruleLevel: RuleLevel.elementary,
      );

      final newState = state.startGame();

      expect(newState.phase, GamePhase.playing);
      expect(newState.currentPlayer, Player.white);
    });
  });

  group('copyWithテスト', () {
    test('指定したフィールドのみ変更される', () {
      final state = GameState(
        currentPlayer: Player.white,
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final newState = state.copyWith(currentPlayer: Player.black);

      expect(newState.currentPlayer, Player.black);
      expect(newState.phase, GamePhase.playing);
      expect(newState.ruleLevel, RuleLevel.elementary);
    });

    test('盤面がコピーされる', () {
      final board = Board();
      board.placePiece(Position(0, 0), Piece(type: PieceType.hei, owner: Player.white, id: 1));

      final state = GameState(
        board: board,
        ruleLevel: RuleLevel.elementary,
      );

      final newState = state.copyWith();

      // コピー先の盤面を変更しても元は変わらない
      newState.board.placePiece(Position(1, 1), Piece(type: PieceType.chu, owner: Player.white, id: 2));

      expect(state.board.isEmpty(Position(1, 1)), true);
      expect(newState.board.isEmpty(Position(1, 1)), false);
    });
  });

  group('setupFixedPositionテスト', () {
    test('固定配置で帥が中央に配置される', () {
      final state = GameState(ruleLevel: RuleLevel.elementary);
      state.initializePieces();
      state.setupFixedPosition();

      // 白の帥はrow=0, col=4に配置される
      expect(state.board.getPiece(Position(0, 4))?.type, PieceType.sui);
      expect(state.board.getPiece(Position(0, 4))?.owner, Player.white);

      // 黒の帥はrow=8, col=4に配置される
      expect(state.board.getPiece(Position(8, 4))?.type, PieceType.sui);
      expect(state.board.getPiece(Position(8, 4))?.owner, Player.black);
    });

    test('固定配置で大・中も配置される', () {
      final state = GameState(ruleLevel: RuleLevel.elementary);
      state.initializePieces();
      state.setupFixedPosition();

      // 白の大はrow=0, col=3
      expect(state.board.getPiece(Position(0, 3))?.type, PieceType.dai);
      // 白の中はrow=0, col=5
      expect(state.board.getPiece(Position(0, 5))?.type, PieceType.chu);
    });
  });

  group('isAiThinkingテスト', () {
    test('デフォルトはfalse', () {
      final state = GameState(ruleLevel: RuleLevel.elementary);
      expect(state.isAiThinking, false);
    });

    test('copyWithで変更できる', () {
      final state = GameState(ruleLevel: RuleLevel.elementary);
      final newState = state.copyWith(isAiThinking: true);
      expect(newState.isAiThinking, true);
    });
  });
}
