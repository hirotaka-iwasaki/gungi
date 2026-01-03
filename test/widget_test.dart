// 軍儀アプリの基本ウィジェットテスト
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gungi/main.dart';

void main() {
  testWidgets('アプリが起動してタイトル画面が表示される', (WidgetTester tester) async {
    // アプリを構築
    await tester.pumpWidget(const ProviderScope(child: GungiApp()));

    // タイトルが表示されていることを確認
    expect(find.text('軍儀'), findsOneWidget);
    expect(find.text('G U N G I'), findsOneWidget);

    // メニューボタンが表示されていることを確認
    expect(find.text('2人対戦'), findsOneWidget);
    expect(find.text('CPU対戦'), findsOneWidget);
    expect(find.text('遊び方'), findsOneWidget);
  });
}
