import '../utils/constants.dart';
import 'board.dart';
import 'move.dart';
import 'piece.dart';
import 'position.dart';

/// ゲームフェーズ
enum GamePhase {
  setup, // 初期配置
  playing, // 対局中
  finished, // 終局
}

/// ゲーム状態クラス
class GameState {
  final Board board;
  final Map<Player, List<Piece>> handPieces; // 手駒（未配置駒）
  final Player currentPlayer;
  final GamePhase phase;
  final RuleLevel ruleLevel;
  final List<Move> moveHistory;
  final Player? winner;
  final Map<Player, bool> setupFinished; // 各プレイヤーの配置完了フラグ
  final bool isAiThinking; // AI思考中フラグ
  int _pieceIdCounter;

  GameState({
    Board? board,
    Map<Player, List<Piece>>? handPieces,
    this.currentPlayer = Player.white,
    this.phase = GamePhase.setup,
    this.ruleLevel = RuleLevel.advanced,
    List<Move>? moveHistory,
    this.winner,
    Map<Player, bool>? setupFinished,
    this.isAiThinking = false,
    int pieceIdCounter = 0,
  })  : board = board ?? Board(),
        handPieces = handPieces ??
            {
              Player.white: [],
              Player.black: [],
            },
        moveHistory = moveHistory ?? [],
        setupFinished = setupFinished ??
            {
              Player.white: false,
              Player.black: false,
            },
        _pieceIdCounter = pieceIdCounter;

  /// 指定プレイヤーが配置完了しているか
  bool isSetupFinished(Player player) => setupFinished[player] ?? false;

  /// 両者とも配置完了しているか
  bool get bothSetupFinished =>
      setupFinished[Player.white] == true && setupFinished[Player.black] == true;

  /// 新しい駒を生成
  Piece createPiece(PieceType type, Player owner) {
    return Piece(type: type, owner: owner, id: _pieceIdCounter++);
  }

  /// 初期駒セットを生成
  void initializePieces() {
    for (final player in Player.values) {
      final pieces = <Piece>[];
      for (final type in PieceType.values) {
        // 特殊駒は上級ルールのみ
        if (type.isSpecial && !ruleLevel.useSpecialPieces) continue;

        for (int i = 0; i < type.count; i++) {
          pieces.add(createPiece(type, player));
        }
      }
      handPieces[player] = pieces;
    }
  }

  /// 入門・初級ルールの固定初期配置を設定
  void setupFixedPosition() {
    // 固定配置の定義（先手視点、後手は反転）
    // TODO: 公式ルールに基づく固定配置を実装
    _setupDefaultPosition(Player.white);
    _setupDefaultPosition(Player.black);
  }

  void _setupDefaultPosition(Player player) {
    final isWhite = player == Player.white;
    final baseRow = isWhite ? 0 : 8;

    // 帥を中央に配置
    final sui =
        handPieces[player]!.firstWhere((p) => p.type == PieceType.sui);
    handPieces[player]!.remove(sui);
    board.placePiece(Position(baseRow, 4), sui);

    // 大を帥の左に配置
    final dai =
        handPieces[player]!.firstWhere((p) => p.type == PieceType.dai);
    handPieces[player]!.remove(dai);
    board.placePiece(Position(baseRow, 3), dai);

    // 中を帥の右に配置
    final chu =
        handPieces[player]!.firstWhere((p) => p.type == PieceType.chu);
    handPieces[player]!.remove(chu);
    board.placePiece(Position(baseRow, 5), chu);

    // 2段目に兵を配置
    final secondRow = isWhite ? 1 : 7;
    final heiList =
        handPieces[player]!.where((p) => p.type == PieceType.hei).toList();
    for (int i = 0; i < heiList.length && i < 4; i++) {
      handPieces[player]!.remove(heiList[i]);
      board.placePiece(Position(secondRow, 2 + i * 2), heiList[i]);
    }
  }

