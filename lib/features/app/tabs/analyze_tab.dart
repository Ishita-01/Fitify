import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/analysis.dart';
import '../providers/analysis_provider.dart';
import '../screens/analysis_report_screen.dart';
import '../screens/emg_screen.dart';
import '../widgets/app_widgets.dart';

class AnalyzeTab extends StatefulWidget {
  const AnalyzeTab({super.key});

  @override
  State<AnalyzeTab> createState() => _AnalyzeTabState();
}

class _AnalyzeTabState extends State<AnalyzeTab> {
  String? _fileName;

  Future<void> _runAnalysis() async {
    final provider = context.read<AnalysisProvider>();
    final exercise = provider.selected;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProcessingDialog(),
    );
    final report = await provider.submit(exercise, fileName: _fileName ?? 'clip.mp4');
    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss processing
    setState(() => _fileName = null);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AnalysisReportScreen(report: report)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final history = provider.reports;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('Analyze', style: AppTextStyles.display.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text('Upload a recorded set for an AI form breakdown.',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Step 1 — select exercise.
          Text('1. Select exercise', style: AppTextStyles.title),
          const SizedBox(height: 10),
          _ExerciseDropdown(
            value: provider.selected,
            onChanged: (e) => provider.select(e),
          ),
          const SizedBox(height: 20),

          // Step 2 — upload video.
          Text('2. Upload your video', style: AppTextStyles.title),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _fileName = 'workout_${provider.selected.name}.mp4'),
            child: DottedUploadBox(fileName: _fileName),
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: 'Analyze Video',
            icon: Icons.auto_awesome_rounded,
            onPressed: _fileName == null
                ? null
                : _runAnalysis,
          ),
          const SizedBox(height: 28),

          // EMG future module.
          Text('Muscle Monitoring', style: AppTextStyles.heading),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const EmgScreen())),
            child: const _EmgTeaser(),
          ),
          const SizedBox(height: 28),

          // History.
          Row(
            children: [
              Text('Previous Reports', style: AppTextStyles.heading),
              const Spacer(),
              Text('${provider.completed.length}',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Text('No analyses yet.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textTertiary))
          else
            for (final r in history) _HistoryRow(report: r),
        ],
      ),
    );
  }
}

class _ExerciseDropdown extends StatelessWidget {
  const _ExerciseDropdown({required this.value, required this.onChanged});
  final AnalyzableExercise value;
  final ValueChanged<AnalyzableExercise> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AnalyzableExercise>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          items: [
            for (final e in AnalyzableExercise.values)
              DropdownMenuItem(
                value: e,
                child: Row(
                  children: [
                    Icon(e.icon, size: 20, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Text(e.label, style: AppTextStyles.title.copyWith(fontSize: 15.5)),
                  ],
                ),
              ),
          ],
          onChanged: (e) => e == null ? null : onChanged(e),
        ),
      ),
    );
  }
}

class DottedUploadBox extends StatelessWidget {
  const DottedUploadBox({super.key, this.fileName});
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final has = fileName != null;
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: has ? AppColors.accentMuted : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: has ? AppColors.accent : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(has ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              size: 40, color: AppColors.accent),
          const SizedBox(height: 10),
          Text(has ? fileName! : 'Tap to upload a video',
              style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 4),
          Text(has ? 'Ready to analyze' : 'MP4 · up to 60s works best',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _EmgTeaser extends StatelessWidget {
  const _EmgTeaser();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFF4338CA)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('EMG Muscle Monitoring',
                        style: AppTextStyles.title
                            .copyWith(color: Colors.white, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('SOON',
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Activation, fatigue & left-right balance',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.report});
  final AnalysisReport report;

  @override
  Widget build(BuildContext context) {
    final processing = report.status == AnalysisStatus.processing;
    return GestureDetector(
      onTap: processing
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AnalysisReportScreen(report: report))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(report.exercise.icon, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.exercise.label,
                      style: AppTextStyles.title.copyWith(fontSize: 15.5)),
                  const SizedBox(height: 2),
                  Text(processing ? 'Processing…' : _ago(report.createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            if (processing)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              Text('${report.overallScore}',
                  style: AppTextStyles.statValue
                      .copyWith(color: _scoreColor(report.overallScore))),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(height: 20),
            Text('Analyzing your video…', style: AppTextStyles.title),
            const SizedBox(height: 6),
            Text('Running pose & movement evaluation',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

Color _scoreColor(int s) {
  if (s >= 85) return AppColors.success;
  if (s >= 70) return AppColors.warning;
  return AppColors.danger;
}
