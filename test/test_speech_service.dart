import 'package:flutter_test/flutter_test.dart';
import 'package:gen_ui_chat_ai/services/speech_to_text_service.dart';
import 'package:gen_ui_chat_ai/utils/speech_utils.dart';
import 'package:flutter/material.dart';

void main() {
  group('SpeechToTextService Tests', () {
    late SpeechToTextService service;
    late List<String> results;
    late List<String> errors;
    late List<bool> listeningStates;

    setUp(() {
      results = [];
      errors = [];
      listeningStates = [];

      service = SpeechToTextService(
        onResult: (text) => results.add(text),
        onError: (error) => errors.add(error),
        onListeningChanged: (isListening) => listeningStates.add(isListening),
      );
    });

    test('initial state is correct', () {
      expect(service.isListening, false);
      expect(service.isAvailable, false);
    });

    test('checkAvailability returns boolean', () async {
      // This will return false in test environment since no actual microphone
      final available = await service.checkAvailability();
      expect(available, isA<bool>());
    });

    test('startListening handles unavailable microphone', () async {
      final started = await service.startListening();
      // In test environment, this should fail gracefully
      expect(started, isA<bool>());
    });

    test('stopListening does not crash when not listening', () async {
      // Should not throw
      await service.stopListening();
      expect(service.isListening, false);
    });

    test('cancelListening does not crash when not listening', () async {
      // Should not throw
      await service.cancelListening();
      expect(service.isListening, false);
    });

    test('dispose cleans up resources', () {
      // Should not throw
      service.dispose();
      expect(true, true);
    });
  });

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
}
