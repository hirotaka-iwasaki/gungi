import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../utils/constants.dart';

/// スタック詳細表示ウィジェット
/// 重なった駒の詳細を確認できるダイアログ
class StackViewer extends StatelessWidget {
  final Position position;
  final PieceStack stack;

  const StackViewer({
    super.key,
    required this.position,
    required this.stack,
  });

  /// ダイアログを表示
  static void show(BuildContext context, Position position, PieceStack stack) {
    if (stack.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => StackViewer(
        position: position,
        stack: stack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pieces = stack.pieces;

    return AlertDialog(
      title: Text('${position.toNotation()} のスタック'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // スタックの視覚的表示（上から下へ）
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.brown.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.brown.shade300),
            ),
            child: Column(
              children: [
                for (int i = pieces.length - 1; i >= 0; i--)
                  _buildPieceRow(pieces[i], i + 1, i == pieces.length - 1),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 説明
          Text(
            'スタック高さ: ${stack.height}段',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (stack.height >= 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '移動距離 +${stack.height - 1}',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  Widget _buildPieceRow(Piece piece, int level, bool isTop) {
    final isWhite = piece.owner == Player.white;
    final bgColor = isWhite ? Colors.white : Colors.grey.shade800;
    final textColor = isWhite ? Colors.black : Colors.white;
    final borderColor = isTop ? Colors.amber : Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor,
          width: isTop ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 段数
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$level',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 駒名
          Text(
            piece.kanji,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 12),
          // プレイヤー
          Text(
            isWhite ? '先手' : '後手',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          if (isTop) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '最上',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
