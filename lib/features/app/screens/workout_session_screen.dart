import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/workout.dart';
import '../widgets/app_widgets.dart';

/// Guided workout session. The coach walks the user through each exercise with
/// an animation placeholder, a timer (or rep target), progress, rest screens
/// and a next-exercise preview. NO camera, pose estimation or live analysis.
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key, required this.workout});
  final Workout workout;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with SingleTickerProviderStateMixin {
  static const _restSeconds = 15;

  late final AnimationController _pulse;
  Timer? _timer;
  int _index = 0;
  bool _resting = false;
  bool _paused = false;
  int _remaining = 0;

  List<Exercise> get _exercises => widget.workout.exercises;
  Exercise get _current => _exercises[_index];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _setupCurrent();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _setupCurrent() {
    _remaining = _current.isTimed ? _current.durationSec! : 0;
  }

  void _tick(Timer t) {
    if (_paused) return;
    setState(() {
      if (_resting) {
        _remaining--;
        if (_remaining <= 0) {
          _resting = false;
          _setupCurrent();
        }
      } else if (_current.isTimed) {
        _remaining--;
        if (_remaining <= 0) _complete();
      }
    });
  }

  /// Finish current exercise → rest then next, or end the workout.
  void _complete() {
    if (_index >= _exercises.length - 1) {
      _finish();
      return;
    }
    _index++;
    _resting = true;
    _remaining = _restSeconds;
  }

  void _skip() => setState(_complete);

  void _previous() {
    if (_index == 0 && !_resting) return;
    setState(() {
      if (_resting) {
        _resting = false;
      } else if (_index > 0) {
        _index--;
      }
      _setupCurrent();
    });
  }

  void _finish() {
    _timer?.cancel();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Workout complete! 🎉', style: AppTextStyles.title),
        content: Text(
          'Nice work — you finished ${widget.workout.title}.\n'
          'Want a form check? Record a set and upload it in Analyze.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text('Done',
                style: AppTextStyles.label.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _exit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Exit workout?', style: AppTextStyles.title),
        content: Text('Your progress for this session won\'t be saved.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Stay',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Exit',
                  style: AppTextStyles.label.copyWith(color: AppColors.danger))),
        ],
      ),
    );
    if (leave == true && mounted) {
      _timer?.cancel();
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = _exercises.length;
    final progress = (_index + (_resting ? 1 : 0)) / total;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                      onTap: _exit,
                      child: const Icon(Icons.close_rounded, size: 26)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceHighlight,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('${_index + 1}/$total', style: AppTextStyles.label),
                ],
              ),
              Expanded(child: _resting ? _restView() : _exerciseView()),
              _controls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseView() {
    return Column(
      children: [
        const Spacer(),
        Text('EXERCISE ${_index + 1} OF ${_exercises.length}',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6)),
        const SizedBox(height: 16),
        // Animation placeholder (a real GIF/Lottie would render here).
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEAF1FF), Color(0xFFF4F5FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.05).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: Center(
              child: Icon(_current.icon, size: 96, color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(_current.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(fontSize: 26)),
        const SizedBox(height: 10),
        Text(_current.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary, fontSize: 14.5)),
        const SizedBox(height: 20),
        Text(
          _current.isTimed ? _fmt(_remaining) : '× ${_current.reps}',
          style: AppTextStyles.display
              .copyWith(fontSize: 52, color: AppColors.textPrimary),
        ),
        const Spacer(),
        if (_index < _exercises.length - 1)
          Text('Next: ${_exercises[_index + 1].name}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _restView() {
    final next = _current; // _index already advanced into rest
    return Column(
      children: [
        const Spacer(),
        Text('REST', style: AppTextStyles.heading.copyWith(color: AppColors.accent)),
        const SizedBox(height: 8),
        Text(_fmt(_remaining),
            style: AppTextStyles.display.copyWith(fontSize: 72)),
        const SizedBox(height: 24),
        DarkCard(
          child: Column(
            children: [
              Text('UP NEXT',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Icon(next.icon, size: 48, color: AppColors.accent),
              const SizedBox(height: 8),
              Text(next.name, style: AppTextStyles.title),
              const SizedBox(height: 2),
              Text(next.metaLabel,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _controls() {
    return Row(
      children: [
        Expanded(
          child: _SecondaryBtn(
              icon: Icons.skip_previous_rounded,
              label: 'Prev',
              onTap: _previous),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GradientButton(
            label: _paused ? 'Resume' : (_resting ? 'Skip Rest' : 'Pause'),
            icon: _paused
                ? Icons.play_arrow_rounded
                : (_resting ? Icons.fast_forward_rounded : Icons.pause_rounded),
            onPressed: () {
              if (_resting) {
                setState(() {
                  _resting = false;
                  _setupCurrent();
                });
              } else {
                setState(() => _paused = !_paused);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SecondaryBtn(
              icon: Icons.skip_next_rounded, label: 'Skip', onTap: _skip),
        ),
      ],
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
