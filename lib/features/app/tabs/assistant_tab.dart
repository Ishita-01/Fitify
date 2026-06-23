import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat_message.dart';
import '../providers/assistant_provider.dart';

class AssistantTab extends StatefulWidget {
  const AssistantTab({super.key});

  @override
  State<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<AssistantTab> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  void _send(String text) {
    if (text.trim().isEmpty) return;
    context.read<AssistantProvider>().send(text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    final messages = provider.messages;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle),
                  child:
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Coach', style: AppTextStyles.title),
                    Text('Always here to help',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: messages.length + (provider.typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == messages.length) return const _TypingBubble();
                return _Bubble(message: messages[i]);
              },
            ),
          ),
          if (messages.length <= 1)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final s in AssistantProvider.suggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _send(s),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.isDark
                                ? AppColors.accent.withValues(alpha: 0.14)
                                : Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppColors.accent.withValues(alpha: 0.55)),
                          ),
                          child: Text(s,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.accent)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final dark = AppColors.isDark;
    // Coach bubble: black glass in dark, frosted white in light.
    final coachFill = dark
        ? const Color(0xFF191B21)
        : Colors.white.withValues(alpha: 0.62);
    final coachBorder = dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.75);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent.withValues(alpha: 0.95) : coachFill,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
              color: isUser
                  ? Colors.white.withValues(alpha: 0.18)
                  : coachBorder),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.30)
                  : const Color(0xFF1B2559).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _CoachText(
          text: message.text,
          color: isUser ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Renders coach text with light markdown: **bold** runs and `- ` bullet lines,
/// so replies read as formatted points rather than one grey blob. No package —
/// keeps the app light.
class _CoachText extends StatelessWidget {
  const _CoachText({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.body
        .copyWith(color: color, fontSize: 14.5, height: 1.42);
    final lines = text.split('\n');
    final widgets = <Widget>[];
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }
      final bullet = line.startsWith('- ') || line.startsWith('• ');
      final content = bullet ? line.substring(2) : line;
      final span = TextSpan(style: base, children: _spans(content, base));
      if (bullet) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1, right: 8),
                child: Text('•',
                    style: base.copyWith(color: AppColors.accent)),
              ),
              Expanded(child: Text.rich(span)),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text.rich(span),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  // Split a line on **…** into bold / normal spans.
  List<TextSpan> _spans(String line, TextStyle base) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var i = 0;
    for (final m in re.allMatches(line)) {
      if (m.start > i) spans.add(TextSpan(text: line.substring(i, m.start)));
      spans.add(TextSpan(
          text: m.group(1),
          style: base.copyWith(fontWeight: FontWeight.w700)));
      i = m.end;
    }
    if (i < line.length) spans.add(TextSpan(text: line.substring(i)));
    return spans;
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xFF191B21)
              : Colors.white.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.white
                  .withValues(alpha: dark ? 0.06 : 0.75)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(),
            SizedBox(width: 4),
            _Dot(),
            SizedBox(width: 4),
            _Dot(),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
          color: AppColors.textTertiary, shape: BoxShape.circle),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: dark
                ? AppColors.background.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.45),
            border: Border(
                top: BorderSide(
                    color: Colors.white
                        .withValues(alpha: dark ? 0.06 : 0.70),
                    width: 1)),
          ),
          child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              cursorColor: AppColors.accent,
              onSubmitted: onSend,
              decoration: InputDecoration(
                hintText: 'Ask your coach…',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                filled: true,
                fillColor: dark
                    ? AppColors.surfaceElevated
                    : Colors.white.withValues(alpha: 0.65),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onSend(controller.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  gradient: AppColors.accentGradient, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          ),
          ],
          ),
        ),
      ),
    );
  }
}
