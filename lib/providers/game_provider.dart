import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_player.dart';
import '../ai/minimax_ai.dart';
import '../ai/random_ai.dart';
import '../logic/move_validator.dart';
import '../models/game_state.dart';
import '../models/move.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../utils/constants.dart';

/// ゲーム状態プロバイダー
class GameNotifier extends Notifier<GameState> {
  Position? _selectedPosition;
  Piece? _selectedHandPiece;
  List<Move> _legalMoves = [];
  Move? _lastMove;
  AiPlayer? _aiPlayer;

  Position? get selectedPosition => _selectedPosition;
  Piece? get selectedHandPiece => _selectedHandPiece;
  List<Move> get legalMoves => _legalMoves;
  Move? get lastMove => _lastMove;
  bool get isAiEnabled => _aiPlayer != null;
  bool get isAiThinking => state.isAiThinking;
  AiPlayer? get aiPlayer => _aiPlayer;

  @override
  GameState build() {
    return GameState();
  }

  /// ゲームを初期化
  void initializeGame({
    RuleLevel level = RuleLevel.advanced,
    AiDifficulty? aiDifficulty,
  }) {
    final newState = GameState(ruleLevel: level);
    newState.initializePieces();

    if (!level.freeSetup) {
      // 固定配置
      newState.setupFixedPosition();
      state = newState.startGame();
    } else {
      state = newState;
    }

    _selectedPosition = null;
    _selectedHandPiece = null;
    _legalMoves = [];
    _lastMove = null;

    // AI設定
    if (aiDifficulty != null) {
      _aiPlayer = _createAi(aiDifficulty, Player.black);
    } else {
      _aiPlayer = null;
    }

    // 初期盤面をログ出力
    developer.log('=== 新規対局開始 (${level.name}) ===');
    print('=== 新規対局開始 (${level.name}) ===');
    if (_aiPlayer != null) {
      developer.log('AI: ${_aiPlayer!.name}');
      print('AI: ${_aiPlayer!.name}');
    }
    developer.log(state.board.toDebugString());
    print(state.board.toDebugString());
  }

  /// AIを生成
  AiPlayer _createAi(AiDifficulty difficulty, Player player) {
    switch (difficulty) {
      case AiDifficulty.easy:
        return RandomAi();
      case AiDifficulty.medium:
        return MinimaxAi(aiPlayer: player, depth: 2);
      case AiDifficulty.hard:
        return MinimaxAi(aiPlayer: player, depth: 3, maxMovesToConsider: 25);
    }
  }

  /// セルをタップ
  void onCellTap(Position pos) {
    if (state.phase == GamePhase.finished) return;

    if (state.phase == GamePhase.setup) {
      _handleSetupTap(pos);
      return;
    }

    _handlePlayingTap(pos);
  }

  /// 初期配置フェーズでのタップ処理
  /// 中級・上級編では交互に1枚ずつ配置する
  void _handleSetupTap(Position pos) {
    if (_selectedHandPiece == null) return;

    // 配置完了済みなら操作不可
    if (state.isSetupFinished(state.currentPlayer)) return;

    // 自陣（3段目まで）に配置可能
    // 先手(white): row 0-2、後手(black): row 6-8
    final isWhite = state.currentPlayer == Player.white;
    final validRow = isWhite ? pos.row <= 2 : pos.row >= 6;

    if (!validRow) return;

    final stack = state.board.getStack(pos);
    if (stack.isNotEmpty) return; // 既に駒がある場合は配置不可

    // 配置を実行
    final move = Move.drop(
      piece: _selectedHandPiece!,
      to: pos,
      player: state.currentPlayer,
    );

    developer.log('[配置] ${state.currentPlayer == Player.white ? "先手" : "後手"}: ${_selectedHandPiece!.kanji} -> ${pos.toNotation()}');
    print('[配置] ${state.currentPlayer == Player.white ? "先手" : "後手"}: ${_selectedHandPiece!.kanji} -> ${pos.toNotation()}');

    state = state.applyMove(move);
    _selectedHandPiece = null;
    _legalMoves = [];
    _lastMove = move;

    // AIの手番なら自動で配置
    _checkAiTurn();
  }

