import '../utils/constants.dart';

/// 駒クラス
class Piece {
  final PieceType type;
  final Player owner;
  final int id; // 一意識別子

  const Piece({
    required this.type,
    required this.owner,
    required this.id,
  });

  /// 漢字表記
  String get kanji => type.kanji;

  /// コピー
  Piece copyWith({
    PieceType? type,
    Player? owner,
  }) {
    return Piece(
      type: type ?? this.type,
      owner: owner ?? this.owner,
      id: id,
    );
  }

  @override
  bool operator ==(Object other) => other is Piece && id == other.id;

  @override
  int get hashCode => id;

  @override
  String toString() => '${owner.name}:${type.kanji}#$id';
}

/// 駒スタック（同一マス上の駒の積み重ね）
class PieceStack {
  final List<Piece> _pieces;

  PieceStack() : _pieces = [];
  PieceStack.from(List<Piece> pieces) : _pieces = List.from(pieces);

  /// スタックの高さ
  int get height => _pieces.length;

  /// 空かどうか
  bool get isEmpty => _pieces.isEmpty;

  /// 駒があるか
  bool get isNotEmpty => _pieces.isNotEmpty;

  /// 最上部の駒
  Piece? get top => _pieces.isNotEmpty ? _pieces.last : null;

  /// 最上部の駒の所有者
  Player? get controller => top?.owner;

  /// 全ての駒
  List<Piece> get pieces => List.unmodifiable(_pieces);

  /// 指定インデックスの駒
  Piece? pieceAt(int index) =>
      index >= 0 && index < _pieces.length ? _pieces[index] : null;

  /// 駒を追加（ツケ）
  void push(Piece piece) {
    _pieces.add(piece);
  }

  /// 最上部の駒を取り除く
  Piece? pop() {
    if (_pieces.isEmpty) return null;
    return _pieces.removeLast();
  }

  /// 全ての駒を取り除く（捕獲時）
  List<Piece> clear() {
    final removed = List<Piece>.from(_pieces);
    _pieces.clear();
    return removed;
  }

  /// コピー
  PieceStack copy() => PieceStack.from(_pieces);

  @override
  String toString() => _pieces.map((p) => p.kanji).join('|');
}
