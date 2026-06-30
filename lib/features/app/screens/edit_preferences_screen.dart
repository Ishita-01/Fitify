import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/onboarding_enums.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../widgets/app_widgets.dart';

class EditPreferencesScreen extends StatefulWidget {
  const EditPreferencesScreen({super.key});

  @override
  State<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends State<EditPreferencesScreen> {
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _targetWeightController;

  Gender? _gender;
  BodyShape? _bodyShape;
  DesiredShape? _desiredShape;
  WorkoutRecency? _recency;
  WorkoutIntensity? _intensity;

  final List<FitnessGoal> _goals = [];
  final List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    final profile = context.read<OnboardingProvider>().profile;
    _nameController = TextEditingController(text: profile.name ?? '');
    _heightController = TextEditingController(text: profile.heightCm?.toString() ?? '');
    _currentWeightController = TextEditingController(text: profile.currentWeightKg?.toString() ?? '');
    _targetWeightController = TextEditingController(text: profile.targetWeightKg?.toString() ?? '');

    _gender = profile.gender;
    _bodyShape = profile.currentBodyShape;
    _desiredShape = profile.desiredBodyShape;
    _recency = profile.lastWorkout;
    _intensity = profile.intensity;

    _goals.addAll(profile.goals);
    _activities.addAll(profile.activities);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final name = _nameController.text.trim();
    final height = int.tryParse(_heightController.text);
    final currentWeight = int.tryParse(_currentWeightController.text);
    final targetWeight = int.tryParse(_targetWeightController.text);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    final onb = context.read<OnboardingProvider>();
    final updatedProfile = onb.profile.copyWith(
      name: name,
      gender: _gender,
      currentBodyShape: _bodyShape,
      desiredBodyShape: _desiredShape,
      heightCm: height,
      currentWeightKg: currentWeight,
      targetWeightKg: targetWeight,
      lastWorkout: _recency,
      intensity: _intensity,
      goals: _goals,
      activities: _activities,
    );

    onb.updateProfile(updatedProfile);
    onb.finish(); // Save to SharedPreferences

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved successfully!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Edit Preferences', style: AppTextStyles.heading.copyWith(fontSize: 22)),
        actions: [
          IconButton(
            icon: Icon(Icons.check_rounded, color: AppColors.accent, size: 28),
            onPressed: () => _save(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _sectionHeader('Profile Info'),
            DarkCard(
              child: _buildTextField(
                label: 'Name',
                controller: _nameController,
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(height: 16),
            _DropdownPreferenceCard(
              label: 'Gender',
              summary: _gender?.label ?? 'Not set',
              icon: _gender?.icon ?? Icons.person_outline_rounded,
              child: _buildGenderChips(),
            ),
            const SizedBox(height: 24),
            _sectionHeader('Body & Metrics'),
            DarkCard(
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Height (cm)',
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    suffixText: 'cm',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Current Weight (kg)',
                    controller: _currentWeightController,
                    keyboardType: TextInputType.number,
                    suffixText: 'kg',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Target Weight (kg)',
                    controller: _targetWeightController,
                    keyboardType: TextInputType.number,
                    suffixText: 'kg',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DropdownPreferenceCard(
              label: 'Current Body Shape',
              summary: _bodyShape?.label ?? 'Not set',
              icon: _bodyShape?.icon ?? Icons.accessibility_new_rounded,
              child: _buildBodyShapeChips(),
            ),
            const SizedBox(height: 16),
            _DropdownPreferenceCard(
              label: 'Desired Body Shape',
              summary: _desiredShape?.label ?? 'Not set',
              icon: _desiredShape?.icon ?? Icons.star_outline_rounded,
              child: _buildDesiredShapeChips(),
            ),
            const SizedBox(height: 24),
            _sectionHeader('Workout Details'),
            _DropdownPreferenceCard(
              label: 'Last Workout Recency',
              summary: _recency?.label ?? 'Not set',
              icon: _recency?.icon ?? Icons.calendar_month_rounded,
              child: _buildRecencyChips(),
            ),
            const SizedBox(height: 16),
            _DropdownPreferenceCard(
              label: 'Workout Intensity',
              summary: _intensity?.label ?? 'Not set',
              icon: _intensity?.icon ?? Icons.bolt_rounded,
              child: _buildIntensityOptions(),
            ),
            const SizedBox(height: 24),
            _sectionHeader('Goals & Target Areas'),
            _DropdownPreferenceCard(
              label: 'Goals',
              summary: _goals.isEmpty ? 'None selected' : _goals.map((g) => g.label).join(', '),
              icon: Icons.auto_awesome_rounded,
              child: _buildGoalChips(),
            ),
            const SizedBox(height: 24),
            _sectionHeader('Favorite Activities'),
            _DropdownPreferenceCard(
              label: 'Favorite Activities',
              summary: _activities.isEmpty ? 'None selected' : _activities.map((a) => a.label).join(', '),
              icon: Icons.fitness_center_rounded,
              child: _buildActivityChips(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: keyboardType == TextInputType.text ? TextCapitalization.words : TextCapitalization.none,
      cursorColor: AppColors.accent,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        suffixText: suffixText,
        suffixStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.surfaceHighlight),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildGenderChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final g in Gender.values)
          FilterChip(
            label: Text(
              g.label,
              style: TextStyle(
                fontSize: 11,
                color: _gender == g ? Colors.white : AppColors.textSecondary,
              ),
            ),
            selected: _gender == g,
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surfaceHighlight,
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.transparent),
            ),
            onSelected: (bool selected) {
              if (selected) {
                setState(() => _gender = g);
              }
            },
          ),
      ],
    );
  }

  Widget _buildBodyShapeChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final bs in BodyShape.values)
          FilterChip(
            label: Text(
              bs.label,
              style: TextStyle(
                fontSize: 11,
                color: _bodyShape == bs ? Colors.white : AppColors.textSecondary,
              ),
            ),
            selected: _bodyShape == bs,
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surfaceHighlight,
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.transparent),
            ),
            onSelected: (bool selected) {
              if (selected) {
                setState(() => _bodyShape = bs);
              }
            },
          ),
      ],
    );
  }

  Widget _buildDesiredShapeChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final ds in DesiredShape.values)
          FilterChip(
            label: Text(
              ds.label,
              style: TextStyle(
                fontSize: 11,
                color: _desiredShape == ds ? Colors.white : AppColors.textSecondary,
              ),
            ),
            selected: _desiredShape == ds,
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surfaceHighlight,
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.transparent),
            ),
            onSelected: (bool selected) {
              if (selected) {
                setState(() => _desiredShape = ds);
              }
            },
          ),
      ],
    );
  }

  Widget _buildRecencyChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final wr in WorkoutRecency.values)
          FilterChip(
            label: Text(
              wr.label,
              style: TextStyle(
                fontSize: 11,
                color: _recency == wr ? Colors.white : AppColors.textSecondary,
              ),
            ),
            selected: _recency == wr,
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surfaceHighlight,
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.transparent),
            ),
            onSelected: (bool selected) {
              if (selected) {
                setState(() => _recency = wr);
              }
            },
          ),
      ],
    );
  }

  Widget _buildIntensityOptions() {
    return Column(
      children: [
        for (final wi in WorkoutIntensity.values) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              wi.icon,
              color: _intensity == wi ? AppColors.accent : AppColors.textSecondary,
              size: 20,
            ),
            title: Text(
              wi.label,
              style: AppTextStyles.label.copyWith(
                fontSize: 13.5,
                color: _intensity == wi ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            subtitle: Text(
              wi.subtitle,
              style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textTertiary),
            ),
            trailing: _intensity == wi ? Icon(Icons.check_rounded, color: AppColors.accent, size: 20) : null,
            onTap: () => setState(() => _intensity = wi),
          ),
          if (wi != WorkoutIntensity.values.last)
            Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
        ],
      ],
    );
  }

  Widget _buildGoalChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final goal in FitnessGoal.values)
          FilterChip(
            label: Text(
              goal.label,
              style: TextStyle(
                fontSize: 11,
                color: _goals.contains(goal) ? Colors.white : AppColors.textSecondary,
              ),
            ),
            selected: _goals.contains(goal),
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surfaceHighlight,
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.transparent),
            ),
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  _goals.add(goal);
                } else {
                  _goals.remove(goal);
                }
              });
            },
          ),
      ],
    );
  }

  Widget _buildActivityChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final act in Activity.values)
          FilterChip(
            label: Text(
              act.label,
              style: TextStyle(
                fontSize: 11,
                color: _activities.contains(act) ? Colors.white : AppColors.textSecondary,
              ),
            ),
            selected: _activities.contains(act),
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surfaceHighlight,
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.transparent),
            ),
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  _activities.add(act);
                } else {
                  _activities.remove(act);
                }
              });
            },
          ),
      ],
    );
  }
}

class _DropdownPreferenceCard extends StatefulWidget {
  const _DropdownPreferenceCard({
    required this.label,
    required this.summary,
    required this.icon,
    required this.child,
  });

  final String label;
  final String summary;
  final IconData icon;
  final Widget child;

  @override
  State<_DropdownPreferenceCard> createState() => _DropdownPreferenceCardState();
}

class _DropdownPreferenceCardState extends State<_DropdownPreferenceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  Icon(widget.icon, color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.summary,
                          style: AppTextStyles.title.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}
