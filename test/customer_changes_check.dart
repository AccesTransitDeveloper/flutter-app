import 'dart:io';
import '../lib/features/booking/cancellation_reasons.dart';

String source(String path) =>
    File.fromUri(Platform.script.resolve('../$path')).readAsStringSync();
void check(bool value, String message) {
  if (!value) throw StateError(message);
}

void main() {
  final ai = source('lib/views/screens/ai/ai_assistant_screen.dart');
  check(!ai.contains('Suggestions') && !ai.contains('AiQuickPrompt') &&
      !ai.contains('Plan a ride'), 'No quick questions or replacement toggle.');
  check(ai.contains('_composerLift = 27') &&
      ai.contains('viewModel.setLanguage(value)'), 'Composer lift and real language selection.');
  final repository = source('lib/data/ai/ai_repository.dart');
  check(RegExp("'language': language").allMatches(repository).length == 3,
      'Language must reach chat, transcription and speech endpoints.');
  check(repository.contains("json['language'] != language"),
      'Old servers must not silently ignore language selection.');
  final model = source('lib/features/ai/ai_viewmodel.dart');
  check(model.contains('_generation++; // Discard old replies') &&
      model.contains('unawaited(stopPlayback())'), 'Changing language invalidates old audio and replies.');
  final sheet = source('lib/views/bottomsheets/cancel_trip_bottom_sheet.dart');
  check(sheet.contains('bool get _canSubmit => !widget.isCancelTripLoading') &&
      sheet.contains("if (_selectedIndex < 0) return ''") &&
      sheet.contains('ChoiceChip('), 'Cancellation remains optional and offers Other.');
  for (final language in ['en', 'ru', 'es', 'ar', 'zh', 'hi', 'tr', 'ja']) {
    check(commonCancellationReasons(language).length == 6 &&
        commonCancellationReasons(language).last == 'Other' &&
        commonCancellationReasons(language).contains('It was a long wait.'),
        'Five quick reasons plus optional Other for $language.');
  }
  final main = source('lib/main.dart');
  check(RegExp('debugShowCheckedModeBanner: false').allMatches(main).length == 3,
      'No Debug banner in ready, loading or failure paths.');
  final manager = source('lib/core/map/managers/mapbox_map_manager.dart');
  final glyph = source('lib/core/map/widgets/route_point_glyph.dart');
  check(manager.contains('RoutePointGlyph.toPng') &&
      glyph.contains('PathFillType.evenOdd') &&
      glyph.contains('pickupColor = Color(0xFF00008B)') &&
      glyph.contains('dropoffColor = Color(0xFFFF0000)') &&
      glyph.contains('routeColor = Color(0xFF006400)') &&
      source('lib/core/map/models/map_types.dart').contains('this.color = 0xFF006400') &&
      manager.contains('existing.lineColor = routeColor') &&
      manager.contains(r'route-point-${fill.toARGB32()}'),
      'Mapbox must use dark blue pickup and #FF0000 drop-off pins, separate icon caches and a dark green route.');
  print('Customer AI, language wiring, optional cancellation and marker source checks passed.');
}
