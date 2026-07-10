import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../domain/services/llm_client.dart';
import '../clients/open_ai_llm_client.dart';

final openAiConfigProvider = Provider<OpenAiConfig>((ref) {
  const apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: 'missing-openai-api-key',
  );
  const model = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );
  const baseUrl = String.fromEnvironment(
    'OPENAI_BASE_URL',
    defaultValue: 'https://api.openai.com/v1/responses',
  );

  return OpenAiConfig(
    apiKey: apiKey,
    model: model,
    baseUri: Uri.parse(baseUrl),
  );
});

final openAiHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final llmClientProvider = Provider<LlmClient>((ref) {
  return OpenAiLlmClient(
    config: ref.watch(openAiConfigProvider),
    httpClient: ref.watch(openAiHttpClientProvider),
  );
});
