import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/emg.dart';
import '../widgets/app_widgets.dart';

/// EMG muscle-monitoring — FUTURE FEATURE. UI placeholder with mock charts and
/// a list of the screens a real hardware/ML integration would unlock.
class EmgScreen extends StatelessWidget {
  const EmgScreen({super.key});

  static const _readings = [
    MuscleReading(group: MuscleGroup.quadriceps, activationPct: 78, fatigueIndex: 42, leftBalancePct: 53),
    MuscleReading(group: MuscleGroup.glutes, activationPct: 64, fatigueIndex: 30, leftBalancePct: 48),
    MuscleReading(group: MuscleGroup.hamstrings, activationPct: 55, fatigueIndex: 38, leftBalancePct: 46),
    MuscleReading(group: MuscleGroup.core, activationPct: 71, fatigueIndex: 26, leftBalancePct: 51),
  ];

  static const _future = [
    ('Muscle Activation', Icons.flash_on_rounded),
    ('Fatigue Monitoring', Icons.battery_alert_rounded),
    ('Left-Right Balance', Icons.compare_arrows_rounded),
    ('Recovery Tracking', Icons.healing_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22)),
                const SizedBox(width: 16),
                Text('Muscle Monitoring', style: AppTextStyles.heading),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6D28D9), Color(0xFF4338CA)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sensors_rounded, color: Colors.white, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EMG integration coming soon',
                            style: AppTextStyles.title
                                .copyWith(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                            'Pair an EMG sensor to see real muscle data. Below is a preview.',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Muscle Activation', style: AppTextStyles.title),
            const SizedBox(height: 12),
            DarkCard(
              child: Column(
                children: [
                  for (var i = 0; i < _readings.length; i++) ...[
                    _ActivationBar(reading: _readings[i]),
                    if (i < _readings.length - 1) const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Left – Right Balance', style: AppTextStyles.title),
            const SizedBox(height: 12),
            DarkCard(
              child: Column(
                children: [
                  for (final r in _readings) ...[
                    _BalanceBar(reading: r),
                    if (r != _readings.last) const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Future Screens', style: AppTextStyles.title),
            const SizedBox(height: 12),
            DarkCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < _future.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: i == _future.length - 1
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                    color: AppColors.border, width: 0.6)),
                      ),
                      child: Row(
                        children: [
                          Icon(_future[i].$2,
                              size: 22, color: AppColors.textSecondary),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Text(_future[i].$1,
                                  style: AppTextStyles.title
                                      .copyWith(fontSize: 15.5))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Soon',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivationBar extends StatelessWidget {
  const _ActivationBar({required this.reading});
  final MuscleReading reading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(reading.group.label,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary))),
            Text('${reading.activationPct}%',
                style: AppTextStyles.label.copyWith(color: AppColors.accent)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: reading.activationPct / 100,
            minHeight: 8,
            backgroundColor: AppColors.surfaceHighlight,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ],
    );
  }
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.reading});
  final MuscleReading reading;

  @override
  Widget build(BuildContext context) {
    final left = reading.leftBalancePct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(reading.group.label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('L $left%', style: AppTextStyles.caption),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Expanded(
                      flex: left,
                      child: Container(height: 8, color: AppColors.accent),
                    ),
                    Expanded(
                      flex: 100 - left,
                      child: Container(height: 8, color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${100 - left}% R', style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}
