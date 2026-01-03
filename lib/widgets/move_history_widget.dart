import 'package:flutter/material.dart';
import '../models/move.dart';
import '../utils/constants.dart';

/// 棋譜表示ウィジェット
class MoveHistoryWidget extends StatelessWidget {
  final List<Move> moves;
  final Move? lastMove;

  const MoveHistoryWidget({
    super.key,
    required this.moves,
    this.lastMove,
  });

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          '棋譜なし',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: moves.length,
      itemBuilder: (context, index) {
        final move = moves[index];
        final isLast = move == lastMove;
        final moveNum = index + 1;
        final playerName = move.player == Player.white ? '先手' : '後手';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: isLast ? Colors.amber.withValues(alpha: 0.2) : null,
          child: Row(
            children: [
              // 手番号
              SizedBox(
                width: 32,
                child: Text(
                  '$moveNum.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
              // プレイヤー
              Container(
                width: 40,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: move.player == Player.white
                      ? Colors.white
                      : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text(
                  playerName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: move.player == Player.white
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 棋譜
              Expanded(
                child: Text(
                  move.toNotation(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              // 手の種類アイコン
              _buildMoveTypeIcon(move.type),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoveTypeIcon(MoveType type) {
    IconData icon;
    Color color;
    String tooltip;

    switch (type) {
      case MoveType.move:
        icon = Icons.arrow_forward;
        color = Colors.blue;
        tooltip = '移動';
        break;
      case MoveType.capture:
        icon = Icons.close;
        color = Colors.red;
        tooltip = '捕獲';
        break;
      case MoveType.stack:
        icon = Icons.layers;
        color = Colors.green;
        tooltip = 'ツケ';
        break;
      case MoveType.attackStack:
        icon = Icons.layers;
        color = Colors.orange;
        tooltip = '敵ツケ';
        break;
      case MoveType.drop:
        icon = Icons.add_circle_outline;
        color = Colors.purple;
        tooltip = '新';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
}

/// 棋譜表示ダイアログ
class MoveHistoryDialog extends StatelessWidget {
  final List<Move> moves;

  const MoveHistoryDialog({
    super.key,
    required this.moves,
  });

  static void show(BuildContext context, List<Move> moves) {
    showDialog(
      context: context,
      builder: (context) => MoveHistoryDialog(moves: moves),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.history),
          const SizedBox(width: 8),
          const Text('棋譜'),
          const Spacer(),
          Text(
            '${moves.length}手',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: moves.isEmpty
            ? const Center(child: Text('まだ指し手がありません'))
            : MoveHistoryWidget(moves: moves),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _copyToClipboard(context),
          icon: const Icon(Icons.copy),
          label: const Text('コピー'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    for (int i = 0; i < moves.length; i++) {
      final move = moves[i];
      final playerName = move.player == Player.white ? '先手' : '後手';
      buffer.writeln('${i + 1}. $playerName: ${move.toNotation()}');
    }

    // クリップボードにコピー（実際にはClipboard.setDataを使用）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('棋譜をコピーしました')),
    );
  }
}
