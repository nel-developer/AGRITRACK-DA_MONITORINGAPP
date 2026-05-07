import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/da_colors.dart';

/// CropFormShell
///
/// Shared layout wrapper for all crop AND livestock monitoring steps.
/// - Green hero header with title + step indicator
/// - White scrollable card for form content
/// - Amber Next/Submit button fixed at bottom

class CropFormShell extends StatelessWidget {
  const CropFormShell({
    super.key,
    required this.currentStep,
    required this.child,
    required this.onNext,
    this.onBack,
    this.nextLabel, // if null → auto Next/Submit
    this.totalSteps = 7,
    this.formTitle = 'CROP PRODUCTION',
    this.formSubtitle = 'Crop Production Monitoring Form',
  });

  final int currentStep;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String? nextLabel;
  final int totalSteps;
  final String formTitle;
  final String formSubtitle;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final topPad = mq.padding.top;
    final botPad = mq.padding.bottom;
    final hPad = screenW * 0.055;
    final imageH = (screenH * 0.22).clamp(140.0, 200.0);

    // Resolve button label
    final buttonLabel =
        nextLabel ?? (currentStep < totalSteps - 1 ? 'Next' : 'Submit');

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Green hero header ──────────────────────────────────
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
                        DAColors.greenDark.withOpacity(0.95),
                        DAColors.greenMid.withOpacity(0.88),
                        DAColors.greenMid.withOpacity(0.60),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.40, 0.75, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, topPad + 14, hPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: onBack ?? () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),

                      const Spacer(),

                      // Title
                      Text(
                        formTitle,
                        style: GoogleFonts.bebasNeue(
                          fontSize: (screenW * 0.088).clamp(28.0, 40.0),
                          color: Colors.white,
                          letterSpacing: 2,
                          height: 1.0,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        formSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: (screenW * 0.03).clamp(10.0, 13.0),
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Step indicator
                      _StepIndicator(
                        current: currentStep,
                        total: totalSteps,
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── White scrollable card ──────────────────────────────
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular((screenW * 0.07).clamp(20.0, 32.0))),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(hPad, 28, hPad, botPad + 100),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom actions (Back + Next/Submit) ────────────────────
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, botPad + 16),
        child: Row(
          children: [
            if (currentStep > 0) ...[
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: onBack ?? () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: DAColors.greenMid, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text('Back',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 20,
                          color: DAColors.greenMid,
                          letterSpacing: 1.5,
                        )),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DAColors.amberLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(buttonLabel,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: 2,
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isComplete = i < current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: isActive ? 6 : 4,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? Colors.white
                        : isActive
                            ? DAColors.amberLight
                            : Colors.white.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}
