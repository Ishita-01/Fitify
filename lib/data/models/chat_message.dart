// AI assistant chat domain model.

enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime time;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.time,
  });

  bool get isUser => role == ChatRole.user;
}
