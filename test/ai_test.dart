// AI関連の単体テスト
import 'package:flutter_test/flutter_test.dart';
import 'package:gungi/ai/ai_player.dart';
import 'package:gungi/ai/evaluation.dart' as gungi;
import 'package:gungi/ai/minimax_ai.dart';
import 'package:gungi/ai/random_ai.dart';
import 'package:gungi/models/board.dart';
import 'package:gungi/models/game_state.dart';
import 'package:gungi/models/move.dart';
import 'package:gungi/models/piece.dart';
import 'package:gungi/models/position.dart';
import 'package:gungi/utils/constants.dart';

void main() {
  group('RandomAiのテスト', () {
    test('難易度はeasy', () {
      final ai = RandomAi();
      expect(ai.difficulty, AiDifficulty.easy);
    });

    test('名前はランダムAI', () {
      final ai = RandomAi();
      expect(ai.name, 'ランダムAI');
    });

    test('合法手から1つを選択する', () async {
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

      final ai = RandomAi(seed: 42);
      final move = await ai.selectMove(state);

      expect(move, isNotNull);
      expect(move.player, Player.white);
    });

    test('合法手がない場合はエラー', () async {
      // 駒がない状態（合法手なし）
      final state = GameState(
        board: Board(),
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final ai = RandomAi();
      expect(() => ai.selectMove(state), throwsStateError);
    });

    test('帥を取れる手を優先する', () async {
      final board = Board();
      final whitePiece = Piece(type: PieceType.dai, owner: Player.white, id: 1);
      final blackSui = Piece(type: PieceType.sui, owner: Player.black, id: 2);
      final whiteSui = Piece(type: PieceType.sui, owner: Player.white, id: 3);
      final blackPiece = Piece(type: PieceType.hei, owner: Player.black, id: 4);

      board.placePiece(Position(4, 4), whitePiece);
      board.placePiece(Position(5, 4), blackSui);
      board.placePiece(Position(0, 0), whiteSui);
      board.placePiece(Position(4, 3), blackPiece);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final ai = RandomAi(seed: 42);
      final move = await ai.selectMove(state);

      // 帥を取る手を選択
      expect(move.type, MoveType.capture);
      expect(move.to, Position(5, 4));
    });

    test('シードを設定すると再現性がある', () async {
      final board = Board();
      board.placePiece(Position(0, 0), Piece(type: PieceType.hei, owner: Player.white, id: 1));
      board.placePiece(Position(0, 4), Piece(type: PieceType.hei, owner: Player.white, id: 2));
      board.placePiece(Position(0, 8), Piece(type: PieceType.hei, owner: Player.white, id: 3));

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final ai1 = RandomAi(seed: 12345);
      final ai2 = RandomAi(seed: 12345);

      final move1 = await ai1.selectMove(state);
      final move2 = await ai2.selectMove(state);

      // 同じシードなら同じ手を選択
      expect(move1.piece.id, move2.piece.id);
      expect(move1.to, move2.to);
    });
  });

  group('MinimaxAiのテスト', () {
    test('depth<=2はmedium難易度', () {
      final ai = MinimaxAi(aiPlayer: Player.white, depth: 2);
      expect(ai.difficulty, AiDifficulty.medium);
    });

    test('depth>2はhard難易度', () {
      final ai = MinimaxAi(aiPlayer: Player.white, depth: 3);
      expect(ai.difficulty, AiDifficulty.hard);
    });

    test('depth<=2は中級AI', () {
      final ai = MinimaxAi(aiPlayer: Player.white, depth: 2);
      expect(ai.name, '中級AI');
    });

    test('depth>2は上級AI', () {
      final ai = MinimaxAi(aiPlayer: Player.white, depth: 3);
      expect(ai.name, '上級AI');
    });

    test('合法手から1つを選択する', () async {
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

      final ai = MinimaxAi(aiPlayer: Player.white, depth: 1, seed: 42);
      final move = await ai.selectMove(state);

      expect(move, isNotNull);
      expect(move.player, Player.white);
    });

    test('帥を取れる手を即座に選択する', () async {
      final board = Board();
      final whitePiece = Piece(type: PieceType.dai, owner: Player.white, id: 1);
      final blackSui = Piece(type: PieceType.sui, owner: Player.black, id: 2);
      final whiteSui = Piece(type: PieceType.sui, owner: Player.white, id: 3);

      board.placePiece(Position(4, 4), whitePiece);
      board.placePiece(Position(5, 4), blackSui);
      board.placePiece(Position(0, 0), whiteSui);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final ai = MinimaxAi(aiPlayer: Player.white, depth: 2);
      final move = await ai.selectMove(state);

      // 帥を取る手を選択
      expect(move.type, MoveType.capture);
      expect(move.to, Position(5, 4));
    });

    test('合法手がない場合はエラー', () async {
      final state = GameState(
        board: Board(),
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final ai = MinimaxAi(aiPlayer: Player.white, depth: 2);
      expect(() => ai.selectMove(state), throwsStateError);
    });
  });

  group('Evaluationのテスト', () {
    group('pieceValuesテスト', () {
      test('帥の価値が最も高い', () {
        expect(gungi.Evaluation.pieceValues[PieceType.sui], 10000);
      });

      test('大・中・馬は高価値', () {
        expect(gungi.Evaluation.pieceValues[PieceType.dai], 900);
        expect(gungi.Evaluation.pieceValues[PieceType.chu], 700);
        expect(gungi.Evaluation.pieceValues[PieceType.uma], 650);
      });

      test('兵は最低価値', () {
        expect(gungi.Evaluation.pieceValues[PieceType.hei], 100);
      });

      test('謀は高価値（寝返り能力）', () {
        expect(gungi.Evaluation.pieceValues[PieceType.bou], 800);
      });
    });

    group('evaluateテスト', () {
      test('終局で勝者は高スコア', () {
        final state = GameState(
          phase: GamePhase.finished,
          winner: Player.white,
          ruleLevel: RuleLevel.elementary,
        );

        final score = gungi.Evaluation.evaluate(state, Player.white);
        expect(score, 100000);
      });

      test('終局で敗者は低スコア', () {
        final state = GameState(
          phase: GamePhase.finished,
          winner: Player.black,
          ruleLevel: RuleLevel.elementary,
        );

        final score = gungi.Evaluation.evaluate(state, Player.white);
        expect(score, -100000);
      });

      test('駒が多いほど高スコア', () {
        final board1 = Board();
        board1.placePiece(Position(0, 4), Piece(type: PieceType.sui, owner: Player.white, id: 1));

        final board2 = Board();
        board2.placePiece(Position(0, 4), Piece(type: PieceType.sui, owner: Player.white, id: 1));
        board2.placePiece(Position(1, 4), Piece(type: PieceType.dai, owner: Player.white, id: 2));

        final state1 = GameState(
          board: board1,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final state2 = GameState(
          board: board2,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final score1 = gungi.Evaluation.evaluate(state1, Player.white);
        final score2 = gungi.Evaluation.evaluate(state2, Player.white);

        expect(score2, greaterThan(score1));
      });

      test('帥がないと帥ありより低評価', () {
        // 帥がある状態
        final boardWithSui = Board();
        boardWithSui.placePiece(Position(0, 4), Piece(type: PieceType.sui, owner: Player.white, id: 1));
        boardWithSui.placePiece(Position(8, 4), Piece(type: PieceType.sui, owner: Player.black, id: 2));

        final stateWithSui = GameState(
          board: boardWithSui,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        // 帥がない状態（大のみ）
        final boardNoSui = Board();
        boardNoSui.placePiece(Position(0, 4), Piece(type: PieceType.dai, owner: Player.white, id: 3));
        boardNoSui.placePiece(Position(8, 4), Piece(type: PieceType.sui, owner: Player.black, id: 4));

        final stateNoSui = GameState(
          board: boardNoSui,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final scoreWithSui = gungi.Evaluation.evaluate(stateWithSui, Player.white);
        final scoreNoSui = gungi.Evaluation.evaluate(stateNoSui, Player.white);

        // 帥がある方が高評価
        expect(scoreWithSui, greaterThan(scoreNoSui));
      });

      test('中央の駒は高評価', () {
        final boardCenter = Board();
        boardCenter.placePiece(Position(4, 4), Piece(type: PieceType.hei, owner: Player.white, id: 1));
        boardCenter.placePiece(Position(0, 0), Piece(type: PieceType.sui, owner: Player.white, id: 2));

        final boardEdge = Board();
        boardEdge.placePiece(Position(0, 0), Piece(type: PieceType.hei, owner: Player.white, id: 1));
        boardEdge.placePiece(Position(0, 1), Piece(type: PieceType.sui, owner: Player.white, id: 2));

        final stateCenter = GameState(
          board: boardCenter,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final stateEdge = GameState(
          board: boardEdge,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final scoreCenter = gungi.Evaluation.evaluate(stateCenter, Player.white);
        final scoreEdge = gungi.Evaluation.evaluate(stateEdge, Player.white);

        // 中央にある方が高評価
        expect(scoreCenter, greaterThan(scoreEdge));
      });

      test('スタック高さはボーナスになる', () {
        final board1 = Board();
        board1.placePiece(Position(4, 4), Piece(type: PieceType.hei, owner: Player.white, id: 1));
        board1.placePiece(Position(0, 0), Piece(type: PieceType.sui, owner: Player.white, id: 2));

        final board2 = Board();
        board2.placePiece(Position(4, 4), Piece(type: PieceType.hei, owner: Player.white, id: 1));
        board2.placePiece(Position(4, 4), Piece(type: PieceType.hei, owner: Player.white, id: 3)); // 2段スタック
        board2.placePiece(Position(0, 0), Piece(type: PieceType.sui, owner: Player.white, id: 2));

        final state1 = GameState(
          board: board1,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final state2 = GameState(
          board: board2,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final score1 = gungi.Evaluation.evaluate(state1, Player.white);
        final score2 = gungi.Evaluation.evaluate(state2, Player.white);

        // スタックが高い方が高評価
        expect(score2, greaterThan(score1));
      });

      test('帥が後方にいると安全性が高い', () {
        final boardBack = Board();
        boardBack.placePiece(Position(0, 4), Piece(type: PieceType.sui, owner: Player.white, id: 1));

        final boardFront = Board();
        boardFront.placePiece(Position(5, 4), Piece(type: PieceType.sui, owner: Player.white, id: 1));

        final stateBack = GameState(
          board: boardBack,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final stateFront = GameState(
          board: boardFront,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final scoreBack = gungi.Evaluation.evaluate(stateBack, Player.white);
        final scoreFront = gungi.Evaluation.evaluate(stateFront, Player.white);

        // 後方にいる方が高評価
        expect(scoreBack, greaterThan(scoreFront));
      });

      test('帥の周囲に護衛がいると安全性が高い', () {
        final boardAlone = Board();
        boardAlone.placePiece(Position(0, 4), Piece(type: PieceType.sui, owner: Player.white, id: 1));

        final boardGuarded = Board();
        boardGuarded.placePiece(Position(0, 4), Piece(type: PieceType.sui, owner: Player.white, id: 1));
        boardGuarded.placePiece(Position(0, 3), Piece(type: PieceType.hei, owner: Player.white, id: 2));
        boardGuarded.placePiece(Position(0, 5), Piece(type: PieceType.hei, owner: Player.white, id: 3));

        final stateAlone = GameState(
          board: boardAlone,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final stateGuarded = GameState(
          board: boardGuarded,
          currentPlayer: Player.white,
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final scoreAlone = gungi.Evaluation.evaluate(stateAlone, Player.white);
        final scoreGuarded = gungi.Evaluation.evaluate(stateGuarded, Player.white);

        // 護衛がいる方が高評価
        expect(scoreGuarded, greaterThan(scoreAlone));
      });

      test('手駒も評価に含まれる', () {
        final board = Board();
        board.placePiece(Position(0, 4), Piece(type: PieceType.sui, owner: Player.white, id: 1));

        final stateNoHand = GameState(
          board: board,
          currentPlayer: Player.white,
          handPieces: {Player.white: [], Player.black: []},
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final stateWithHand = GameState(
          board: board,
          currentPlayer: Player.white,
          handPieces: {
            Player.white: [Piece(type: PieceType.dai, owner: Player.white, id: 2)],
            Player.black: [],
          },
          phase: GamePhase.playing,
          ruleLevel: RuleLevel.elementary,
        );

        final scoreNoHand = gungi.Evaluation.evaluate(stateNoHand, Player.white);
        final scoreWithHand = gungi.Evaluation.evaluate(stateWithHand, Player.white);

        // 手駒がある方が高評価
        expect(scoreWithHand, greaterThan(scoreNoHand));
      });
    });
  });

  group('AiDifficultyのテスト', () {
    test('3つの難易度がある', () {
      expect(AiDifficulty.values.length, 3);
    });

    test('難易度の名前が正しい', () {
      expect(AiDifficulty.easy.name, 'easy');
      expect(AiDifficulty.medium.name, 'medium');
      expect(AiDifficulty.hard.name, 'hard');
    });
  });
}
