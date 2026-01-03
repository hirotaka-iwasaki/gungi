import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// 駒ウィジェット（アニメーション対応）
class PieceWidget extends StatefulWidget {
  final Piece piece;
  final double size;
  final bool isSelected;
  final int stackPosition; // スタック内の位置（0が最下層）
  final int stackHeight; // スタックの総高さ

  const PieceWidget({
    super.key,
    required this.piece,
    required this.size,
    this.isSelected = false,
    this.stackPosition = 0,
    this.stackHeight = 1,
  });

  @override
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isSelected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PieceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = widget.piece.owner == Player.white;

    // スタック表示用のオフセット（高さに応じて浮き上がる効果）
    final offset = (widget.stackHeight - 1 - widget.stackPosition) * 4.0;

    // 駒の基本色とグラデーション
    final baseColor = isWhite ? AppTheme.whitePieceColor : AppTheme.blackPieceColor;
    final borderColor = isWhite
        ? AppTheme.whitePieceBorderColor
        : AppTheme.blackPieceBorderColor;
    final textColor = isWhite
        ? AppTheme.whitePieceTextColor
        : AppTheme.blackPieceTextColor;

    Widget pieceContent = Container(
      width: widget.size * 0.85,
      height: widget.size * 0.85,
      decoration: BoxDecoration(
        // 立体感のあるグラデーション
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWhite
              ? [
                  const Color(0xFFFFFBF0), // 明るい象牙色
                  baseColor,
                  const Color(0xFFE8D4B8), // 暗めの象牙色
                ]
              : [
                  const Color(0xFF3A3A3A), // 明るい漆黒
                  baseColor,
                  const Color(0xFF0A0A0A), // 深い漆黒
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: 2.0,
        ),
        boxShadow: [
          // メインの影（立体感）
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: Offset(2 + offset * 0.3, 2 + offset * 0.3),
            blurRadius: 4 + offset * 0.5,
          ),
          // 内側の光沢感
          BoxShadow(
            color: isWhite
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
            offset: const Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 駒の漢字（墨書風）
          Center(
            child: Text(
              widget.piece.kanji,
              style: TextStyle(
                fontSize: widget.size * 0.5,
                fontWeight: FontWeight.w900,
                color: textColor,
                shadows: isWhite
                    ? null
                    : [
                        Shadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          offset: const Offset(0.5, 0.5),
                          blurRadius: 2,
                        ),
                      ],
              ),
            ),
          ),
          // スタック高さ表示（2段以上の場合）- 金の装飾風
          if (widget.stackHeight > 1 && widget.stackPosition == widget.stackHeight - 1)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: widget.size * 0.22,
                height: widget.size * 0.22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD700), // 金色
                      Color(0xFFB8860B), // 暗めの金色
                    ],
                  ),
                  shape: BoxShape.circle,
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
                child: Center(
                  child: Text(
                    '${widget.stackHeight}',
                    style: TextStyle(
                      fontSize: widget.size * 0.14,
                      color: const Color(0xFF3D2314),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // 選択時のアニメーション
    if (widget.isSelected) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -offset),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                children: [
                  // グロー効果
                  Container(
                    width: widget.size * 0.85,
                    height: widget.size * 0.85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.selectedColor.withValues(
                            alpha: 0.5 * _glowAnimation.value,
                          ),
                          blurRadius: 12 * _glowAnimation.value,
                          spreadRadius: 2 * _glowAnimation.value,
                        ),
                      ],
                    ),
                  ),
                  child!,
                ],
              ),
            ),
          );
        },
        child: pieceContent,
      );
    }

    return Transform.translate(
      offset: Offset(0, -offset),
      child: pieceContent,
    );
  }
}

/// 手駒表示用の駒ウィジェット
class HandPieceWidget extends StatelessWidget {
  final Piece piece;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  const HandPieceWidget({
    super.key,
    required this.piece,
    required this.size,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: PieceWidget(
        piece: piece,
        size: size,
        isSelected: isSelected,
      ),
    );
  }
}
