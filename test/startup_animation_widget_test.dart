import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer/views/screens/splash/startup_animation.dart';

Future<void> loadIntro(WidgetTester tester, VoidCallback completed) async {
  await tester.pumpWidget(MaterialApp(
    home: StartupAnimation(
      onCompleted: completed,
      onError: () => fail('Bundled animation failed to decode'),
    ),
  ));
  final context = tester.element(find.byType(StartupAnimation));
  await tester.runAsync(() => precacheImage(
    const AssetImage(StartupAnimation.asset), context,
  ));
  await tester.pump();
}

void main() {
  testWidgets('intro finishes once, after six visible seconds', (tester) async {
    var completions = 0;
    await loadIntro(tester, () => completions++);
    await tester.pump(const Duration(seconds: 5));
    expect(completions, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(completions, 1);
  });

  testWidgets('background time does not consume the intro', (tester) async {
    var completions = 0;
    await loadIntro(tester, () => completions++);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(completions, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 4));
    expect(completions, 1);
  });
}
