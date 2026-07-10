import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../domain/services/llm_client.dart';
import '../clients/gemini_llm_client.dart';
import '../clients/open_ai_llm_client.dart';

class LlmProviderConfigurationException implements Exception {
  const LlmProviderConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'LlmProviderConfigurationException: $message';
}

final llmProviderNameProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'LLM_PROVIDER',
    defaultValue: 'openai',
  ).trim().toLowerCase();
});

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

final geminiConfigProvider = Provider<GeminiConfig>((ref) {
  const apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'missing-gemini-api-key',
  );
  const model = String.fromEnvironment('GEMINI_MODEL', defaultValue: '');
  const baseUrl = String.fromEnvironment(
    'GEMINI_BASE_URL',
    defaultValue: 'https://generativelanguage.googleapis.com/v1beta',
  );
  return GeminiConfig(
    apiKey: apiKey,
    model: model,
    baseUri: Uri.parse(baseUrl),
  );
});

final geminiHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final llmClientProvider = Provider<LlmClient>((ref) {
  final provider = ref.watch(llmProviderNameProvider);
  if (kDebugMode) {
    if (provider == 'gemini') {
      final config = ref.watch(geminiConfigProvider);
      debugPrint(
        '[Coach/LLM] provider=gemini baseUrl=${config.baseUri} '
        'model=${config.model}',
      );
    } else if (provider == 'openai') {
      final config = ref.watch(openAiConfigProvider);
      debugPrint(
        '[Coach/LLM] provider=openai baseUrl=${config.baseUri} '
        'model=${config.model}',
      );
    } else {
      debugPrint('[Coach/LLM] provider=$provider configuration=invalid');
    }
  }
  return switch (provider) {
    'openai' => OpenAiLlmClient(
      config: ref.watch(openAiConfigProvider),
      httpClient: ref.watch(openAiHttpClientProvider),
    ),
    'gemini' => GeminiLlmClient(
      config: ref.watch(geminiConfigProvider),
      httpClient: ref.watch(geminiHttpClientProvider),
    ),
    _ => throw LlmProviderConfigurationException(
      'Unknown LLM_PROVIDER "$provider". Expected "openai" or "gemini".',
    ),
  };
});
