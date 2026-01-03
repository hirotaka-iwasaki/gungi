import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_player.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/board_widget.dart';
import '../widgets/hand_area_widget.dart';
import '../widgets/move_history_widget.dart';

/// ゲーム画面
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  GamePhase? _previousPhase;

  @override
  void initState() {
    super.initState();
    // 初期フェーズを記録
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousPhase = ref.read(gameProvider).phase;
    });
  }

  /// タイトルに戻る確認
  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タイトルに戻る'),
        content: const Text('対局を中断してタイトル画面に戻りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              Navigator.pop(context); // ゲーム画面を閉じる
            },
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  void _showNewGameDialog(BuildContext context, GameNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規対局'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('対戦相手を選択:'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.initializeGame(level: RuleLevel.elementary);
              },
              child: const Text('2人対戦'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.initializeGame(
                  level: RuleLevel.elementary,
                  aiDifficulty: AiDifficulty.easy,
                );
              },
              child: const Text('CPU対戦（初級）'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.initializeGame(
                  level: RuleLevel.elementary,
                  aiDifficulty: AiDifficulty.medium,
                );
              },
              child: const Text('CPU対戦（中級）'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.initializeGame(
                  level: RuleLevel.elementary,
                  aiDifficulty: AiDifficulty.hard,
                );
              },
              child: const Text('CPU対戦（上級）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    // フェーズ変化を検知して対局開始ダイアログを表示
    if (_previousPhase == GamePhase.setup && gameState.phase == GamePhase.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameStartDialog();
      });
    }
    _previousPhase = gameState.phase;

    // ルールレベル名
    final levelName = switch (gameState.ruleLevel) {
      RuleLevel.beginner => '入門編',
      RuleLevel.elementary => '初級編',
      RuleLevel.intermediate => '中級編',
      RuleLevel.advanced => '上級編',
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _confirmExit(context),
          tooltip: 'タイトルに戻る',
        ),
        title: Text('軍儀 - $levelName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => MoveHistoryDialog.show(context, gameState.moveHistory),
            tooltip: '棋譜',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showNewGameDialog(context, notifier),
            tooltip: '新規対局',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPortrait = constraints.maxHeight > constraints.maxWidth;

            if (isPortrait) {
              return _buildPortraitLayout(gameState, notifier, constraints);
            } else {
              return _buildLandscapeLayout(gameState, notifier, constraints);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    GameState gameState,
    GameNotifier notifier,
    BoxConstraints constraints,
  ) {
    final boardSize = constraints.maxWidth - 32;

    return Column(
      children: [
        // 相手の情報・手駒
        Padding(
          padding: const EdgeInsets.all(8),
          child: _buildPlayerInfo(
            gameState,
            notifier,
            Player.black,
            isCurrentPlayer: gameState.currentPlayer == Player.black,
          ),
        ),

        // 盤面
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: BoardWidget(
                  board: gameState.board,
                  selectedPosition: notifier.selectedPosition,
                  legalMoves: notifier.legalMoves,
                  lastMove: notifier.lastMove,
                  viewPoint: Player.white,
                  onCellTap: notifier.onCellTap,
                ),
              ),
            ),
          ),
        ),

        // 自分の情報・手駒
        Padding(
          padding: const EdgeInsets.all(8),
          child: _buildPlayerInfo(
            gameState,
            notifier,
            Player.white,
            isCurrentPlayer: gameState.currentPlayer == Player.white,
          ),
        ),

        // ゲーム状態表示
        _buildGameStatus(gameState),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    GameState gameState,
    GameNotifier notifier,
    BoxConstraints constraints,
  ) {
    final boardSize = constraints.maxHeight - 32;

    return Row(
      children: [
        // 左パネル：後手情報
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildPlayerInfo(
                  gameState,
                  notifier,
                  Player.black,
                  isCurrentPlayer: gameState.currentPlayer == Player.black,
                ),
                const Spacer(),
                _buildGameStatus(gameState),
              ],
            ),
          ),
        ),

        // 盤面
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: BoardWidget(
                board: gameState.board,
                selectedPosition: notifier.selectedPosition,
                legalMoves: notifier.legalMoves,
                lastMove: notifier.lastMove,
                viewPoint: Player.white,
                onCellTap: notifier.onCellTap,
              ),
            ),
          ),
        ),

        // 右パネル：先手情報
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildPlayerInfo(
                  gameState,
                  notifier,
                  Player.white,
                  isCurrentPlayer: gameState.currentPlayer == Player.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo(
    GameState gameState,
    GameNotifier notifier,
    Player player, {
    required bool isCurrentPlayer,
  }) {
    final handPieces = gameState.handPieces[player] ?? [];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? Colors.blue.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentPlayer
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.person,
                color: isCurrentPlayer ? Colors.blue : Colors.white54,
              ),
              const SizedBox(width: 8),
              Text(
                player == Player.white ? '先手' : '後手',
                style: TextStyle(
                  color: isCurrentPlayer ? Colors.blue : Colors.white,
                  fontWeight:
                      isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isCurrentPlayer) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '手番',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          HandAreaWidget(
            pieces: handPieces,
            player: player,
            selectedPiece: notifier.selectedHandPiece,
            onPieceTap: isCurrentPlayer ? notifier.onHandPieceTap : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatus(GameState gameState) {
    final notifier = ref.read(gameProvider.notifier);
    String statusText;
    Color statusColor;

    switch (gameState.phase) {
      case GamePhase.setup:
        if (gameState.isAiThinking) {
          statusText = 'CPU配置中...';
          statusColor = Colors.purple;
        } else {
          final playerName = gameState.currentPlayer == Player.white ? '先手' : '後手';
          statusText = '$playerName 初期配置中...';
          statusColor = Colors.orange;
        }
        break;
      case GamePhase.playing:
        if (gameState.isAiThinking) {
          statusText = 'CPU思考中...';
          statusColor = Colors.purple;
        } else {
          final playerName = gameState.currentPlayer == Player.white
              ? '先手（あなた）'
              : (notifier.isAiEnabled ? 'CPU' : '後手');
          statusText = '$playerNameの番';
          statusColor = Colors.green;
        }
        break;
      case GamePhase.finished:
        final winner = gameState.winner == Player.white ? '先手' : '後手';
        statusText = '$winnerの勝利！';
        statusColor = Colors.yellow;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (gameState.isAiThinking)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 初期配置フェーズで先手が未完了なら「配置完了」ボタンを表示
          if (gameState.phase == GamePhase.setup &&
              !gameState.isSetupFinished(Player.white) &&
              !gameState.isAiThinking) ...[
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => _confirmFinishSetup(notifier),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('配置完了'),
            ),
          ],
        ],
      ),
    );
  }

  /// 対局開始ダイアログ
  void _showGameStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.green),
            SizedBox(width: 8),
            Text('対局開始'),
          ],
        ),
        content: const Text('初期配置が完了しました。\n先手から対局を開始します。'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('開始'),
          ),
        ],
      ),
    );
  }

  /// 配置完了確認ダイアログ
  void _confirmFinishSetup(GameNotifier notifier) {
    final gameState = ref.read(gameProvider);
    final whiteHand = gameState.handPieces[Player.white] ?? [];
    final blackHand = gameState.handPieces[Player.black] ?? [];

    // 先手の帥が配置されているかチェック
    final whiteSui = gameState.board.findSui(Player.white);

    if (whiteSui == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('帥を配置してから完了してください')),
      );
      return;
    }

    // CPU対戦かつ後手が未完了の場合のメッセージ
    final cpuMessage = notifier.isAiEnabled && !gameState.isSetupFinished(Player.black)
        ? '\n（CPUは続けて配置します）'
        : '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配置完了'),
        content: Text(
          '配置を完了しますか？$cpuMessage\n\n'
          '先手の残り手駒: ${whiteHand.length}枚\n'
          '後手の残り手駒: ${blackHand.length}枚',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.finishSetup();
            },
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }
}
