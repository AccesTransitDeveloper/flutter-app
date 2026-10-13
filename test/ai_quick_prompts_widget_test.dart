import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer/features/ai/ai_quick_prompts.dart';

void main() {
  for (final width in [320.0, 393.0, 768.0]) {
    testWidgets('all six quick prompts fit at width $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      AiQuickPrompt? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AiQuickPromptGrid(onSelected: (p) => selected = p),
            ),
          ),
        ),
      ));
      for (final prompt in aiQuickPrompts) {
        expect(find.text(prompt.label), findsOneWidget);
        await tester.tap(find.text(prompt.label));
        expect(selected?.message, prompt.message);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('disabled prompts cannot send a request', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AiQuickPromptGrid(onSelected: null)),
    ));
    for (final ink in tester.widgetList<InkWell>(find.byType(InkWell))) {
      expect(ink.onTap, isNull);
    }
  });
}
