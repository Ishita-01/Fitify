import '../models/chat_message.dart';

/// Contract for the AI assistant. A real impl would call an LLM provider
/// (e.g. Anthropic Claude or OpenAI) with the conversation history; this mock
/// returns canned, keyword-aware replies so the chat UI works offline.
///
/// To plug in a real model later, implement [reply] with an API client and
/// swap the binding in main.dart — no UI changes required.
abstract class AssistantRepository {
  Future<String> reply(String prompt, List<ChatMessage> history);
}

class MockAssistantRepository implements AssistantRepository {
  @override
  Future<String> reply(String prompt, List<ChatMessage> history) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final p = prompt.toLowerCase();

    if (p.contains('diet') || p.contains('eat') || p.contains('nutrition') || p.contains('meal')) {
      return 'For steady progress, aim for a slight calorie deficit with ~1.6–2.2g '
          'of protein per kg of bodyweight. Build meals around lean protein, '
          'whole grains, and plenty of vegetables. Want me to draft a sample day?';
    }
    if (p.contains('protein')) {
      return 'Good protein sources: chicken, eggs, Greek yogurt, tofu, lentils, '
          'and fish. Spreading intake across 3–4 meals helps muscle recovery.';
    }
    if (p.contains('rest') || p.contains('recover') || p.contains('sore')) {
      return 'Recovery is where you grow. Prioritise 7–9h of sleep, stay hydrated, '
          'and give a muscle group ~48h before training it hard again. Light '
          'mobility on rest days helps soreness.';
    }
    if (p.contains('lose') || p.contains('fat') || p.contains('weight')) {
      return 'Fat loss = consistent calorie deficit + resistance training to keep '
          'muscle. Combine 3–4 strength sessions with some cardio, and track '
          'weekly trends rather than daily numbers.';
    }
    if (p.contains('squat') || p.contains('form') || p.contains('posture')) {
      return 'Great question! For the best feedback, record a set and upload it in '
          'the Analyze tab — I\'ll score your posture, depth, and joint angles '
          'and flag anything to fix.';
    }
    if (p.contains('hi') || p.contains('hello') || p.contains('hey')) {
      return 'Hey! I\'m your Fitify coach. Ask me about workouts, diet, recovery, '
          'or form — or upload a video in Analyze for a detailed breakdown.';
    }
    return 'I can help with workouts, nutrition, recovery, and goal planning. '
        'For form checks, upload a clip in the Analyze tab. What would you like '
        'to focus on?';
  }
}
