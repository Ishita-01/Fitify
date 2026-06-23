import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass.dart';
import 'providers/theme_provider.dart';
import 'tabs/analyze_tab.dart';
import 'tabs/assistant_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/workouts_tab.dart';

/// The main app shell. Tabs: Home · Workouts · Analyze · Assistant · Profile.
/// A horizontally-swipeable [PageView] sits behind a floating liquid-glass
/// dock whose selection "pill" tracks the drag offset in real time.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late double _page = widget.initialIndex.toDouble();
  int _settled = 0;

  // Non-const so they rebuild when the theme toggles (they read AppColors
  // statics, which aren't InheritedWidgets — kept-alive const tabs would
  // otherwise keep stale colours after a dark-mode switch).
  Widget _tabFor(int i) => switch (i) {
        0 => HomeTab(),
        1 => WorkoutsTab(),
        2 => AnalyzeTab(),
        3 => AssistantTab(),
        _ => ProfileTab(),
      };

  static const _items = [
    _NavSpec('Home', Icons.home_outlined, Icons.home_rounded),
    _NavSpec('Discover', Icons.explore_outlined, Icons.explore_rounded),
    _NavSpec('Analyze', Icons.insights_outlined, Icons.insights_rounded),
    _NavSpec('Assistant', Icons.forum_outlined, Icons.forum_rounded),
    _NavSpec('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _settled = widget.initialIndex;
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final p = _controller.page ?? _page;
    setState(() => _page = p);
    final nearest = p.round();
    if (nearest != _settled) {
      _settled = nearest;
      HapticFeedback.selectionClick(); // little "click" as the pill settles
    }
  }

  void _go(int i) => _controller.animateToPage(
        i,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // rebuild tabs when the theme flips
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: AmbientBackground(
        child: PageView.builder(
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          itemCount: _items.length,
          itemBuilder: (_, i) => _KeepAlive(child: _tabFor(i)),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: LiquidPanel(
          radius: 34,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: LayoutBuilder(
            builder: (context, c) {
              final slot = c.maxWidth / _items.length;
              final clamped = _page.clamp(0.0, (_items.length - 1).toDouble());
              return SizedBox(
                height: 54,
                child: Stack(
                  children: [
                    // The liquid selection pill — slides with the drag.
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: clamped * slot,
                      width: slot,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          Expanded(
                            child: _NavButton(
                              spec: _items[i],
                              // 1 when centred under this slot, 0 when a full
                              // slot away — drives the colour/scale blend.
                              t: (1 - (clamped - i).abs()).clamp(0.0, 1.0),
                              onTap: () => _go(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.spec, required this.t, required this.onTap});
  final _NavSpec spec;
  final double t; // 0..1 selection strength
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(AppColors.textSecondary, AppColors.accent, t)!;
    final selected = t > 0.5;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 1 + t * 0.08,
              child: Icon(selected ? spec.activeIcon : spec.icon,
                  size: 23, color: color),
            ),
            const SizedBox(height: 2),
            Text(spec.label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: t > 0.5 ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

/// Keeps a [PageView] child alive when swiped off-screen so its state survives.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
