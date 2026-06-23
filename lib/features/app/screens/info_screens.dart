import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass.dart';
import '../widgets/app_widgets.dart';

/// Shared scaffold for the simple content screens (FAQ / Privacy / Subscription).
class _InfoScaffold extends StatelessWidget {
  const _InfoScaffold({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Text(title, style: AppTextStyles.heading),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  static const _faqs = <(String, String)>[
    (
      'How does the video analysis work?',
      'Pick an exercise, then upload or record a clip. Fitify tracks your body '
          'with on-device pose estimation, counts your reps, and scores your form '
          'on depth, range of motion and stability — then gives you tips to improve.'
    ),
    (
      'Which exercises are supported?',
      'Twelve for now: squat, deadlift, romanian deadlift, push-up, pull-up, '
          'shoulder press, hammer curl, lateral raise, plank, leg raises, russian '
          'twist and hip thrust. More are on the way.'
    ),
    (
      'How should I film my set?',
      'Film from the front or side with your whole body in frame, in decent light. '
          'Clips up to 60 seconds work best. Keep the camera steady on the floor or a tripod.'
    ),
    (
      'Is my workout plan personalized?',
      'Yes. Your plan is built from your onboarding answers — goal, experience, '
          'how often you train and what you enjoy — and it progresses week to week.'
    ),
    (
      'Is my data private?',
      'Everything you enter is stored on your device. Videos are only used to '
          'produce your form report. See the Privacy Policy for details.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Help & FAQ',
      children: [
        for (final f in _faqs) ...[
          _FaqTile(question: f.$1, answer: f.$2),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        DarkCard(
          child: Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Still stuck? Email support@fitify.app',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: DarkCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.question,
                      style: AppTextStyles.title.copyWith(fontSize: 15.5)),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(widget.answer,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary, height: 1.5)),
              ),
              crossFadeState:
                  _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'What we store',
      'Your profile (goal, body metrics, preferences), your generated plan '
          'progress, and your analysis reports are saved locally on your device '
          'using secure app storage.'
    ),
    (
      'Your videos',
      'Clips you upload or record are used only to generate your form report. '
          'They are processed for pose estimation and are not sold or shared with '
          'third parties.'
    ),
    (
      'AI coach',
      'When you chat with the coach, your message and a short summary of your '
          'profile and plan are sent to the language-model provider to generate a '
          'reply. Do not share sensitive personal information in chat.'
    ),
    (
      'Analytics',
      'Fitify does not run third-party ad trackers. Any diagnostics are '
          'anonymous and used only to fix bugs.'
    ),
    (
      'Your control',
      'You can clear your data at any time from the app. Removing the app '
          'deletes all locally stored information.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Privacy Policy',
      children: [
        Text('Last updated: June 2026',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 14),
        for (final s in _sections) ...[
          DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$1, style: AppTextStyles.title.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                Text(s.$2,
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const _premium = <String>[
    'Unlimited video form analyses',
    'Full progress history & trends',
    'Advanced plan personalization',
    'Priority AI coach responses',
    'EMG muscle monitoring (coming soon)',
  ];

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Subscription',
      children: [
        // Current plan
        DarkCard(
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accentMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_circle_rounded, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free plan', style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text('Your current plan',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Premium card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82FF), Color(0xFF2563FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.premium, size: 28),
                  const SizedBox(width: 10),
                  Text('Fitify Premium',
                      style: AppTextStyles.heading
                          .copyWith(color: Colors.white, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Everything in Free, plus:',
                  style:
                      AppTextStyles.body.copyWith(color: Colors.white70)),
              const SizedBox(height: 14),
              for (final f in _premium)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(f,
                            style: AppTextStyles.body
                                .copyWith(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              GradientButton(
                label: 'Go Premium · \$4.99/mo',
                gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFEFF3FF)]),
                textColor: AppColors.accent,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Premium is a demo — billing not enabled.'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text('Cancel anytime · Demo build, no real billing',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        ),
      ],
    );
  }
}
