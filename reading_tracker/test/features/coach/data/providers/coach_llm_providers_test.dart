import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:reading_tracker/features/coach/data/clients/open_ai_llm_client.dart';
import 'package:reading_tracker/features/coach/data/providers/coach_llm_providers.dart';
import 'package:reading_tracker/features/coach/domain/services/llm_client.dart';

void main() {
  group('coach LLM providers', () {
    test('llmClientProvider devuelve OpenAiLlmClient como LlmClient', () {
      final container = ProviderContainer();
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
  });
}
