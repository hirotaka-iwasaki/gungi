# 軍儀 (Gungi) - Flutter実装ガイド

## プロジェクト概要

HUNTER×HUNTERに登場する架空のボードゲーム「軍儀」のFlutterアプリ実装。
UMS（Universal Makyo System）ルールに準拠したローカル対戦・CPU対戦を実現する。

## 技術スタック

- **フレームワーク**: Flutter (Dart)
- **対応プラットフォーム**: Web, iOS, Android
- **状態管理**: Riverpod（推奨）
- **アーキテクチャ**: MVC/MVVM パターン（UIとゲームロジックを分離）

## 開発時の注意事項

### Flutter Web でのコード変更反映

**重要**: Flutter Webでは、ブラウザのリロードだけではDartソースコードの変更が反映されない。

#### 理由
- `flutter run -d chrome` はDartコードをJavaScriptにコンパイルしてサーバーに保持
- ブラウザリロードは既存のビルド済みJSを再読み込みするだけ
- ソースコード変更を反映するには再コンパイルが必要

#### 変更を反映する方法
1. **サーバー再起動**（確実）: `flutter run`を終了して再実行
2. **Hot Restart**: `flutter run`のコンソールで大文字`R`を押す
3. **Hot Reload**: `flutter run`のコンソールで小文字`r`を押す（UIの変更のみ）

#### 開発コマンド
```bash
# 開発サーバー起動（Chrome）
fvm flutter run -d chrome --web-port=8080

# ヘッドレスサーバー起動（ブラウザ手動）
fvm flutter run -d web-server --web-port=8080
```

#### Claude Code での運用
コード変更後は必ず `flutter run` サーバーを再起動してから動作確認を行うこと。

## ゲームルール要約

### 基本
- 9×9マスの盤面、二人対戦
- 各プレイヤー25枚の駒（14種類）
- 勝利条件: 相手の「帥（すい）」を捕獲

### 駒の種類（各プレイヤー25枚）
| 駒名 | 枚数 | 備考 |
|------|------|------|
| 帥 | 1 | 王将相当、これを取られたら負け |
| 大 | 1 | |
| 中 | 1 | |
| 小 | 2 | |
| 侍 | 2 | |
| 忍 | 2 | |
| 兵 | 4 | |
| 槍 | 3 | |
| 馬 | 2 | |
| 砦 | 2 | |
| 弓 | 2 | 特殊駒（飛び駒） |
| 砲 | 1 | 特殊駒（3マス直進） |
| 筒 | 1 | 特殊駒 |
| 謀 | 1 | 特殊駒（寝返り能力） |

### 特徴的なルール
1. **初期配置が自由**: 自陣3段目まで交互に1枚ずつ配置
2. **駒の再利用不可**: 取った駒は持ち駒にならない（謀の寝返り除く）
3. **ツケ（スタック）**: 駒を重ねられる（最大3段、ルールにより2段）
4. **新（あらた）**: 手駒から盤上に駒を投入
5. **高さ優位**: 高い段の駒は低い段からの攻撃を受けない

### ルールレベル
- 入門編: 固定配置、特殊駒なし、最大2段
- 初級編: 固定配置、特殊駒なし、最大2段
- 中級編: 自由配置、特殊駒なし、最大2段
- 上級編: 自由配置、全駒使用、最大3段

## ディレクトリ構成（推奨）

