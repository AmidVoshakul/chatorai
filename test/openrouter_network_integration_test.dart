import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/services/network_service.dart';
import '../lib/services/openrouter_service.dart';

// Generate mocks
@GenerateMocks([NetworkService])
import 'openrouter_network_integration_test.mocks.dart';

void main() {
  group('OpenRouter Network Integration Tests', () {
    late MockNetworkService mockNetworkService;
    late OpenRouterService openRouterService;

    setUp(() {
      mockNetworkService = MockNetworkService();
      openRouterService = OpenRouterService();
    });

    group('Network Check Integration', () {
      test('OpenRouter methods should check network before making requests', () async {
        // Test that network check is called before API requests
        when(mockNetworkService.isConnected).thenReturn(false);

        // These should throw exceptions when network is not available
        expect(
          () => openRouterService.getAvailableModels(),
          throwsA(isA<Exception>()),
        );

        expect(
          () => openRouterService.uploadFile(filePath: '/test/path'),
          throwsA(isA<Exception>()),
        );

        expect(
          () async => await openRouterService.isHealthy(),
          returnsNormally,
        );
      });

      test('OpenRouter should proceed when network is available', () async {
        when(mockNetworkService.isConnected).thenReturn(true);

        // These should not throw network-related exceptions
        // Note: They might throw other exceptions due to missing API keys, etc.
        try {
          await openRouterService.isHealthy();
        } catch (e) {
          expect(e, isNot(isA<Exception>()));
        }
      });
    });

    group('Error Handling', () {
      test('Network exceptions are properly propagated', () async {
        when(mockNetworkService.isConnected).thenReturn(false);

        try {
          await openRouterService.getAvailableModels();
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e.toString(), contains('No internet connection'));
        }
      });

      test('File upload respects network status', () async {
        when(mockNetworkService.isConnected).thenReturn(false);

        try {
          await openRouterService.uploadFile(filePath: '/test/file.jpg');
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e.toString(), contains('No internet connection'));
        }
      });
    });

    group('Stream Chat Completion', () {
      test('Stream chat completion checks network first', () async {
        when(mockNetworkService.isConnected).thenReturn(false);

        try {
          await openRouterService.streamChatCompletion(
            messages: [{'role': 'user', 'content': 'test'}],
            model: 'test-model',
            onChunk: (chunk) {},
            onCompletion: (completion) {},
          );
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e.toString(), contains('No internet connection'));
        }
      });
    });

    group('Health Check Integration', () {
      test('Health check returns false when network is unavailable', () async {
        when(mockNetworkService.isConnected).thenReturn(false);

        final result = await openRouterService.isHealthy();
        expect(result, false);
      });
    });

    group('Test Methods Integration', () {
      test('Test methods respect network status', () async {
        when(mockNetworkService.isConnected).thenReturn(false);

        try {
          await openRouterService.testProviderStructure();
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e.toString(), contains('No internet connection'));
        }
      });
    });
  });
}
