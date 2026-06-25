import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass.dart';
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
  String? _videoPath; // real file path — sent to the analysis backend later

  void _setPicked(String? path) {
    if (path == null) return;
    setState(() {
      _videoPath = path;
      _fileName = path.split('/').last;
    });
  }

  Future<void> _showUploadOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UploadSheet(),
    );
    if (choice == null || !mounted) return;
    try {
      switch (choice) {
        case 'photos':
          final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
          _setPicked(x?.path);
        case 'record':
          final x = await ImagePicker().pickVideo(
              source: ImageSource.camera,
              maxDuration: const Duration(seconds: 60));
          _setPicked(x?.path);
        case 'files':
          final res = await FilePicker.pickFiles(type: FileType.video);
          _setPicked(res?.files.single.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not open: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _runAnalysis() async {
    final provider = context.read<AnalysisProvider>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProcessingDialog(),
    );
    final report = await provider.submit(
      fileName: _fileName ?? 'clip.mp4',
      videoPath: _videoPath,
    );
    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss processing
    setState(() {
      _fileName = null;
      _videoPath = null;
    });
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AnalysisReportScreen(report: report)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AnalysisProvider>();
    final history = provider.reports;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text('Analyze', style: AppTextStyles.display.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text('Upload a recorded set for an AI form breakdown.',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Upload video — exercise is auto-classified by ML.
          Text('Upload your video', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('Our AI will auto-detect the exercise from your video.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.accent, fontSize: 12)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _showUploadOptions,
            child: DottedUploadBox(fileName: _fileName),
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: 'Analyze Video',
            icon: Icons.auto_awesome_rounded,
            onPressed: _videoPath == null ? null : _runAnalysis,
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

// Exercise dropdown removed — ML auto-classifies the exercise from the video.

class _UploadSheet extends StatelessWidget {
  const _UploadSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: GlassSurface(
          radius: 26,
          opacity: AppColors.isDark ? 0.16 : 0.85,
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Add a video',
                      style: AppTextStyles.title.copyWith(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              _SheetOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from Photos',
                  subtitle: 'Pick an existing video',
                  onTap: () => Navigator.pop(context, 'photos')),
              _SheetOption(
                  icon: Icons.folder_rounded,
                  title: 'Choose from Files',
                  subtitle: 'Browse the Files app',
                  onTap: () => Navigator.pop(context, 'files')),
              _SheetOption(
                  icon: Icons.videocam_rounded,
                  title: 'Record a set',
                  subtitle: 'Up to 60 seconds',
                  onTap: () => Navigator.pop(context, 'record')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title.copyWith(fontSize: 15.5)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
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
    return LiquidPanel(
      radius: 20,
      tint: has ? AppColors.accentSoft : null,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 150,
        width: double.infinity,
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
            colors: [Color(0xD96D28D9), Color(0xE64338CA)]),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.40), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
        child: GlassSurface(
          radius: 18,
          padding: const EdgeInsets.all(14),
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
            Text('Classifying exercise…', style: AppTextStyles.title),
            const SizedBox(height: 6),
            Text('AI is detecting the exercise & analyzing your form',
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
