import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../livestock/livestock_step_wrapper.dart';
import '../crop/crop_step_wrapper.dart';

// ── Implementation type model ─────────────────────────────────────
class _ImplType {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ImplType({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _implTypes = [
  _ImplType(
    key: 'collective',
    title: 'Collective',
    description:
        'Monitor the organization as one group. One monitoring form is filled for the entire organization.',
    icon: Icons.groups_rounded,
    color: DAColors.greenMid,
  ),
  _ImplType(
    key: 'individual',
    title: 'Individual',
    description:
        'Each member will have their own monitoring record and individual monitoring form.',
    icon: Icons.person_rounded,
    color: Color(0xFF1565C0),
  ),
  _ImplType(
    key: 'hybrid',
    title: 'Hybrid',
    description:
        'Group monitoring plus individual member monitoring. Includes both a group form and per-member forms.',
    icon: Icons.people_alt_rounded,
    color: Color(0xFFE65100),
  ),
];

class ImplementationTypeScreen extends StatefulWidget {
  const ImplementationTypeScreen({
    super.key,
    required this.productionType, // 'crop' | 'livestock' | 'poultry'
  });

  final String productionType;

  @override
  State<ImplementationTypeScreen> createState() =>
      _ImplementationTypeScreenState();
}

class _ImplementationTypeScreenState extends State<ImplementationTypeScreen> {
  String? _selected;

  String get _productionLabel {
    switch (widget.productionType.toLowerCase()) {
      case 'livestock':
        return 'Livestock Production';
      case 'poultry':
        return 'Poultry Production';
      default:
        return 'Crop Production';
    }
  }

  void _onSelect(String key) {
    setState(() => _selected = key);

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;

      String route;
      switch (widget.productionType.toLowerCase()) {
        case 'livestock':
          route = AppRoutes.livestockStep1;
          break;
        case 'poultry':
          route = AppRoutes.poultryStep1;
          break;
        default:
          route = AppRoutes.cropStep1;
      }

      if (widget.productionType.toLowerCase() == 'livestock') {
        // Livestock: create wrapper, set implementationType
        final wrapper = LivestockStepWrapper()..implementationType = key;
        Navigator.of(context).pushNamed(route, arguments: wrapper);
      } else if (widget.productionType.toLowerCase() == 'crop') {
        // *** FIXED: create wrapper AND set implementationType before pushing ***
        final wrapper = CropStepWrapper()..implementationType = key;
        Navigator.of(context).pushNamed(route, arguments: wrapper);
      } else {
        Navigator.of(context).pushNamed(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;
    final topPad = mq.padding.top;
    final botPad = mq.padding.bottom;
    final hPad = screenW * 0.055;
    final imageH = (screenH * 0.28).clamp(200.0, 280.0);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero header ────────────────────────────────────────
          SizedBox(
            height: imageH + topPad,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/splash_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: DAColors.greenDark)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        DAColors.greenDark.withOpacity(0.92),
                        DAColors.greenMid.withOpacity(0.85),
                        DAColors.greenMid.withOpacity(0.50),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.40, 0.75, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, topPad + 12, hPad, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.20),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'CHOOSE\nIMPLEMENTATION TYPE',
                        style: GoogleFonts.bebasNeue(
                          fontSize: (screenW * 0.078).clamp(24.0, 38.0),
                          color: Colors.white,
                          letterSpacing: 2,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.35))),
                        child: Text(_productionLabel,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                      const SizedBox(height: 6),
                      Text('Select how monitoring will be conducted.',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.80))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Cards ──────────────────────────────────────────────
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular((screenW * 0.07).clamp(20.0, 32.0))),
                ),
                child: Stack(children: [
                  ListView.separated(
                    padding: EdgeInsets.fromLTRB(hPad, 24, hPad, botPad + 24),
                    itemCount: _implTypes.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: screenH * 0.018),
                    itemBuilder: (ctx, i) {
                      final type = _implTypes[i];
                      return _ImplCard(
                        type: type,
                        isSelected: _selected == type.key,
                        screenW: screenW,
                        screenH: screenH,
                        onTap: () => _onSelect(type.key),
                      );
                    },
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Implementation type card
// ═══════════════════════════════════════════════════════════════════
class _ImplCard extends StatelessWidget {
  const _ImplCard({
    required this.type,
    required this.isSelected,
    required this.screenW,
    required this.screenH,
    this.onTap,
  });

  final _ImplType type;
  final bool isSelected;
  final double screenW;
  final double screenH;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardPad = screenW * 0.045;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isSelected ? type.color : Colors.transparent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? type.color.withOpacity(0.18)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: (screenW * 0.14).clamp(52.0, 64.0),
                height: (screenW * 0.14).clamp(52.0, 64.0),
                decoration: BoxDecoration(
                    color: type.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(type.icon,
                    color: type.color,
                    size: (screenW * 0.075).clamp(28.0, 36.0)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(type.title,
                              style: GoogleFonts.bebasNeue(
                                  fontSize: (screenW * 0.058).clamp(20.0, 28.0),
                                  color: DAColors.textDark,
                                  letterSpacing: 1.5))),
                      if (isSelected)
                        Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                color: type.color, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)),
                    ]),
                    const SizedBox(height: 4),
                    Text(type.description,
                        style: GoogleFonts.poppins(
                            fontSize: (screenW * 0.032).clamp(11.0, 13.0),
                            color: DAColors.textMuted,
                            height: 1.5)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: type.color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(50)),
                      child: Text(
                          type.key == 'collective'
                              ? 'One group form'
                              : type.key == 'individual'
                                  ? 'Per member forms'
                                  : 'Group + member forms',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: type.color)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