  /// 配置可能なマスを取得（セットアップ用）
  List<Position> getValidSetupPositions() {
    if (state.phase != GamePhase.setup) return [];

    final positions = <Position>[];
    final isWhite = state.currentPlayer == Player.white;

    for (int r = 0; r < boardSize; r++) {
      // 自陣3段のみ
      if (isWhite && r > 2) continue;
      if (!isWhite && r < 6) continue;

      for (int c = 0; c < boardSize; c++) {
        final pos = Position(r, c);
        if (state.board.isEmpty(pos)) {
          positions.add(pos);
        }
      }
    }

    return positions;
  }

  /// 対局フェーズでのタップ処理
  void _handlePlayingTap(Position pos) {
    final stack = state.board.getStack(pos);

    // 手駒が選択されている場合
    if (_selectedHandPiece != null) {
      final dropMove = _legalMoves.firstWhere(
        (m) => m.to == pos && m.type == MoveType.drop,
        orElse: () => Move.drop(
            piece: _selectedHandPiece!, to: pos, player: state.currentPlayer),
      );

      if (_legalMoves.any((m) => m.to == pos && m.type == MoveType.drop)) {
        _applyMove(dropMove);
      } else {
        // 選択解除
        _selectedHandPiece = null;
        _legalMoves = [];
        state = state.copyWith();
      }
      return;
    }

    // 盤上の駒が選択されている場合
    if (_selectedPosition != null) {
      // 同じ位置をタップしたら選択解除
      if (_selectedPosition == pos) {
        _clearSelection();
        return;
      }

      // 合法手の中から一致する手を探す
      final matchingMove = _legalMoves.where((m) => m.to == pos).toList();

      if (matchingMove.isNotEmpty) {
        // 複数の選択肢がある場合（捕獲 or ツケ）
        if (matchingMove.length > 1) {
          // TODO: ダイアログで選択させる
          // 今は捕獲を優先
          final captureMove = matchingMove.firstWhere(
            (m) => m.type == MoveType.capture,
            orElse: () => matchingMove.first,
          );
          _applyMove(captureMove);
        } else {
          _applyMove(matchingMove.first);
        }
        return;
      }

      // 自分の別の駒を選択
      if (stack.isNotEmpty && stack.controller == state.currentPlayer) {
        _selectPosition(pos);
        return;
      }

      // 選択解除
      _clearSelection();
      return;
    }

    // 何も選択されていない場合、自分の駒を選択
    if (stack.isNotEmpty && stack.controller == state.currentPlayer) {
      _selectPosition(pos);
    }
  }

  /// 位置を選択
  void _selectPosition(Position pos) {
    _selectedPosition = pos;
    _selectedHandPiece = null;

    final validator = MoveValidator(state);
    _legalMoves = validator
        .generateAllLegalMoves()
        .where((m) => m.from == pos)
        .toList();

    state = state.copyWith();
  }

  /// 手駒を選択
  void onHandPieceTap(Piece piece) {
    if (state.phase == GamePhase.finished) return;
    if (piece.owner != state.currentPlayer) return;

    _selectedPosition = null;
    _selectedHandPiece = piece;

    if (state.phase == GamePhase.setup) {
      // 初期配置フェーズ: 自陣3段のどこでも配置可能
      final positions = getValidSetupPositions();
      _legalMoves = positions
          .map((pos) => Move.drop(
                piece: piece,
                to: pos,
                player: state.currentPlayer,
              ))
          .toList();
    } else {
      // 対局フェーズ: 最前線ルールに従う
      final validator = MoveValidator(state);
      _legalMoves = validator
          .generateAllLegalMoves()
          .where((m) => m.type == MoveType.drop && m.piece.type == piece.type)
          .toList();
    }

    state = state.copyWith();
  }

