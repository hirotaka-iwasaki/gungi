import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'piece_widget.dart';

/// 手駒エリアウィジェット（和風デザイン）
class HandAreaWidget extends StatelessWidget {
  final List<Piece> pieces;
  final Player player;
  final Piece? selectedPiece;
  final Function(Piece)? onPieceTap;
  final double pieceSize;

  const HandAreaWidget({
    super.key,
    required this.pieces,
    required this.player,
    this.selectedPiece,
    this.onPieceTap,
    this.pieceSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    // 駒を種類ごとにグループ化
    final groupedPieces = <PieceType, List<Piece>>{};
    for (final piece in pieces) {
      groupedPieces.putIfAbsent(piece.type, () => []).add(piece);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // 木目調の背景
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.panelColor.withValues(alpha: 0.9),
            AppTheme.panelColor,
            const Color(0xFF241A14),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ラベル（金色の装飾付き）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                player == Player.white ? '先手持駒' : '後手持駒',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (pieces.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'なし',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: groupedPieces.entries.map((entry) {
                return _buildPieceGroup(entry.key, entry.value);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPieceGroup(PieceType type, List<Piece> pieces) {
    final piece = pieces.first;
    final count = pieces.length;
    final isSelected = selectedPiece != null && selectedPiece!.type == type;

    return GestureDetector(
      onTap: () => onPieceTap?.call(piece),
      child: Stack(
        children: [
          PieceWidget(
            piece: piece,
            size: pieceSize,
            isSelected: isSelected,
          ),
          // 枚数表示（金の装飾風）
          if (count > 1)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFB8860B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8B6914),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  'x$count',
                  style: const TextStyle(
                    color: Color(0xFF3D2314),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
