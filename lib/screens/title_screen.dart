import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_player.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

/// タイトル画面（和風デザイン）
class TitleScreen extends ConsumerWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // 漆黒の和風グラデーション
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              const Color(0xFF1F1814),
              AppTheme.panelColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 装飾的な上部ライン
                Container(
                  width: 120,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.accentColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // タイトル（墨書風）
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFE4B5), // 明るい象牙色
                      Color(0xFFFFD700), // 金色
                      Color(0xFFB8860B), // 暗めの金色
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    '軍儀',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(3, 3),
                          blurRadius: 6,
                          color: Colors.black87,
                        ),
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'G U N G I',
                  style: TextStyle(
                    fontSize: 22,
                    letterSpacing: 12,
                    color: AppTheme.accentColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 12),
                // 装飾的な下部ライン
                Container(
                  width: 120,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.accentColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // メニューボタン
                _MenuButton(
                  label: '2人対戦',
                  sublabel: '同じ端末で対戦',
                  icon: Icons.people,
                  onPressed: () => _showRuleLevelDialog(
                    context,
                    ref,
                    aiDifficulty: null,
                  ),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: 'CPU対戦',
                  sublabel: 'コンピュータと対戦',
                  icon: Icons.smart_toy,
                  onPressed: () => _showCpuDifficultyDialog(context, ref),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: '遊び方',
                  sublabel: 'ルール説明',
                  icon: Icons.help_outline,
                  onPressed: () => _showHowToPlayDialog(context),
                ),

                const Spacer(),

                // フッター
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'HUNTER×HUNTER 軍儀',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// CPU難易度選択ダイアログ
  void _showCpuDifficultyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CPU難易度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogButton(
              label: '初級',
              description: 'ランダムに指す',
              onPressed: () {
                Navigator.pop(context);
                _showRuleLevelDialog(
                  context,
                  ref,
                  aiDifficulty: AiDifficulty.easy,
                );
              },
            ),
            const SizedBox(height: 8),
            _DialogButton(
              label: '中級',
              description: '基本的な戦略を使う',
              onPressed: () {
                Navigator.pop(context);
                _showRuleLevelDialog(
                  context,
                  ref,
                  aiDifficulty: AiDifficulty.medium,
                );
              },
            ),
            const SizedBox(height: 8),
            _DialogButton(
              label: '上級',
              description: '深く読んで指す',
              onPressed: () {
                Navigator.pop(context);
                _showRuleLevelDialog(
                  context,
                  ref,
                  aiDifficulty: AiDifficulty.hard,
                );
              },
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

  /// ルールレベル選択ダイアログ
  void _showRuleLevelDialog(
    BuildContext context,
    WidgetRef ref, {
    required AiDifficulty? aiDifficulty,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルールレベル'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogButton(
              label: '入門編',
              description: '固定配置・特殊駒なし・最大2段',
              onPressed: () {
                Navigator.pop(context);
                _startGame(context, ref, RuleLevel.beginner, aiDifficulty);
              },
            ),
            const SizedBox(height: 8),
            _DialogButton(
              label: '初級編',
              description: '固定配置・特殊駒なし・最大2段',
              onPressed: () {
                Navigator.pop(context);
                _startGame(context, ref, RuleLevel.elementary, aiDifficulty);
              },
            ),
            const SizedBox(height: 8),
            _DialogButton(
              label: '中級編',
              description: '自由配置・特殊駒なし・最大2段',
              onPressed: () {
                Navigator.pop(context);
                _startGame(context, ref, RuleLevel.intermediate, aiDifficulty);
              },
            ),
            const SizedBox(height: 8),
            _DialogButton(
              label: '上級編',
              description: '自由配置・全駒使用・最大3段',
              onPressed: () {
                Navigator.pop(context);
                _startGame(context, ref, RuleLevel.advanced, aiDifficulty);
              },
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

  /// ゲーム開始
  void _startGame(
    BuildContext context,
    WidgetRef ref,
    RuleLevel level,
    AiDifficulty? aiDifficulty,
  ) {
    ref.read(gameProvider.notifier).initializeGame(
          level: level,
          aiDifficulty: aiDifficulty,
        );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  /// 遊び方ダイアログ
  void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('軍儀の遊び方'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _RuleSection(
                title: '基本ルール',
                content: '・9×9マスの盤面で対戦\n'
                    '・相手の「帥」を取ったら勝ち\n'
                    '・各プレイヤー25枚の駒を使用',
              ),
              SizedBox(height: 16),
              _RuleSection(
                title: 'ツケ（スタック）',
                content: '・駒を重ねて置ける（最大2〜3段）\n'
                    '・高い駒は低い駒から攻撃されない\n'
                    '・高さに応じて移動距離が伸びる',
              ),
              SizedBox(height: 16),
              _RuleSection(
                title: '新（あらた）',
                content: '・手駒から盤上に駒を配置\n'
                    '・自分の最前線より前には置けない',
              ),
              SizedBox(height: 16),
              _RuleSection(
                title: '特殊駒（上級編）',
                content: '・弓：障害物を飛び越える\n'
                    '・砲：3マス直進\n'
                    '・謀：敵駒にツケて寝返らせる',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

/// メニューボタン（和風デザイン）
class _MenuButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3D2B1F), // 暗めの木目
              Color(0xFF2D1F14), // 深い木目
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            splashColor: AppTheme.accentColor.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFE4B5), // 象牙色
                        ),
                      ),
                      Text(
                        sublabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ダイアログ内ボタン
class _DialogButton extends StatelessWidget {
  final String label;
  final String description;
  final VoidCallback onPressed;

  const _DialogButton({
    required this.label,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ルール説明セクション
class _RuleSection extends StatelessWidget {
  final String title;
  final String content;

  const _RuleSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(content),
      ],
    );
  }
}
