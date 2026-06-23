import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../theme/app_colors.dart';

/// Real shader-based "liquid glass" panel (Apple-style lensing/refraction) for
/// HERO surfaces only — the This-Week card, the tab dock, the chat composer,
/// the upload box. Heavier than [GlassSurface]; never put it in a scrolling
/// list. Needs Impeller (default on iOS) and an [AmbientBackground] behind it.
class LiquidPanel extends StatelessWidget {
  const LiquidPanel({
    super.key,
    required this.child,
    this.radius = 26,
    this.padding = const EdgeInsets.all(18),
    this.tint,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final base = tint ?? Colors.white;
    // Dark sits over near-black, so a faint frost + lensing reads as glass.
    // Light needs a stronger white tint + frost + a lift shadow or it vanishes.
    final glass = LiquidGlass.withOwnLayer(
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      glassContainsChild: false,
      settings: LiquidGlassSettings(
        glassColor: base.withValues(alpha: dark ? 0.08 : 0.34),
        thickness: dark ? 16 : 14,
        blur: dark ? 5 : 10,
        refractiveIndex: 1.4,
        lightAngle: -0.45 * 3.1415926,
        lightIntensity: dark ? 1.0 : 0.8,
        ambientStrength: dark ? 0.12 : 0.25,
        saturation: 1.1,
      ),
      child: Padding(padding: padding, child: child),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF1B2559).withValues(alpha: 0.12),
            blurRadius: dark ? 20 : 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: glass,
    );
  }
}

/// The everyday card surface used across the app (lists, rows, tiles).
///
/// DARK: a sleek, solid near-black card with a hairline border + a faint top
/// sheen — NO backdrop blur (the background is pure black, so a blur would only
/// cost GPU and muddy the card into grey). This is the "black, not grey" look.
///
/// LIGHT: a genuine frosted-glass pane (backdrop blur + translucent white) that
/// refracts the soft colour wash behind it.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(18),
    this.tint,
    this.opacity,
    this.blur = 22,
    this.border = true,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  /// Optional colour wash over the surface (e.g. accent-tinted panes).
  final Color? tint;

  /// Light-mode base fill alpha. When null, resolves per theme.
  final double? opacity;
  final double blur;
  final bool border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return AppColors.isDark ? _buildDark() : _buildLight();
  }

  // Solid near-black card — cheap, crisp, matches the reference.
  Widget _buildDark() {
    final base = tint;
    final topFill = base ?? const Color(0xFF181A20);
    final bottomFill = base ?? const Color(0xFF101217);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topFill, bottomFill],
        ),
        border: border
            ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1)
            : null,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Faint glassy sheen along the very top edge.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(radius)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }

  // Frosted translucent glass for light mode.
  Widget _buildLight() {
    final base = tint ?? Colors.white;
    final fill = opacity ?? 0.42;
    final fillTop = (fill + 0.10).clamp(0.0, 1.0);
    final fillBottom = (fill - 0.08).clamp(0.0, 1.0);
    final sheen = Colors.white.withValues(alpha: 0.55);

    return Container(
      decoration: shadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B2559).withValues(alpha: 0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  base.withValues(alpha: fillTop),
                  base.withValues(alpha: fillBottom),
                ],
              ),
              border: border
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.55), width: 1)
                  : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [sheen, sheen.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Background behind every screen.
///
/// LIGHT: soft drifting colour blobs — the "liquid" the glass refracts.
/// DARK: pure near-black (no blobs) so cards read as clean black/glass instead
/// of muddy grey, exactly like the reference. Also far cheaper to paint.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppColors.isDark) {
      return Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: AppColors.background)),
          child,
        ],
      );
    }
    const a = 0.45;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: AppColors.background)),
        Positioned(top: -120, left: -100, child: _Blob(const Color(0xFF7DA7FF), 340, a)),
        Positioned(top: 160, right: -140, child: _Blob(const Color(0xFFC9B8FF), 320, a)),
        Positioned(bottom: -80, left: -60, child: _Blob(const Color(0xFF9FE8C9), 300, a)),
        Positioned(bottom: 220, right: -40, child: _Blob(const Color(0xFFFFD9A8), 220, a)),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.color, this.size, this.alpha);
  final Color color;
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}