  /// 選択を解除
  void _clearSelection() {
    _selectedPosition = null;
    _selectedHandPiece = null;
    _legalMoves = [];
    state = state.copyWith();
  }

  /// 指し手を適用
  void _applyMove(Move move) {
    final moveNum = state.moveHistory.length + 1;
    final playerName = move.player == Player.white ? '先手' : '後手';

    // 指し手をログ出力
    developer.log('[$moveNum] $playerName: ${move.toNotation()}');
    print('[$moveNum] $playerName: ${move.toNotation()}');

    state = state.applyMove(move);
    _lastMove = move;

    // 盤面状態をログ出力
    developer.log(state.board.toDebugString());
    print(state.board.toDebugString());

    // 勝敗判定結果
    if (state.phase == GamePhase.finished) {
      final winnerName = state.winner == Player.white ? '先手' : '後手';
      developer.log('=== 対局終了: ${winnerName}の勝利 ===');
      print('=== 対局終了: ${winnerName}の勝利 ===');
      _printMoveHistory();
    }

    _clearSelection();

    // AIの手番なら自動で指す
    _checkAiTurn();
  }

  /// AIの手番かチェックして実行
  void _checkAiTurn() {
    if (_aiPlayer == null) return;
    if (state.phase == GamePhase.finished) return;
    if (state.currentPlayer != Player.black) return; // AIは後手

    if (state.phase == GamePhase.setup) {
      _executeAiSetup();
    } else {
      _executeAiMove();
    }
  }

