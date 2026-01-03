// 盤面ロジックの単体テスト
import 'package:flutter_test/flutter_test.dart';
import 'package:gungi/models/board.dart';
import 'package:gungi/models/piece.dart';
import 'package:gungi/models/position.dart';
import 'package:gungi/utils/constants.dart';

void main() {
  group('Board初期化テスト', () {
    test('盤面は9x9で初期化される', () {
      final board = Board();
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          expect(board.getStack(Position(r, c)).isEmpty, true);
        }
      }
    });
  });

  group('getStackのテスト', () {
    test('有効な座標でスタックを取得できる', () {
      final board = Board();
      expect(() => board.getStack(Position(0, 0)), returnsNormally);
      expect(() => board.getStack(Position(8, 8)), returnsNormally);
    });

    test('無効な座標でエラーが発生する', () {
      final board = Board();
      expect(() => board.getStack(Position(-1, 0)), throwsArgumentError);
      expect(() => board.getStack(Position(0, -1)), throwsArgumentError);
      expect(() => board.getStack(Position(9, 0)), throwsArgumentError);
      expect(() => board.getStack(Position(0, 9)), throwsArgumentError);
    });
  });

  group('placePieceのテスト', () {
    test('駒を配置できる', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final pos = Position(0, 0);

      board.placePiece(pos, piece);
      expect(board.getStack(pos).top, piece);
      expect(board.getStack(pos).height, 1);
    });

    test('同じ位置に複数の駒を積める', () {
      final board = Board();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);
      final pos = Position(0, 0);

      board.placePiece(pos, piece1);
      board.placePiece(pos, piece2);

      expect(board.getStack(pos).height, 2);
      expect(board.getStack(pos).top, piece2);
    });
  });

  group('removePieceのテスト', () {
    test('最上部の駒を取り除ける', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final pos = Position(0, 0);

      board.placePiece(pos, piece);
      final removed = board.removePiece(pos);

      expect(removed, piece);
      expect(board.getStack(pos).isEmpty, true);
    });

    test('空のスタックからはnullが返る', () {
      final board = Board();
      final removed = board.removePiece(Position(0, 0));
      expect(removed, null);
    });

    test('スタックから1枚だけ取り除かれる', () {
      final board = Board();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);
      final pos = Position(0, 0);

      board.placePiece(pos, piece1);
      board.placePiece(pos, piece2);

      final removed = board.removePiece(pos);

      expect(removed, piece2);
      expect(board.getStack(pos).height, 1);
      expect(board.getStack(pos).top, piece1);
    });
  });

  group('captureStackのテスト', () {
    test('スタック全体を取り除ける', () {
      final board = Board();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);
      final pos = Position(0, 0);

      board.placePiece(pos, piece1);
      board.placePiece(pos, piece2);

      final captured = board.captureStack(pos);

      expect(captured.length, 2);
      expect(captured[0], piece1);
      expect(captured[1], piece2);
      expect(board.getStack(pos).isEmpty, true);
    });

    test('空のスタックからは空リストが返る', () {
      final board = Board();
      final captured = board.captureStack(Position(0, 0));
      expect(captured.isEmpty, true);
    });
  });

  group('movePieceのテスト', () {
    test('駒を移動できる', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final from = Position(0, 0);
      final to = Position(1, 0);

      board.placePiece(from, piece);
      board.movePiece(from, to);

      expect(board.getStack(from).isEmpty, true);
      expect(board.getStack(to).top, piece);
    });

    test('移動先にスタックがあれば上に乗る', () {
      final board = Board();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);
      final from = Position(0, 0);
      final to = Position(1, 0);

      board.placePiece(to, piece1);
      board.placePiece(from, piece2);
      board.movePiece(from, to);

      expect(board.getStack(to).height, 2);
      expect(board.getStack(to).top, piece2);
    });

    test('空の位置からの移動は何も起きない', () {
      final board = Board();
      final from = Position(0, 0);
      final to = Position(1, 0);

      board.movePiece(from, to);
      expect(board.getStack(to).isEmpty, true);
    });
  });

  group('moveStackのテスト', () {
    test('スタック全体を移動できる', () {
      final board = Board();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);
      final from = Position(0, 0);
      final to = Position(1, 0);

      board.placePiece(from, piece1);
      board.placePiece(from, piece2);
      board.moveStack(from, to);

      expect(board.getStack(from).isEmpty, true);
      expect(board.getStack(to).height, 2);
      expect(board.getStack(to).pieceAt(0), piece1);
      expect(board.getStack(to).pieceAt(1), piece2);
    });

    test('移動先にスタックがあれば合流する', () {
      final board = Board();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);
      final piece3 = Piece(type: PieceType.dai, owner: Player.white, id: 3);
      final from = Position(0, 0);
      final to = Position(1, 0);

      board.placePiece(to, piece1);
      board.placePiece(from, piece2);
      board.placePiece(from, piece3);
      board.moveStack(from, to);

      expect(board.getStack(to).height, 3);
      expect(board.getStack(to).pieceAt(0), piece1);
      expect(board.getStack(to).pieceAt(1), piece2);
      expect(board.getStack(to).pieceAt(2), piece3);
    });
  });

  group('getPieceのテスト', () {
    test('最上部の駒を取得できる', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);

      board.placePiece(Position(0, 0), piece);
      expect(board.getPiece(Position(0, 0)), piece);
    });

    test('空のマスはnullを返す', () {
      final board = Board();
      expect(board.getPiece(Position(0, 0)), null);
    });
  });

  group('getHeightのテスト', () {
    test('スタックの高さを取得できる', () {
      final board = Board();
      expect(board.getHeight(Position(0, 0)), 0);

      board.placePiece(Position(0, 0), Piece(type: PieceType.hei, owner: Player.white, id: 1));
      expect(board.getHeight(Position(0, 0)), 1);

      board.placePiece(Position(0, 0), Piece(type: PieceType.chu, owner: Player.white, id: 2));
      expect(board.getHeight(Position(0, 0)), 2);
    });
  });

  group('isEmptyのテスト', () {
    test('空マスを判定できる', () {
      final board = Board();
      expect(board.isEmpty(Position(0, 0)), true);

      board.placePiece(Position(0, 0), Piece(type: PieceType.hei, owner: Player.white, id: 1));
      expect(board.isEmpty(Position(0, 0)), false);
    });
  });

  group('findSuiのテスト', () {
    test('帥の位置を取得できる', () {
      final board = Board();
      final whiteSui = Piece(type: PieceType.sui, owner: Player.white, id: 1);
      final blackSui = Piece(type: PieceType.sui, owner: Player.black, id: 2);

      board.placePiece(Position(0, 4), whiteSui);
      board.placePiece(Position(8, 4), blackSui);

      expect(board.findSui(Player.white), Position(0, 4));
      expect(board.findSui(Player.black), Position(8, 4));
    });

    test('帥がスタック内にあっても見つかる', () {
      final board = Board();
      final sui = Piece(type: PieceType.sui, owner: Player.white, id: 1);
      final hei = Piece(type: PieceType.hei, owner: Player.white, id: 2);

      board.placePiece(Position(0, 4), sui);
      board.placePiece(Position(0, 4), hei); // 帥の上に兵を積む

      expect(board.findSui(Player.white), Position(0, 4));
    });

    test('帥がない場合はnullを返す', () {
      final board = Board();
      expect(board.findSui(Player.white), null);
      expect(board.findSui(Player.black), null);
    });
  });

  group('getFrontLineのテスト', () {
    test('最前線を正しく計算できる（白）', () {
      final board = Board();

      // 白駒を配置
      board.placePiece(Position(0, 0), Piece(type: PieceType.hei, owner: Player.white, id: 1));
      board.placePiece(Position(2, 0), Piece(type: PieceType.hei, owner: Player.white, id: 2));
      board.placePiece(Position(5, 4), Piece(type: PieceType.hei, owner: Player.white, id: 3));

      // 白は最も大きいrow（前進している位置）が最前線
      expect(board.getFrontLine(Player.white), 5);
    });

    test('最前線を正しく計算できる（黒）', () {
      final board = Board();

      // 黒駒を配置
      board.placePiece(Position(8, 0), Piece(type: PieceType.hei, owner: Player.black, id: 1));
      board.placePiece(Position(6, 0), Piece(type: PieceType.hei, owner: Player.black, id: 2));
      board.placePiece(Position(3, 4), Piece(type: PieceType.hei, owner: Player.black, id: 3));

      // 黒は最も小さいrow（前進している位置）が最前線
      expect(board.getFrontLine(Player.black), 3);
    });

    test('駒がない場合のデフォルト値', () {
      final board = Board();
      expect(board.getFrontLine(Player.white), 0);
      expect(board.getFrontLine(Player.black), 8);
    });
  });

  group('copyのテスト', () {
    test('盤面をコピーできる', () {
      final board = Board();
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      board.placePiece(Position(0, 0), piece);

      final copy = board.copy();

      // コピー先に同じ駒がある
      expect(copy.getStack(Position(0, 0)).top, piece);
    });

    test('コピーは独立している', () {
      final board = Board();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);
      board.placePiece(Position(0, 0), piece1);

      final copy = board.copy();
      copy.placePiece(Position(0, 0), piece2);

      // 元の盤面は変わっていない
      expect(board.getStack(Position(0, 0)).height, 1);
      expect(copy.getStack(Position(0, 0)).height, 2);
    });
  });

  group('toDebugStringのテスト', () {
    test('デバッグ文字列が生成される', () {
      final board = Board();
      board.placePiece(Position(4, 4), Piece(type: PieceType.sui, owner: Player.white, id: 1));

      final debugString = board.toDebugString();

      expect(debugString.contains('帥'), true);
      expect(debugString.contains('・'), true);
      expect(debugString.isNotEmpty, true);
    });
  });

  group('PieceStack追加テスト', () {
    test('pieceAtで指定位置の駒を取得できる', () {
      final stack = PieceStack();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);

      stack.push(piece1);
      stack.push(piece2);

      expect(stack.pieceAt(0), piece1);
      expect(stack.pieceAt(1), piece2);
      expect(stack.pieceAt(2), null);
      expect(stack.pieceAt(-1), null);
    });

    test('isNotEmptyが正しく動作する', () {
      final stack = PieceStack();
      expect(stack.isNotEmpty, false);

      stack.push(Piece(type: PieceType.hei, owner: Player.white, id: 1));
      expect(stack.isNotEmpty, true);
    });

    test('piecesで全駒を取得できる（不変リスト）', () {
      final stack = PieceStack();
      final piece1 = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final piece2 = Piece(type: PieceType.chu, owner: Player.white, id: 2);

      stack.push(piece1);
      stack.push(piece2);

      final pieces = stack.pieces;
      expect(pieces.length, 2);
      expect(pieces[0], piece1);
      expect(pieces[1], piece2);
    });

    test('controllerが最上部の駒の所有者を返す', () {
      final stack = PieceStack();
      expect(stack.controller, null);

      stack.push(Piece(type: PieceType.hei, owner: Player.white, id: 1));
      expect(stack.controller, Player.white);

      stack.push(Piece(type: PieceType.hei, owner: Player.black, id: 2));
      expect(stack.controller, Player.black);
    });

    test('toStringが正しく出力される', () {
      final stack = PieceStack();
      stack.push(Piece(type: PieceType.hei, owner: Player.white, id: 1));
      stack.push(Piece(type: PieceType.chu, owner: Player.white, id: 2));

      expect(stack.toString(), '兵|中');
    });

    test('PieceStack.fromで初期化できる', () {
      final piece = Piece(type: PieceType.hei, owner: Player.white, id: 1);
      final stack = PieceStack.from([piece]);

      expect(stack.height, 1);
      expect(stack.top, piece);
    });
  });
}
