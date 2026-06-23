import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import 'assistant_repository.dart';

/// Real AI coach backed by Groq (free tier, OpenAI-compatible). Personalises
/// every reply with the user's profile + current plan via the system prompt.
///
/// Falls back to [MockAssistantRepository] on any network/parse error or a
/// missing key, so the chat never hard-fails in a demo.
class GroqAssistantRepository implements AssistantRepository {
  GroqAssistantRepository(this.apiKey, {this.model = 'llama-3.3-70b-versatile'});

  final String apiKey;
  final String model;

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  final _fallback = MockAssistantRepository();

  static const _systemBase =
      'You are the in-app fitness coach for "Fitify". Talk like a real, warm '
      'human trainer: concise, encouraging, and plain-spoken. Keep most replies '
      'to 2 to 4 short sentences. When you give multiple tips, steps, or options, '
      'format them as short bullet points that each start with "- " instead of '
      'one long run-on paragraph. Do NOT use em dashes (the "—" character); use a '
      'comma, a period, or a new sentence instead. No markdown headings and no '
      'emoji spam. Never sound like a generic AI assistant. Give specific, '
      'actionable advice and reference the user\'s plan and goals when relevant. '
      'For form checks, point them to the Analyze tab.';

  @override
  Future<String> reply(String prompt, List<ChatMessage> history,
      {String context = ''}) async {
    if (apiKey.trim().isEmpty) {
      return _fallback.reply(prompt, history, context: context);
    }
    try {
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content':
              context.isEmpty ? _systemBase : '$_systemBase\n\n$context',
        },
        // Last 10 turns for continuity without burning tokens.
        ...(history.length > 10 ? history.sublist(history.length - 10) : history)
            .map((m) => <String, String>{
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.text,
                }),
        {'role': 'user', 'content': prompt},
      ];

      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 320,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        return _fallback.reply(prompt, history, context: context);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      String? text;
      if (choices != null && choices.isNotEmpty) {
        final message = (choices.first as Map)['message'];
        if (message is Map) {
          final content = message['content'];
          if (content is String) text = content.trim();
        }
      }
      if (text == null || text.isEmpty) {
        return _fallback.reply(prompt, history, context: context);
      }
      return text;
    } catch (_) {
      return _fallback.reply(prompt, history, context: context);
    }
  }
}