  /// AIの初期配置を実行
  Future<void> _executeAiSetup() async {
    if (state.isAiThinking) return;

    state = state.copyWith(isAiThinking: true);

    try {
      await Future.delayed(const Duration(milliseconds: 200));

      final handPieces = state.handPieces[Player.black] ?? [];

      // 帥が配置済みかチェック
      final suiOnBoard = state.board.findSui(Player.black) != null;

      // 配置完了条件: 帥が配置済み かつ 先手が完了済み
      if (suiOnBoard && state.isSetupFinished(Player.white)) {
        // 40%の確率で完了（平均1〜2枚追加配置）
        final shouldFinish = DateTime.now().microsecond % 10 < 4;
        if (shouldFinish) {
          _finishAiSetup();
          return;
        }
      }

      if (handPieces.isEmpty) {
        _finishAiSetup();
        return;
      }

      // 帥を優先的に選択、なければランダム
      Piece piece;
      final sui = handPieces.where((p) => p.type == PieceType.sui).firstOrNull;
      if (sui != null) {
        piece = sui;
      } else {
        // 重要な駒を優先: 大、中、小、侍、忍 の順
        final priority = [PieceType.dai, PieceType.chu, PieceType.sho, PieceType.samurai, PieceType.shinobi];
        Piece? priorityPiece;
        for (final type in priority) {
          priorityPiece = handPieces.where((p) => p.type == type).firstOrNull;
          if (priorityPiece != null) break;
        }
        piece = priorityPiece ?? handPieces[DateTime.now().millisecondsSinceEpoch % handPieces.length];
      }

      // 配置可能なマスを取得（後手は row 6-8）
      final validPositions = <Position>[];
      for (int r = 6; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          final pos = Position(r, c);
          if (state.board.isEmpty(pos)) {
            validPositions.add(pos);
          }
        }
      }

      if (validPositions.isEmpty) {
        _finishAiSetup();
        return;
      }

      // 帥は中央付近に配置、他はランダム
      Position pos;
      if (piece.type == PieceType.sui) {
        // 中央（8,4）に配置を試みる
        final center = Position(8, 4);
        if (validPositions.contains(center)) {
          pos = center;
        } else {
          pos = validPositions[validPositions.length ~/ 2];
        }
      } else {
        pos = validPositions[DateTime.now().microsecondsSinceEpoch % validPositions.length];
      }

      final move = Move.drop(
        piece: piece,
        to: pos,
        player: Player.black,
      );

      developer.log('[配置] 後手(AI): ${piece.kanji} -> ${pos.toNotation()}');
      print('[配置] 後手(AI): ${piece.kanji} -> ${pos.toNotation()}');

      state = state.applyMove(move);
      _lastMove = move;

      // 先手が配置完了済みなら、続けて配置（applyMoveで手番が維持される）
      if (state.currentPlayer == Player.black && state.phase == GamePhase.setup) {
        state = state.copyWith(isAiThinking: false);
        await Future.delayed(const Duration(milliseconds: 100));
        _checkAiTurn();
        return;
      }
    } catch (e) {
      developer.log('AI setup error: $e');
      print('AI setup error: $e');
    } finally {
      state = state.copyWith(isAiThinking: false);
    }
  }

  /// AIの手を実行
  Future<void> _executeAiMove() async {
    if (state.isAiThinking) return;

    state = state.copyWith(isAiThinking: true);

    try {
      // 少し遅延を入れてUIが更新されるのを待つ
      await Future.delayed(const Duration(milliseconds: 300));

      final move = await _aiPlayer!.selectMove(state);

      if (state.phase != GamePhase.playing) return; // ゲームが終了していたら中止

      final moveNum = state.moveHistory.length + 1;
      developer.log('[$moveNum] AI(後手): ${move.toNotation()}');
      print('[$moveNum] AI(後手): ${move.toNotation()}');

      state = state.applyMove(move);
      _lastMove = move;

      developer.log(state.board.toDebugString());
      print(state.board.toDebugString());

      if (state.phase == GamePhase.finished) {
        final winnerName = state.winner == Player.white ? '先手' : '後手';
        developer.log('=== 対局終了: ${winnerName}の勝利 ===');
        print('=== 対局終了: ${winnerName}の勝利 ===');
        _printMoveHistory();
      }
    } catch (e) {
      developer.log('AI error: $e');
      print('AI error: $e');
    } finally {
      state = state.copyWith(isAiThinking: false);
    }
  }

  /// 棋譜を出力
  void _printMoveHistory() {
    developer.log('--- 棋譜 ---');
    print('--- 棋譜 ---');
    for (int i = 0; i < state.moveHistory.length; i++) {
      final move = state.moveHistory[i];
      final playerName = move.player == Player.white ? '先手' : '後手';
      developer.log('${i + 1}. $playerName: ${move.toNotation()}');
      print('${i + 1}. $playerName: ${move.toNotation()}');
    }
    developer.log('------------');
    print('------------');
  }

  /// 初期配置フェーズを完了（先手用）
  void finishSetup() {
    if (state.phase != GamePhase.setup) return;
    if (state.isSetupFinished(Player.white)) return;

    developer.log('[配置完了] 先手が配置を完了');
    print('[配置完了] 先手が配置を完了');

    state = state.finishPlayerSetup(Player.white);
    _clearSelection();

    // 対局開始したか確認
    if (state.phase == GamePhase.playing) {
      developer.log('=== 初期配置完了、対局開始 ===');
      print('=== 初期配置完了、対局開始 ===');
      developer.log(state.board.toDebugString());
      print(state.board.toDebugString());
      return;
    }

    // CPUの番になったら続きを配置
    _checkAiTurn();
  }

  /// AI用: 配置完了を宣言
  void _finishAiSetup() {
    if (state.phase != GamePhase.setup) return;
    if (state.isSetupFinished(Player.black)) return;

    developer.log('[配置完了] 後手(AI)が配置を完了');
    print('[配置完了] 後手(AI)が配置を完了');

    state = state.finishPlayerSetup(Player.black);

    // 対局開始したか確認
    if (state.phase == GamePhase.playing) {
      developer.log('=== 初期配置完了、対局開始 ===');
      print('=== 初期配置完了、対局開始 ===');
      developer.log(state.board.toDebugString());
      print(state.board.toDebugString());
    }
  }
}

/// ゲームプロバイダー
final gameProvider = NotifierProvider<GameNotifier, GameState>(() {
  return GameNotifier();
});
