import 'package:flutter/foundation.dart';

import '../../../data/models/chat_message.dart';
import '../../../data/repositories/assistant_repository.dart';

/// Holds the assistant conversation. Calls the repository for replies, so a
/// real LLM can be dropped in by swapping the repository binding.
class AssistantProvider extends ChangeNotifier {
  AssistantProvider(this._repo) {
    _messages.add(ChatMessage(
      role: ChatRole.assistant,
      text:
          "Hi! I'm your Fitify coach 💪 Ask me about workouts, nutrition, recovery "
          "or goals — or upload a clip in Analyze for a form breakdown.",
      time: DateTime.now(),
    ));
  }

  final AssistantRepository _repo;
  final List<ChatMessage> _messages = [];
  bool _typing = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get typing => _typing;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _typing) return;
    _messages.add(ChatMessage(
        role: ChatRole.user, text: trimmed, time: DateTime.now()));
    _typing = true;
    notifyListeners();

    final answer = await _repo.reply(trimmed, _messages);
    _messages.add(ChatMessage(
        role: ChatRole.assistant, text: answer, time: DateTime.now()));
    _typing = false;
    notifyListeners();
  }

  static const List<String> suggestions = [
    'How do I lose fat?',
    'Best protein sources?',
    'How much rest between workouts?',
    'Plan my week',
  ];
}
