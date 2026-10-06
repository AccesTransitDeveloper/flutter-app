import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:customer/core/preferences/shared_preference_manager.dart';
import 'package:customer/core/providers/app_providers.dart';
import 'package:customer/core/theme/app_theme.dart';
import 'package:customer/models/responses/auth/entity_detail_response.dart';
import 'package:customer/features/support/support_api.dart';
import 'package:customer/features/support/support_controller.dart';
import 'package:customer/features/support/support_models.dart';
import 'package:customer/views/screens/support/support_chat_screen.dart';

class WidgetSupportApi extends SupportApi {
  WidgetSupportApi(super.preferences);
  final fixture = SupportChat.fromJson({
    'id': 'chat-widget', 'ticketNumber': 'SUP-TEST', 'subject': 'Dispatch assistance', 'status': 'in_progress',
    'updatedAt': '2026-10-06T12:00:00Z', 'lastMessage': 'We are checking your pickup.',
    'messages': [
      {'id': 'msg-customer', 'sequence': 1, 'senderName': 'Test Customer', 'senderRole': 'user', 'content': 'I need help with my pickup location.', 'timestamp': '2026-10-06T12:00:00Z'},
      {'id': 'msg-support', 'sequence': 2, 'senderName': 'AT Support', 'senderRole': 'support_agent', 'content': 'We are checking your pickup. Please share your current location so dispatch can help.', 'timestamp': '2026-10-06T12:01:00Z'},
    ],
  });
  @override
  Future<List<SupportChat>> list() async => [fixture];
  @override
  Future<SupportChat> get(String id, {int? before}) async => fixture;
  @override
  Future<void> markRead(String id, int throughSequence) async {}
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Widget tests use Ahem by default. Load the SDK's real fonts for readable
    // screenshots without adding test font assets to the release APK.
    var directory = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 8; i++) {
      final fonts = Directory('${directory.path}/material_fonts');
      if (fonts.existsSync()) {
        for (final entry in {'Roboto': 'Roboto-Regular.ttf', 'MaterialIcons': 'MaterialIcons-Regular.otf'}.entries) {
          final file = File('${fonts.path}/${entry.value}');
          if (file.existsSync()) {
            final loader = FontLoader(entry.key)..addFont(file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
            await loader.load();
          }
        }
        break;
      }
      directory = directory.parent;
    }
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('support list/thread/composer fit a $width px phone with keyboard', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 780);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final preferences = SharedPreferenceManager(await SharedPreferences.getInstance());
      await preferences.setEntity(Entity(id: 'widget-test-customer', type: 2));
      await preferences.setAuthorization('synthetic-widget-auth');
      late SupportController controller;
      final boundary = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: [sharedPreferenceManagerProvider.overrideWith((ref) async => preferences)],
        child: RepaintBoundary(key: boundary, child: MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.defaultLightTheme,
          home: SupportChatScreen(controllerFactory: (p) => controller = SupportController(p, supportApi: WidgetSupportApi(p)))),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('AT Support Chat'), findsOneWidget);
      await tester.tap(find.text('Dispatch assistance').first);
      await tester.pumpAndSettle();
      expect(find.text('I need help with my pickup location.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        const captureDir = String.fromEnvironment('SUPPORT_CAPTURE_DIR', defaultValue: '/tmp');
        final file = File('$captureDir/at-support-passenger-chat-${width.toInt()}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      controller.location = const SupportLocation(latitude: 40.7, longitude: -74, accuracyMeters: 5, capturedAt: '2026-10-06T12:00:00Z');
      controller.files.add(SupportDraftFile('/tmp/synthetic-nonexistent-file.pdf', 'very-long-customer-support-document-name.pdf', supportUuid()));
      tester.view.viewInsets = const FakeViewPadding(bottom: 290);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
