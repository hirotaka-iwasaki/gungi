// 軍儀ゲームロジックの単体テスト
import 'package:flutter_test/flutter_test.dart';
import 'package:gungi/models/board.dart';
import 'package:gungi/models/game_state.dart';
import 'package:gungi/models/move.dart';
import 'package:gungi/models/piece.dart';
import 'package:gungi/models/position.dart';
import 'package:gungi/logic/move_validator.dart';
import 'package:gungi/utils/constants.dart';

void main() {
  group('Position（座標）のテスト', () {
    test('有効な座標かどうかを判定できる', () {
      expect(Position(0, 0).isValid, true);
      expect(Position(8, 8).isValid, true);
      expect(Position(4, 4).isValid, true);
      expect(Position(-1, 0).isValid, false);
      expect(Position(0, -1).isValid, false);
      expect(Position(9, 0).isValid, false);
      expect(Position(0, 9).isValid, false);
    });

    test('座標のオフセット計算ができる', () {
      final pos = Position(4, 4);
      expect(pos.offset(1, 0), Position(5, 4));
      expect(pos.offset(0, 1), Position(4, 5));
      expect(pos.offset(-1, -1), Position(3, 3));
    });

    test('座標の棋譜表記が正しい', () {
      // 実装では数字形式: '${col+1}${row+1}'
      expect(Position(0, 0).toNotation(), '11');
      expect(Position(8, 8).toNotation(), '99');
      expect(Position(4, 4).toNotation(), '55');
    });
  });

  group('Piece（駒）のテスト', () {
    test('駒の漢字表記が正しい', () {
      final sui = Piece(type: PieceType.sui, owner: Player.white, id: 1);
      final dai = Piece(type: PieceType.dai, owner: Player.black, id: 2);
      expect(sui.kanji, '帥');
      expect(dai.kanji, '大');
    });

    test('駒のコピーが正しく動作する', () {
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final copied = piece.copyWith(owner: Player.black);
      expect(copied.owner, Player.black);
      expect(copied.type, PieceType.hei);
      expect(copied.id, 1); // IDは変わらない
    });

    test('駒の等価性はIDで判定される', () {
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece3 = Piece(type: PieceType.hei, owner: Player.white, id: 2);
      expect(piece1 == piece2, true);
      expect(piece1 == piece3, false);
    });
  });

  group('PieceStack（駒スタック）のテスト', () {
    test('空のスタックは正しく初期化される', () {
      final stack = PieceStack();
      expect(stack.isEmpty, true);
      expect(stack.height, 0);
      expect(stack.top, null);
    });

    test('駒をプッシュできる', () {
      final stack = PieceStack();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      stack.push(piece);
      expect(stack.height, 1);
      expect(stack.top, piece);
      expect(stack.controller, Player.white);
    });

    test('駒をポップできる', () {
      final stack = PieceStack();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);
      stack.push(piece1);
      stack.push(piece2);

      final popped = stack.pop();
      expect(popped, piece2);
      expect(stack.height, 1);
      expect(stack.top, piece1);
    });

    test('スタックをクリアできる', () {
      final stack = PieceStack();
      stack.push(Piece(type: PieceType.hei, owner: Player.white, id: 1));
      stack.push(Piece(type: PieceType.chu, owner: Player.white, id: 2));

      final removed = stack.clear();
      expect(removed.length, 2);
      expect(stack.isEmpty, true);
    });

    test('スタックのコピーが独立している', () {
      final stack = PieceStack();
      stack.push(Piece(type: PieceType.hei, owner: Player.white, id: 1));

      final copy = stack.copy();
      copy.push(Piece(type: PieceType.chu, owner: Player.white, id: 2));

      expect(stack.height, 1);
      expect(copy.height, 2);
    });
  });

  group('Board（盤面）のテスト', () {
    test('盤面は9x9で初期化される', () {
      final board = Board();
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          expect(board.getStack(Position(r, c)).isEmpty, true);
        }
      }
    });

    test('駒を配置できる', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final pos = Position(0, 0);

      board.placePiece(pos, piece);
      expect(board.getStack(pos).top, piece);
    });

    test('帥の位置を取得できる', () {
      final board = Board();
      final whiteSui = Piece(type: PieceType.sui, owner: Player.white, id: 1);
      final blackSui = Piece(type: PieceType.sui, owner: Player.black, id: 2);

      board.placePiece(Position(0, 4), whiteSui);
      board.placePiece(Position(8, 4), blackSui);

      expect(board.findSui(Player.white), Position(0, 4));
      expect(board.findSui(Player.black), Position(8, 4));
    });

    test('最前線を正しく計算できる', () {
      final board = Board();

      // 白駒を配置
      board.placePiece(Position(0, 0), Piece(type: PieceType.hei, owner: Player.white, id: 1));
      board.placePiece(Position(2, 0), Piece(type: PieceType.hei, owner: Player.white, id: 2));

      // 黒駒を配置
      board.placePiece(Position(8, 0), Piece(type: PieceType.hei, owner: Player.black, id: 3));
      board.placePiece(Position(6, 0), Piece(type: PieceType.hei, owner: Player.black, id: 4));

      expect(board.getFrontLine(Player.white), 2); // 白は行2が最前線
      expect(board.getFrontLine(Player.black), 6); // 黒は行6が最前線
    });
  });

  group('Move（指し手）のテスト', () {
    test('移動手を作成できる', () {
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final move = Move.move(
        piece: piece,
        from: Position(0, 0),
        to: Position(1, 0),
        player: Player.white,
      );
      expect(move.type, MoveType.move);
      expect(move.from, Position(0, 0));
      expect(move.to, Position(1, 0));
    });

    test('捕獲手を作成できる', () {
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final move = Move.capture(
        piece: piece,
        from: Position(0, 0),
        to: Position(1, 0),
        player: Player.white,
      );
      expect(move.type, MoveType.capture);
    });

    test('ツケ手を作成できる', () {
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final move = Move.stack(
        piece: piece,
        from: Position(0, 0),
        to: Position(1, 0),
        player: Player.white,
        isAttack: false,
      );
      expect(move.type, MoveType.stack);
    });

    test('新手を作成できる', () {
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final move = Move.drop(
        piece: piece,
        to: Position(1, 0),
        player: Player.white,
      );
      expect(move.type, MoveType.drop);
      expect(move.from, null);
    });
  });

  group('GameState（ゲーム状態）のテスト', () {
    test('初期状態で先手が手番', () {
      final state = GameState(
        ruleLevel: RuleLevel.elementary,
        phase: GamePhase.playing,
      );
      expect(state.currentPlayer, Player.white);
      expect(state.phase, GamePhase.playing);
    });

    test('copyWithで手番を変更できる', () {
      final state = GameState(
        ruleLevel: RuleLevel.elementary,
        phase: GamePhase.playing,
      );
      expect(state.currentPlayer, Player.white);

      final newState = state.copyWith(currentPlayer: Player.black);
      expect(newState.currentPlayer, Player.black);
    });
  });

  group('MoveValidator（合法手判定）のテスト', () {
    test('空の盤面では手駒からの新のみ可能', () {
      final state = GameState(
        board: Board(),
        currentPlayer: Player.white,
        handPieces: {
          Player.white: [
            Piece(type: PieceType.hei, owner: Player.white, id: 1),
          ],
          Player.black: [],
        },
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 全ての手が新手であること
      expect(moves.every((m) => m.type == MoveType.drop), true);
    });

    test('兵は前方1マスに移動できる', () {
      final board = Board();
      final hei = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      board.placePiece(Position(0, 4), hei);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 兵は前方1マス（白の場合は行+1）に移動可能
      final moveMoves = moves.where((m) => m.type == MoveType.move).toList();
      expect(moveMoves.any((m) => m.to == Position(1, 4)), true);
    });

    test('スタック高さ制限が適用される', () {
      final board = Board();
      final hei1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final hei2 = Piece(type: PieceType.hei, owner: Player.white, id: 2);
      final hei3 = Piece(type: PieceType.hei, owner: Player.white, id: 3);

      // 2段スタックを作成
      board.placePiece(Position(0, 0), hei1);
      board.placePiece(Position(0, 0), hei2);

      // 隣に駒を配置
      board.placePiece(Position(1, 0), hei3);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary, // maxHeight = 2
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 既に2段のスタックにはツケできない（初級編は最大2段）
      final stackMoves = moves.where((m) =>
        m.type == MoveType.stack &&
        m.to == Position(0, 0)
      ).toList();
      expect(stackMoves.isEmpty, true);
    });

    test('高さ優位：低い駒は高い駒を攻撃できない', () {
      final board = Board();
      final whiteHei = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final blackHei1 = Piece(type: PieceType.hei, owner: Player.black, id: 2);
      final blackHei2 = Piece(type: PieceType.hei, owner: Player.black, id: 3);

      // 白兵を配置（1段）
      board.placePiece(Position(4, 4), whiteHei);

      // 黒兵を2段スタックで配置（隣接マス）
      board.placePiece(Position(4, 5), blackHei1);
      board.placePiece(Position(4, 5), blackHei2);

      final state = GameState(
        board: board,
        currentPlayer: Player.white,
        handPieces: {Player.white: [], Player.black: []},
        phase: GamePhase.playing,
        ruleLevel: RuleLevel.elementary,
      );

      final validator = MoveValidator(state);
      final moves = validator.generateAllLegalMoves();

      // 1段の白兵は2段の黒スタックを捕獲できない
      final captureMoves = moves.where((m) =>
        m.type == MoveType.capture &&
        m.to == Position(4, 5)
      ).toList();
      expect(captureMoves.isEmpty, true);
    });
  });

  group('勝敗判定のテスト', () {
    test('帥が捕獲されたら勝利', () {
      final board = Board();

      // 白帥を配置
      final whiteSui = Piece(type: PieceType.sui, owner: Player.white, id: 1);
      board.placePiece(Position(0, 4), whiteSui);

      // 黒帥を配置
      final blackSui = Piece(type: PieceType.sui, owner: Player.black, id: 2);
      board.placePiece(Position(8, 4), blackSui);

      // 白帥が盤上にある状態
      expect(board.findSui(Player.white), isNotNull);

      // 白帥を除去（捕獲をシミュレート）
      board.getStack(Position(0, 4)).clear();

      // 白帥が盤上にない = 黒の勝利
      expect(board.findSui(Player.white), isNull);
    });
  });
}
