import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../auth/login_screen.dart' show mockUserRole;
import '../../theme/da_colors.dart';
import '../../theme/da_text_styles.dart';
import '../../theme/responsive_helper.dart';

const String _mockUserName = 'Juan';
const String _mockUserRole = 'profiler';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final isProfiler = mockUserRole == 'profiler';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Layer 1: Background ────────────────────────────────
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: DAColors.greenDark),
          ),

          // ── Layer 2: Overlay ───────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [
                  DAColors.greenDark.withOpacity(0.88),
                  DAColors.greenDark.withOpacity(0.80),
                  DAColors.greenDark.withOpacity(0.75),
                ],
              ),
            ),
          ),

          // ── Layer 3: Content — Column fills full screen ────────
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r.pageHPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: r.scale(16)),

                  // Top bar
                  _buildTopBar(r),

                  SizedBox(height: r.scale(20)),

                  // Welcome
                  Text(
                    'Welcome, $_mockUserName',
                    style: GoogleFonts.poppins(
                      fontSize:   r.scaleFont(28),
                      fontWeight: FontWeight.w800,
                      color:      DAColors.white,
                      height:     1.2,
                    ),
                  ),

                  SizedBox(height: r.scale(6)),

                  // Role badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.scale(12),
                      vertical:   r.scale(4),
                    ),
                    decoration: BoxDecoration(
                      color:        DAColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(r.scale(20)),
                      border: Border.all(
                        color: DAColors.white.withOpacity(0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _mockUserRole.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize:      r.scaleFont(10),
                        fontWeight:    FontWeight.w600,
                        color:         DAColors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: r.scale(24)),

                  // Section label
                  Text(
                    'Monitoring Forms',
                    style: GoogleFonts.poppins(
                      fontSize:      r.scaleFont(11),
                      fontWeight:    FontWeight.w600,
                      color:         DAColors.white.withOpacity(0.70),
                      letterSpacing: 1.5,
                    ),
                  ),

                  SizedBox(height: r.scale(10)),

                  // ── Tiles — each Expanded so they fill space ───
                  Expanded(
                    child: _MonitoringTile(
                      title:       'Crop Production\nMonitoring',
                      icon:        Icons.grass_rounded,
                      color:       const Color(0xFF43A047),
                      isLocked:    !isProfiler,
                      lockMessage: 'Monitoring forms are only\navailable for Profilers.',
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.implementation,
                              arguments: 'crop'),
                      r: r,
                    ),
                  ),

                  SizedBox(height: r.scale(12)),

                  Expanded(
                    child: _MonitoringTile(
                      title:       'Livestock Production\nMonitoring',
                      icon:        Icons.pets_rounded,
                      color:       const Color(0xFF388E3C),
                      isLocked:    !isProfiler,
                      lockMessage: 'Monitoring forms are only\navailable for Profilers.',
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.implementation,
                              arguments: 'livestock'),
                      r: r,
                    ),
                  ),

                  SizedBox(height: r.scale(12)),

                  Expanded(
                    child: _MonitoringTile(
                      title:       'Poultry Production\nMonitoring',
                      icon:        Icons.egg_rounded,
                      color:       const Color(0xFF2E7D32),
                      isLocked:    !isProfiler,
                      lockMessage: 'Monitoring forms are only\navailable for Profilers.',
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.implementation,
                              arguments: 'poultry'),
                      r: r,
                    ),
                  ),

                  // Bottom clearance for nav bar
                  SizedBox(height: r.scale(90)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ResponsiveHelper r) {
    final logoSize = r.scale(52);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/da_logo.png',
          width:  logoSize,
          height: logoSize,
          fit:    BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width:  logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color:        DAColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(logoSize / 2),
            ),
            alignment: Alignment.center,
            child: Text('DA',
              style: TextStyle(
                fontSize:   logoSize * 0.3,
                fontWeight: FontWeight.w800,
                color:      DAColors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: r.scale(10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AGRI-TRACK',
              style: DATextStyles.brandDisplay(
                fontSize:      r.scaleFont(22),
                letterSpacing: r.scale(2),
              ),
            ),
            Text('CALABARZON',
              style: GoogleFonts.poppins(
                fontSize:      r.scaleFont(9),
                fontWeight:    FontWeight.w600,
                color:         DAColors.white.withOpacity(0.80),
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Monitoring tile — fills its Expanded parent fully
// ═══════════════════════════════════════════════════════════════════
class _MonitoringTile extends StatelessWidget {
  const _MonitoringTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.isLocked,
    required this.lockMessage,
    required this.onTap,
    required this.r,
  });

  final String           title;
  final IconData         icon;
  final Color            color;
  final bool             isLocked;
  final String           lockMessage;
  final VoidCallback     onTap;
  final ResponsiveHelper r;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(r.scale(20)),
      child: Stack(
        children: [

          // Tile base — fills parent fully
          GestureDetector(
            onTap: isLocked ? null : onTap,
            child: Container(
              width:      double.infinity,
              height:     double.infinity,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.30),
                borderRadius: BorderRadius.circular(r.scale(20)),
                border: Border.all(
                  color: DAColors.white.withOpacity(0.18),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: r.scale(20),
                vertical:   r.scale(16),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width:  r.scale(52),
                    height: r.scale(52),
                    decoration: BoxDecoration(
                      color:        DAColors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(r.scale(14)),
                    ),
                    child: Icon(icon, color: DAColors.white, size: r.scale(28)),
                  ),
                  SizedBox(width: r.scale(16)),
                  // Title
                  Expanded(
                    child: Text(title,
                      style: GoogleFonts.poppins(
                        fontSize:   r.scaleFont(16),
                        fontWeight: FontWeight.w700,
                        color:      DAColors.white,
                        height:     1.3,
                      ),
                    ),
                  ),
                  // Arrow
                  Icon(Icons.arrow_forward_ios_rounded,
                    color: DAColors.white.withOpacity(0.70),
                    size:  r.scale(16)),
                ],
              ),
            ),
          ),

          // Lock overlay
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color:        Colors.black.withOpacity(0.60),
                  borderRadius: BorderRadius.circular(r.scale(20)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded,
                      color: DAColors.white, size: r.scale(24)),
                    SizedBox(height: r.scale(6)),
                    Text(lockMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize:   r.scaleFont(11),
                        fontWeight: FontWeight.w500,
                        color:      DAColors.white,
                        height:     1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}