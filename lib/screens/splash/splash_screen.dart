import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../routes/app_routes.dart';
import '../../theme/da_colors.dart';
import '../../theme/da_text_styles.dart';
import '../../theme/responsive_helper.dart';

/// SplashScreen
///
/// First screen on cold launch. Shows DA branding with staggered
/// animations, then navigates to Login (or Home if already logged in).
///
/// Fonts  : Bebas Neue (brand name) · Poppins (labels) — via google_fonts
/// Assets : assets/images/splash_bg.png  — rice-field background photo
///          assets/images/da_logo.png    — DA seal (transparent PNG)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Timing ────────────────────────────────────────────────────────
  static const Duration _kTotal = Duration(milliseconds: 900);
  static const Duration _kFadeIn = Duration(milliseconds: 800);
  static const Duration _kLogoDelay = Duration(milliseconds: 200);
  static const Duration _kBrandDelay = Duration(milliseconds: 420);

  // ── Controllers ───────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _brandCtrl;

  // ── Animations ────────────────────────────────────────────────────
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initAnimations();
    _startSequence();
    _startFailSafeNavigation();
  }

  void _initAnimations() {
    // Logo — fade + scale up from 72%
    _logoCtrl = AnimationController(vsync: this, duration: _kFadeIn);
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );

    // Brand — fade + slide up
    _brandCtrl = AnimationController(vsync: this, duration: _kFadeIn);
    _brandFade = CurvedAnimation(parent: _brandCtrl, curve: Curves.easeIn);
    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _brandCtrl, curve: Curves.easeOutCubic));
  }

  Future<void> _startSequence() async {
    await Future.delayed(_kLogoDelay);
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(_kBrandDelay);
    if (!mounted) return;
    _brandCtrl.forward();

    await Future.delayed(_kTotal);
    if (!mounted) return;
    _navigateNext();
  }

  void _startFailSafeNavigation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || _hasNavigated) return;
      _navigateNext(forceLoginFallback: true);
    });
  }

  Future<void> _navigateNext({bool forceLoginFallback = false}) async {
    if (!mounted || _hasNavigated) return;

    var route = AppRoutes.login;

    // Always wait for Firebase Auth to restore the previous session state
    // This ensures users don't get logged out on every app restart
    try {
      final authUser = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      route = authUser != null ? AppRoutes.home : AppRoutes.login;
    } catch (_) {
      route = AppRoutes.login;
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: DAColors.greenDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1 – Background photo
          _SplashBg(),

          // 2 – Green gradient scrim
          _GradientScrim(),

          // 3 – Animated content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
                child: _buildContent(r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ResponsiveHelper r) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        _buildLogo(r),
        SizedBox(height: r.splashLogoBrandGap),
        _buildBrand(r),
        const Spacer(flex: 2),
      ],
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────
  Widget _buildLogo(ResponsiveHelper r) {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Image.asset(
          'assets/images/da_logo.png',
          width: r.splashDaLogoSize,
          height: r.splashDaLogoSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _PlaceholderLogo(r: r),
        ),
      ),
    );
  }

  // ── Brand section ─────────────────────────────────────────────────
  Widget _buildBrand(ResponsiveHelper r) {
    return FadeTransition(
      opacity: _brandFade,
      child: SlideTransition(
        position: _brandSlide,
        child: Column(
          children: [
            // App name — Bebas Neue
            Text(
              'AGRI-TRACK',
              style: DATextStyles.brandDisplay(
                fontSize: r.splashBrandFontSize,
                letterSpacing: r.scale(6),
              ),
            ),

            SizedBox(height: r.splashBrandSubGap),

            Text(
              'DEPARTMENT OF AGRICULTURE',
              textAlign: TextAlign.center,
              style: DATextStyles.labelSm(
                fontSize: r.splashSubFontSize,
                color: Colors.white.withOpacity(0.60),
                letterSpacing: r.scale(3),
              ),
            ),

            SizedBox(height: r.xs),

            Text(
              'CALABARZON  ·  SAAD PROGRAM',
              textAlign: TextAlign.center,
              style: DATextStyles.labelSm(
                fontSize: r.splashSubFontSize,
                color: Colors.white.withOpacity(0.42),
                letterSpacing: r.scale(2.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Private sub-widgets
// ═══════════════════════════════════════════════════════════════════

class _SplashBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/splash_bg.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: DAColors.greenDark),
    );
  }
}

class _GradientScrim extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DAColors.greenDark.withOpacity(0.84),
            DAColors.greenMid.withOpacity(0.68),
            DAColors.greenDark.withOpacity(0.90),
          ],
          stops: const [0.0, 0.48, 1.0],
        ),
      ),
    );
  }
}

/// Shown during development when da_logo.png has not been added yet.
class _PlaceholderLogo extends StatelessWidget {
  const _PlaceholderLogo({required this.r});
  final ResponsiveHelper r;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: r.splashDaLogoSize,
      height: r.splashDaLogoSize,
      alignment: Alignment.center,
      child: Text(
        'DA',
        style: TextStyle(
          fontSize: r.splashDaLogoSize * 0.28,
          fontWeight: FontWeight.w700,
          color: DAColors.white,
        ),
      ),
    );
  }
}
