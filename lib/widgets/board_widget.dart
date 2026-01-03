import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/move.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'piece_widget.dart';

/// 盤面ウィジェット（アニメーション対応）
class BoardWidget extends StatefulWidget {
  final Board board;
  final Position? selectedPosition;
  final List<Move> legalMoves;
  final Move? lastMove;
  final Player viewPoint; // 視点（どちら側から見るか）
  final Function(Position)? onCellTap;

  const BoardWidget({
    super.key,
    required this.board,
    this.selectedPosition,
    this.legalMoves = const [],
    this.lastMove,
    this.viewPoint = Player.white,
    this.onCellTap,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / boardSize;

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.boardColor,
              border: Border.all(
                color: AppTheme.boardBorderColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(5, 5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Stack(
              children: [
                // 盤面のグリッド線
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxWidth),
                  painter: _BoardGridPainter(),
                ),
                // 駒とセル
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: boardSize,
                  ),
                  itemCount: boardSize * boardSize,
                  itemBuilder: (context, index) {
                    // 視点に応じて座標を変換
                    final row = widget.viewPoint == Player.white
                        ? boardSize - 1 - index ~/ boardSize
                        : index ~/ boardSize;
                    final col = widget.viewPoint == Player.white
                        ? index % boardSize
                        : boardSize - 1 - index % boardSize;

                    final pos = Position(row, col);
                    return _buildCell(pos, cellSize);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCell(Position pos, double cellSize) {
    final stack = widget.board.getStack(pos);
    final isSelected = widget.selectedPosition == pos;
    final isLegalMove = widget.legalMoves.any((m) => m.to == pos);
    final isLastMove = widget.lastMove?.from == pos || widget.lastMove?.to == pos;
    final isCapture = widget.legalMoves.any(
        (m) => m.to == pos && (m.type == MoveType.capture));

    return GestureDetector(
      onTap: () => widget.onCellTap?.call(pos),
      child: Container(
        decoration: BoxDecoration(
          color: _getCellColor(isSelected, isLegalMove, isLastMove, isCapture),
          border: Border.all(
            color: AppTheme.boardLineColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Center(
          child: stack.isNotEmpty
              ? _buildStackedPieces(stack, cellSize, isSelected)
              : isLegalMove
                  ? _buildLegalMoveIndicator(cellSize, isCapture)
                  : null,
        ),
      ),
    );
  }

  Color? _getCellColor(
      bool isSelected, bool isLegalMove, bool isLastMove, bool isCapture) {
    if (isSelected) return AppTheme.selectedColor;
    if (isCapture) return AppTheme.captureColor;
    if (isLegalMove) return AppTheme.legalMoveColor;
    if (isLastMove) return AppTheme.lastMoveColor;
    return null;
  }

  Widget _buildStackedPieces(PieceStack stack, double cellSize, bool isSelected) {
    // 最上部の駒のみ表示（スタック情報付き）
    return PieceWidget(
      piece: stack.top!,
      size: cellSize,
      isSelected: isSelected,
      stackPosition: stack.height - 1,
      stackHeight: stack.height,
    );
  }

  Widget _buildLegalMoveIndicator(double cellSize, bool isCapture) {
    // 合法手インジケーターにパルスアニメーション
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: cellSize * 0.3 * _pulseAnimation.value,
          height: cellSize * 0.3 * _pulseAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCapture
                ? AppTheme.captureColor.withValues(alpha: _pulseAnimation.value)
                : AppTheme.legalMoveColor.withValues(alpha: _pulseAnimation.value * 0.8),
            boxShadow: [
              BoxShadow(
                color: (isCapture ? AppTheme.captureColor : AppTheme.legalMoveColor)
                    .withValues(alpha: 0.5 * _pulseAnimation.value),
                blurRadius: 8 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 盤面のグリッド線を描画（和風デザイン）
class _BoardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / boardSize;

    // 木目調の背景グラデーション
    final bgPaint = Paint();
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        // 市松模様のような微妙な色の違いを出す
        final isLight = (r + c) % 2 == 0;
        bgPaint.color = isLight
            ? AppTheme.boardColorLight.withValues(alpha: 0.3)
            : AppTheme.boardColorDark.withValues(alpha: 0.3);

        canvas.drawRect(
          Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
          bgPaint,
        );
      }
    }

    // グリッド線
    final linePaint = Paint()
      ..color = AppTheme.boardLineColor
      ..strokeWidth = 1.5;

    // 縦線
    for (int i = 0; i <= boardSize; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // 横線
    for (int i = 0; i <= boardSize; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // 星（目印）を描画 - 9路盤の場合は中央と四隅に配置
    final starPaint = Paint()
      ..color = AppTheme.starColor
      ..style = PaintingStyle.fill;

    final starRadius = cellSize * 0.08;

    // 星の位置（0-indexed）
    const starPositions = [
      [2, 2], [2, 6], // 上段
      [4, 4], // 中央（天元）
      [6, 2], [6, 6], // 下段
    ];

    for (final pos in starPositions) {
      final x = (pos[1] + 0.5) * cellSize;
      final y = (pos[0] + 0.5) * cellSize;
      canvas.drawCircle(Offset(x, y), starRadius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
