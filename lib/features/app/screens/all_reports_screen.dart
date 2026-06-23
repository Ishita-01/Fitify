import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass.dart';
import '../../../data/models/analysis.dart';
import '../providers/analysis_provider.dart';
import '../widgets/app_widgets.dart';
import 'analysis_report_screen.dart';

/// Full list of completed form-analysis reports (the Home "View all" target).
class AllReportsScreen extends StatelessWidget {
  const AllReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<AnalysisProvider>().completed;
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
                  Text('Your Reports', style: AppTextStyles.heading),
                  const Spacer(),
                  Text('${reports.length}',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
              const SizedBox(height: 20),
              if (reports.isEmpty)
                DarkCard(
                  child: Text(
                    'No analyses yet. Upload a workout video in Analyze to get a '
                    'detailed form breakdown.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                )
              else
                for (final r in reports) ...[
                  _ReportRow(report: r),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});
  final AnalysisReport report;

  Color _color(int s) => s >= 85
      ? AppColors.success
      : (s >= 70 ? AppColors.warning : AppColors.danger);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AnalysisReportScreen(report: report))),
      child: DarkCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
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
                  Text('${report.metrics.length} metrics · ${report.issues.length} issues',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            Text('${report.overallScore}',
                style: AppTextStyles.statValue
                    .copyWith(color: _color(report.overallScore))),
          ],
        ),
      ),
    );
  }
}