  /// 指し手を適用
  GameState applyMove(Move move) {
    final newBoard = board.copy();
    final newHandPieces = {
      Player.white: List<Piece>.from(handPieces[Player.white]!),
      Player.black: List<Piece>.from(handPieces[Player.black]!),
    };
    final newHistory = List<Move>.from(moveHistory)..add(move);

    switch (move.type) {
      case MoveType.move:
        newBoard.movePiece(move.from!, move.to);
        break;

      case MoveType.capture:
        // 相手の駒を捕獲（ゲームから除外）
        newBoard.captureStack(move.to);
        newBoard.movePiece(move.from!, move.to);
        break;

      case MoveType.stack:
        // 自駒の上にツケ
        newBoard.movePiece(move.from!, move.to);
        break;

      case MoveType.attackStack:
        // 敵駒の上にツケ
        newBoard.movePiece(move.from!, move.to);
        // 謀の場合は寝返り処理
        if (move.piece.type == PieceType.bou) {
          _handleBouDefection(newBoard, move.to, move.player);
        }
        break;

      case MoveType.drop:
        // 手駒から配置
        newHandPieces[move.player]!.remove(move.piece);
        newBoard.placePiece(move.to, move.piece);
        break;
    }

    // 勝敗判定（対局フェーズのみ）
    Player? newWinner;
    GamePhase newPhase = phase;

    if (phase == GamePhase.playing) {
      final opponentSui = newBoard.findSui(move.player.opponent);
      if (opponentSui == null) {
        newWinner = move.player;
        newPhase = GamePhase.finished;
      }
    }

    // 次の手番を決定
    // 初期配置フェーズで相手が配置完了済みなら自分の番のまま
    Player nextPlayer;
    if (phase == GamePhase.setup && setupFinished[move.player.opponent] == true) {
      nextPlayer = move.player; // 自分の番のまま
    } else {
      nextPlayer = move.player.opponent; // 通常通り交代
    }

    return GameState(
      board: newBoard,
      handPieces: newHandPieces,
      currentPlayer: nextPlayer,
      phase: newPhase,
      ruleLevel: ruleLevel,
      moveHistory: newHistory,
      winner: newWinner,
      setupFinished: Map.from(setupFinished),
      isAiThinking: isAiThinking,
      pieceIdCounter: _pieceIdCounter,
    );
  }

  /// プレイヤーの配置完了を宣言
  GameState finishPlayerSetup(Player player) {
    final newSetupFinished = Map<Player, bool>.from(setupFinished);
    newSetupFinished[player] = true;

    // 両者が完了したら対局開始
    if (newSetupFinished[Player.white] == true &&
        newSetupFinished[Player.black] == true) {
      return GameState(
        board: board,
        handPieces: handPieces,
        currentPlayer: Player.white,
        phase: GamePhase.playing,
        ruleLevel: ruleLevel,
        moveHistory: moveHistory,
        winner: winner,
        setupFinished: newSetupFinished,
        isAiThinking: isAiThinking,
        pieceIdCounter: _pieceIdCounter,
      );
    }

    // 片方だけ完了の場合、相手の番に
    return GameState(
      board: board,
      handPieces: handPieces,
      currentPlayer: player.opponent,
      phase: phase,
      ruleLevel: ruleLevel,
      moveHistory: moveHistory,
      winner: winner,
      setupFinished: newSetupFinished,
      isAiThinking: isAiThinking,
      pieceIdCounter: _pieceIdCounter,
    );
  }

  /// 謀の寝返り処理
  void _handleBouDefection(Board board, Position pos, Player player) {
    final stack = board.getStack(pos);
    if (stack.height < 2) return;

    // 最上部（謀）の下にある敵駒を自軍に変える
    final pieces = stack.pieces;
    for (int i = 0; i < pieces.length - 1; i++) {
      final piece = pieces[i];
      if (piece.owner != player) {
        // 寝返り：所有者を変更（新しいPieceを作成）
        // 注：実際の実装ではスタック内のピースを置き換える必要がある
      }
    }
  }

  /// 対局フェーズに移行
  GameState startGame() {
    return GameState(
      board: board,
      handPieces: handPieces,
      currentPlayer: Player.white,
      phase: GamePhase.playing,
      ruleLevel: ruleLevel,
      moveHistory: moveHistory,
      winner: winner,
      isAiThinking: isAiThinking,
      pieceIdCounter: _pieceIdCounter,
    );
  }

  /// コピー
  GameState copyWith({
    Board? board,
    Map<Player, List<Piece>>? handPieces,
    Player? currentPlayer,
    GamePhase? phase,
    RuleLevel? ruleLevel,
    List<Move>? moveHistory,
    Player? winner,
    Map<Player, bool>? setupFinished,
    bool? isAiThinking,
  }) {
    return GameState(
      board: board ?? this.board.copy(),
      handPieces: handPieces ??
          {
            Player.white: List.from(this.handPieces[Player.white]!),
            Player.black: List.from(this.handPieces[Player.black]!),
          },
      currentPlayer: currentPlayer ?? this.currentPlayer,
      phase: phase ?? this.phase,
      ruleLevel: ruleLevel ?? this.ruleLevel,
      moveHistory: moveHistory ?? List.from(this.moveHistory),
      winner: winner,
      setupFinished: setupFinished ?? Map.from(this.setupFinished),
      isAiThinking: isAiThinking ?? this.isAiThinking,
      pieceIdCounter: _pieceIdCounter,
    );
  }
}
