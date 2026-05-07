import 'package:flutter/material.dart';

/// ResponsiveHelper
///
/// Screen-size-aware sizing utility used across all AgriTrack screens.
///
/// Breakpoints:
///   phone   < 600 dp  (standard Android/iOS handset)
///   tablet  600–899 dp
///   large   ≥ 900 dp  (landscape tablet / iPad Pro)
///
/// Always instantiate inside build() so it picks up orientation changes:
///
///   @override
///   Widget build(BuildContext context) {
///     final r = ResponsiveHelper(context);
///     ...
///   }
class ResponsiveHelper {
  ResponsiveHelper(BuildContext context) : _size = MediaQuery.sizeOf(context);

  final Size _size;

  // ── Breakpoint flags ────────────────────────────────────────────
  bool get isPhone => _size.width < 600;
  bool get isTablet => _size.width >= 600 && _size.width < 900;
  bool get isLarge => _size.width >= 900;
  bool get isWide => _size.width >= 600; // tablet or larger

  // ── Screen dimensions ───────────────────────────────────────────
  double get screenW => _size.width;
  double get screenH => _size.height;

  // ── Scale factor ────────────────────────────────────────────────
  /// Linear scale relative to 360 dp baseline, capped at 1.8×.
  double get _sf => (_size.width / 360).clamp(0.85, 1.8);

  /// Scale a layout dimension proportionally to screen width.
  double scale(double value) => value * _sf;

  /// Scale a font size — slightly flatter curve than layout scale.
  double scaleFont(double value) => value * (_size.width / 360).clamp(1.0, 1.4);

  // ── Page layout ─────────────────────────────────────────────────
  /// Outer page padding (h + v).
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: isWide ? scale(40) : scale(24),
        vertical: scale(24),
      );

  /// Horizontal page padding only.
  double get pageHPad => isWide ? scale(40) : scale(24);

  /// Max content width — keeps tablets from stretching too wide.
  double get contentMaxWidth => isLarge ? 520 : double.infinity;

  // ── Splash tokens ───────────────────────────────────────────────
  double get splashDaLogoSize =>
      (_size.height * (isWide ? 0.18 : 0.22)).clamp(100.0, 220.0);
  double get splashBrandFontSize => scaleFont(isWide ? 48 : 34);
  double get splashSubFontSize => scaleFont(isWide ? 13 : 11);
  double get splashLogoBrandGap => scale(isWide ? 36 : 24);
  double get splashBrandSubGap => scale(isWide ? 10 : 6);
  double get splashBottomPad => scale(isWide ? 40 : 24);

  // ── Form / card tokens ──────────────────────────────────────────
  double get cardRadius => scale(16);
  double get inputHeight => scale(isWide ? 58 : 50);
  double get buttonHeight => scale(isWide ? 58 : 52);
  double get tileIconSize => scale(isWide ? 56 : 46);
  double get tileRadius => scale(isWide ? 20 : 16);

  // ── Bottom nav ──────────────────────────────────────────────────
  double get bottomNavHeight => scale(isWide ? 70 : 60);
  double get navIconSize => scale(isWide ? 28 : 24);

  // ── Spacing ─────────────────────────────────────────────────────
  double get xs => scale(4);
  double get sm => scale(8);
  double get md => scale(16);
  double get lg => scale(24);
  double get xl => scale(32);
  double get xxl => scale(48);

  // ── Gap helpers (vertical) ──────────────────────────────────────
  SizedBox get gapXS => SizedBox(height: xs);
  SizedBox get gapSM => SizedBox(height: sm);
  SizedBox get gapMD => SizedBox(height: md);
  SizedBox get gapLG => SizedBox(height: lg);
  SizedBox get gapXL => SizedBox(height: xl);
  SizedBox get gapXXL => SizedBox(height: xxl);

  // ── Gap helpers (horizontal) ────────────────────────────────────
  SizedBox get hGapXS => SizedBox(width: xs);
  SizedBox get hGapSM => SizedBox(width: sm);
  SizedBox get hGapMD => SizedBox(width: md);
  SizedBox get hGapLG => SizedBox(width: lg);
}