```
lib/
├── main.dart
├── models/                # データモデル
│   ├── piece.dart         # 駒クラス（種類、所属、座標）
│   ├── board.dart         # 盤面クラス（9x9グリッド、スタック管理）
│   ├── game_state.dart    # ゲーム状態（盤面、手駒、手番、勝敗）
│   ├── move.dart          # 指し手データ
│   ├── player.dart        # プレイヤー情報
│   └── rule_config.dart   # ルール設定（難易度別）
├── logic/                 # ゲームロジック
│   ├── move_validator.dart    # 合法手判定
│   ├── piece_movement.dart    # 駒ごとの移動ルール定義
│   ├── stack_rules.dart       # ツケ・捕獲ルール
│   └── game_controller.dart   # ゲーム進行制御
├── ai/                    # CPU対戦AI
│   ├── ai_player.dart         # AIインターフェース
│   ├── random_ai.dart         # 初級AI（ランダム）
│   ├── minimax_ai.dart        # 中級AI（ミニマックス）
│   ├── advanced_ai.dart       # 上級AI（深い探索）
│   └── evaluation.dart        # 局面評価関数
├── widgets/               # UIコンポーネント
│   ├── board_widget.dart      # 盤面描画
│   ├── piece_widget.dart      # 駒描画
│   ├── hand_area_widget.dart  # 手駒表示
│   ├── info_panel_widget.dart # 情報パネル
│   └── stack_viewer.dart      # スタック詳細表示
├── screens/               # 画面
│   ├── title_screen.dart      # タイトル画面
│   ├── game_screen.dart       # 対局画面
│   ├── setup_screen.dart      # 初期配置画面
│   └── settings_screen.dart   # 設定画面
├── providers/             # 状態管理
│   └── game_provider.dart
├── theme/                 # テーマ・スタイル
│   ├── app_theme.dart
│   └── piece_assets.dart      # 駒画像リソース
└── utils/
    ├── constants.dart         # 定数定義
    └── notation.dart          # 棋譜表記
```

## 実装の優先順位

### Phase 1: コアロジック
1. `Piece`クラス - 駒の種類・所属・座標
2. `Board`クラス - 9x9グリッドとスタック管理
3. `GameState`クラス - ゲーム全体の状態管理
4. 各駒の移動ルール実装（`piece_movement.dart`）
5. ツケ・捕獲の判定ロジック

### Phase 2: 基本UI
1. 盤面表示（`BoardWidget`）
2. 駒表示（`PieceWidget`）
3. タップ/ドラッグ操作
4. 合法手ハイライト

### Phase 3: ゲームフロー
1. 初期配置フェーズ
2. 対局フェーズ
3. 勝敗判定・終局処理

### Phase 4: AI実装
1. ランダムAI（Easy）
2. ミニマックスAI（Medium）
3. 評価関数の調整

### Phase 5: UI/UX強化
1. 原作風デザイン（木目調盤面、和風配色）
2. 効果音・アニメーション
3. 棋譜表示

## コーディング規約

### 命名規則
- クラス名: PascalCase（例: `GameState`, `PieceWidget`）
- 変数・関数: camelCase（例: `getLegalMoves`, `currentPlayer`）
- 定数: SCREAMING_SNAKE_CASE または lowerCamelCase
- ファイル名: snake_case（例: `game_state.dart`）

### 駒タイプのenum定義
```dart
enum PieceType {
  sui,    // 帥
  dai,    // 大
  chu,    // 中
  sho,    // 小
  samurai,// 侍
  shinobi,// 忍
  hei,    // 兵
  yari,   // 槍
  uma,    // 馬
  toride, // 砦
  yumi,   // 弓
  hou,    // 砲
  tsutsu, // 筒
  bou,    // 謀
}
```

### プレイヤー識別
```dart
enum Player { white, black }  // white=先手, black=後手
```

### 座標系
- 内部: 0-indexed（0〜8）
- 表示: 1-indexed（1〜9）

## 重要な実装ポイント

### スタック（ツケ）の表現
各マスは`List<Piece>`として管理。インデックス0が最下層。
```dart
class Cell {
  List<Piece> stack = [];
  int get height => stack.length;
  Piece? get topPiece => stack.isNotEmpty ? stack.last : null;
}
```

### 移動範囲の拡張
駒が2段・3段になると移動距離が+1ずつ延長される。
```dart
int getMoveDistance(int baseDistance, int stackHeight) {
  return baseDistance + (stackHeight - 1);
}
```

### 高さ制限
自分と同じ段数以下の駒にしか「捕る」「ツケる」ができない。

### 謀（ぼう）の寝返り
敵駒にツケることで、下の敵駒を自軍に変える唯一の特殊能力。

## テスト方針

- 各駒の移動ロジックの単体テスト
- ツケ・捕獲ルールのテスト
- 勝敗判定のテスト
- AIの合法手生成テスト

## 参考リソース

- design.md: 詳細設計書
- UMS公式ルール
- 公式商品版の駒デザイン
