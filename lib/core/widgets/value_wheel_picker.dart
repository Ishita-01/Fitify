import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Light vertical wheel picker over an integer range. The selected row sits in
/// a blue outlined pill, matching the onboarding "birth year / height" style.
class ValueWheelPicker extends StatefulWidget {
  const ValueWheelPicker({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  final int min;
  final int max;
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  State<ValueWheelPicker> createState() => _ValueWheelPickerState();
}

class _ValueWheelPickerState extends State<ValueWheelPicker> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.value.clamp(widget.min, widget.max) - widget.min,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.max - widget.min + 1;
    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection pill.
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.onbCardSelected,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.onbPrimary, width: 1.6),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 60,
            perspective: 0.003,
            diameterRatio: 2.0,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) => widget.onChanged(widget.min + i),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (context, i) {
                final v = widget.min + i;
                final selected = v == widget.value;
                return Center(
                  child: Text(
                    widget.unit.isEmpty ? '$v' : '$v ${widget.unit}',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: selected ? 30 : 24,
                      color: selected
                          ? AppColors.onbPrimary
                          : AppColors.onbTextGrey.withValues(alpha: 0.45),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
