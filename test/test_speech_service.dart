import 'package:flutter_test/flutter_test.dart';
import 'package:gen_ui_chat_ai/services/speech_to_text_service.dart';
import 'package:gen_ui_chat_ai/utils/speech_utils.dart';
import 'package:flutter/material.dart';

void main() {
  group('SpeechUtils Tests', () {
    test('getIcon returns correct icon for states', () {
      final icon1 = SpeechUtils.getIcon(true, true); // listening, available
      final icon2 = SpeechUtils.getIcon(false, true); // not listening, available
      final icon3 = SpeechUtils.getIcon(false, false); // not listening, unavailable

      expect(icon1, Icons.stop);
      expect(icon2, Icons.mic);
      expect(icon3, Icons.mic_off);
    });

    test('getColor returns correct color for states', () {
      final theme = ThemeData.light();
      
      final color1 = SpeechUtils.getColor(theme, true, true); // listening, available
      final color2 = SpeechUtils.getColor(theme, false, true); // not listening, available
      final color3 = SpeechUtils.getColor(theme, false, false); // not listening, unavailable

      expect(color1, Colors.red);
      expect(color2, isA<Color>());
      expect(color3, Colors.grey);
    });

    test('formatListeningTime formats duration correctly', () {
      final duration1 = Duration(seconds: 5);
      final duration2 = Duration(seconds: 65);
      final duration3 = Duration(minutes: 2, seconds: 5);

      expect(SpeechUtils.formatListeningTime(duration1), '5s');
      expect(SpeechUtils.formatListeningTime(duration2), '1m 5s');
      expect(SpeechUtils.formatListeningTime(duration3), '2m 5s');
    });
  });

  group('SpeechToTextService - Google-style UX', () {
    testWidgets('service initializes with correct callbacks', (tester) async {
      late SpeechToTextService service;
      final results = <String>[];
      final messages = <String>[];
      final states = <SpeechUiState>[];
      final partialResults = <String>[];
      bool autoRestartCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                service = SpeechToTextService(
                  context: context,
                  onResult: (text) => results.add(text),
                  onStatusMessage: (message) => messages.add(message),
                  onStateChanged: (state) => states.add(state),
                  onPartialResult: (text) => partialResults.add(text),
                  onAutoRestart: () {
                    autoRestartCalled = true;
                  },
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(service.isListening, false);
      expect(service.isAvailable, false);
    });

    testWidgets('service handles operations without crashing', (tester) async {
      late SpeechToTextService service;
      final results = <String>[];
      final messages = <String>[];
      final states = <SpeechUiState>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                service = SpeechToTextService(
                  context: context,
                  onResult: (text) => results.add(text),
                  onStatusMessage: (message) => messages.add(message),
                  onStateChanged: (state) => states.add(state),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // These should not crash
      await service.checkAvailability();
      await service.startListening();
      await service.stopListening();
      await service.cancelListening();
      service.dispose();

      expect(true, true); // If we got here, no crashes occurred
    });
  });
}
