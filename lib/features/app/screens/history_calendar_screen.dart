import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/analysis.dart';
import '../../../data/models/training_plan.dart';

class HistoryCalendarScreen extends StatefulWidget {
  const HistoryCalendarScreen({
    super.key,
    required this.startDate,
    required this.program,
    required this.reports,
  });

  final DateTime startDate;
  final List<ProgramStage> program;
  final List<AnalysisReport> reports;

  @override
  State<HistoryCalendarScreen> createState() => _HistoryCalendarScreenState();
}

class _HistoryCalendarScreenState extends State<HistoryCalendarScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  String _getMonthLabel() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month.toString().padLeft(2, '0');
    return '$year/$month';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // Sunday-first grid calculation (Sunday = 0 cells offset, Monday = 1, etc.)
    final emptyCells = firstDay.weekday % 7;
    final totalCells = emptyCells + lastDay.day;

    // Map completed dates
    final completedWorkoutDates = <DateTime>{};
    for (final stage in widget.program) {
      for (final day in stage.days) {
        if (day.status == DayStatus.done) {
          final date = widget.startDate.add(Duration(days: day.day - 1));
          completedWorkoutDates.add(DateTime(date.year, date.month, date.day));
        }
      }
    }

    final completedAnalysisDates = <DateTime>{};
    for (final r in widget.reports) {
      completedAnalysisDates.add(DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day));
    }

    final weekdaysLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'History',
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Month Selector Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left_rounded, size: 32, color: AppColors.textPrimary),
                  onPressed: _prevMonth,
                ),
                Text(
                  _getMonthLabel(),
                  style: AppTextStyles.heading.copyWith(fontSize: 20, letterSpacing: 0.5),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right_rounded, size: 32, color: AppColors.textPrimary),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Weekday labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final w in weekdaysLabels)
                  Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Calendar grid
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                mainAxisExtent: 44,
              ),
              itemBuilder: (context, index) {
                if (index < emptyCells) {
                  return const SizedBox.shrink();
                }
                final dayNum = index - emptyCells + 1;
                final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                final cellDateKey = DateTime(cellDate.year, cellDate.month, cellDate.day);
                
                final isToday = cellDateKey.year == now.year && cellDateKey.month == now.month && cellDateKey.day == now.day;
                final isFuture = cellDateKey.isAfter(DateTime(now.year, now.month, now.day));
                
                final isWorkoutDone = completedWorkoutDates.contains(cellDateKey);
                final isAnalysisDone = completedAnalysisDates.contains(cellDateKey);
                final isDone = isWorkoutDone || isAnalysisDone;

                Color? bg;
                Color textCol = isFuture ? AppColors.textTertiary.withValues(alpha: 0.5) : AppColors.textPrimary;
                Border? border;

                if (isToday) {
                  bg = AppColors.textPrimary; // Solid black/white background matching screenshot
                  textCol = AppColors.surface;
                } else if (isDone) {
                  bg = isWorkoutDone ? AppColors.accent : AppColors.success;
                  textCol = Colors.white;
                }

                return Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bg,
                      border: border,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday || isDone ? FontWeight.bold : FontWeight.normal,
                        color: textCol,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
