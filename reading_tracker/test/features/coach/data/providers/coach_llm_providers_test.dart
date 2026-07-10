import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:reading_tracker/features/coach/data/clients/gemini_llm_client.dart';
import 'package:reading_tracker/features/coach/data/clients/open_ai_llm_client.dart';
import 'package:reading_tracker/features/coach/data/providers/coach_llm_providers.dart';
import 'package:reading_tracker/features/coach/domain/services/llm_client.dart';

void main() {
  group('coach LLM providers', () {
    test('llmClientProvider devuelve OpenAiLlmClient como LlmClient', () {
      final container = ProviderContainer(
        overrides: [llmProviderNameProvider.overrideWithValue('openai')],
      );
      addTearDown(container.dispose);

      final client = container.read(llmClientProvider);

      expect(client, isA<LlmClient>());
      expect(client, isA<OpenAiLlmClient>());
    });

    test('openAiConfigProvider usa valores por defecto cuando no hay env', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(openAiConfigProvider);

      expect(config.apiKey, 'missing-openai-api-key');
      expect(config.model, 'gpt-4o-mini');
      expect(config.baseUri, Uri.parse('https://api.openai.com/v1/responses'));
    });

    test('openAiHttpClientProvider se puede crear sin error', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(openAiHttpClientProvider);

      expect(client, isA<http.Client>());
    });

    test('selecciona GeminiLlmClient cuando LLM_PROVIDER es gemini', () {
      final container = ProviderContainer(
        overrides: [
          llmProviderNameProvider.overrideWithValue('gemini'),
          geminiConfigProvider.overrideWithValue(
            GeminiConfig(apiKey: 'test-key', model: 'gemini-test'),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(llmClientProvider), isA<GeminiLlmClient>());
    });

    test('mantiene OpenAiLlmClient cuando LLM_PROVIDER es openai', () {
      final container = ProviderContainer(
        overrides: [llmProviderNameProvider.overrideWithValue('openai')],
      );
      addTearDown(container.dispose);

      expect(container.read(llmClientProvider), isA<OpenAiLlmClient>());
    });

    test('rechaza provider desconocido con error de configuracion', () {
      final container = ProviderContainer(
        overrides: [llmProviderNameProvider.overrideWithValue('otro')],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(llmClientProvider),
        throwsA(isA<LlmProviderConfigurationException>()),
      );
    });

    test('Gemini seleccionado falla si falta su configuracion', () {
      final container = ProviderContainer(
        overrides: [
          llmProviderNameProvider.overrideWithValue('gemini'),
          geminiConfigProvider.overrideWith(
            (ref) => throw const GeminiConfigurationException(
              'GEMINI_API_KEY is missing',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(llmClientProvider),
        throwsA(isA<GeminiConfigurationException>()),
      );
    });
  });
}
