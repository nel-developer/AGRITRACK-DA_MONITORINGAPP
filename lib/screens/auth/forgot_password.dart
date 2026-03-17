import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../theme/da_colors.dart';
import '../../theme/da_text_styles.dart';
import '../../theme/responsive_helper.dart';

/// ForgotPasswordScreen
///
/// Layout — identical structure to LoginScreen:
///   • Image block  — full width, natural 938:563 ratio, gradient + branding
///   • Form section — white card, rounded top, overlaps image by 24dp
///     Reset Password title · subtitle · Email field · Submit · Cancel

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool  _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    // TODO: replace with real reset logic (API call)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show success snackbar then go back to login
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reset link sent to ${_emailCtrl.text.trim()}',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: DAColors.greenMid,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _onCancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: DAColors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageBlock(r),
            _buildFormSection(r),
          ],
        ),
      ),
    );
  }

  // ── Image block — same as LoginScreen ────────────────────────────
  Widget _buildImageBlock(ResponsiveHelper r) {
    final imageH   = r.screenW * (563 / 938);
    final logoSize = (imageH * 0.38).clamp(56.0, 110.0);

    return SizedBox(
      width:  r.screenW,
      height: imageH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          Image.asset(
            'assets/images/auth_bg.png',
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) =>
                Container(color: DAColors.greenDark),
          ),

          // Gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [
                  DAColors.greenDark.withOpacity(0.82),
                  DAColors.greenMid.withOpacity(0.72),
                  DAColors.greenLight.withOpacity(0.28),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.30, 0.65, 1.0],
              ),
            ),
          ),

          // Branding
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: r.scale(12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/da_logo.png',
                    width:  logoSize,
                    height: logoSize,
                    fit:    BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        _FallbackLogo(size: logoSize),
                  ),
                  SizedBox(height: r.scale(6)),
                  Text(
                    'AGRI-TRACK',
                    style: DATextStyles.brandDisplay(
                      fontSize:      r.scaleFont(44),
                      letterSpacing: r.scale(3),
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

  // ── Form section ──────────────────────────────────────────────────
  Widget _buildFormSection(ResponsiveHelper r) {
    return Transform.translate(
      offset: Offset(0, -r.scale(24)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: DAColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          r.pageHPad,
          r.scale(28),
          r.pageHPad,
          r.scale(32),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Title
              Text(
                'Reset Password',
                style: GoogleFonts.poppins(
                  fontSize:   r.scaleFont(28),
                  fontWeight: FontWeight.w800,
                  color:      DAColors.greenDark,
                ),
              ),

              SizedBox(height: r.scale(8)),

              // Subtitle
              Text(
                'We will send you the link to reset your password',
                textAlign: TextAlign.center,
                style: DATextStyles.bodyMd(
                  color:    DAColors.textMid,
                  fontSize: r.scaleFont(13),
                ),
              ),

              SizedBox(height: r.scale(28)),

              // Email field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    fontSize:   r.scaleFont(14),
                    fontWeight: FontWeight.w600,
                    color:      DAColors.textDark,
                  ),
                ),
              ),
              SizedBox(height: r.scale(6)),
              TextFormField(
                controller:   _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style:        DATextStyles.fieldValue(fontSize: r.scaleFont(14)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@'))              return 'Enter a valid email';
                  return null;
                },
                decoration: InputDecoration(
                  hintText:  'Enter Email Address',
                  hintStyle: DATextStyles.fieldHint(fontSize: r.scaleFont(14)),
                  filled:    true,
                  fillColor: DAColors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: r.scale(18),
                    vertical:   r.scale(16),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(r.scale(12)),
                    borderSide:   const BorderSide(color: DAColors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(r.scale(12)),
                    borderSide:   const BorderSide(color: DAColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(r.scale(12)),
                    borderSide:   const BorderSide(color: DAColors.greenMid, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(r.scale(12)),
                    borderSide:   const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(r.scale(12)),
                    borderSide:   const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),

              SizedBox(height: r.scale(36)),

              // Submit button — green
              SizedBox(
                width:  double.infinity,
                height: r.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:         DAColors.greenMid,
                    disabledBackgroundColor: DAColors.greenMid.withOpacity(0.7),
                    foregroundColor:         DAColors.white,
                    elevation:               0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(r.scale(14)),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width:  r.scale(22),
                          height: r.scale(22),
                          child: const CircularProgressIndicator(
                            color:       DAColors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            fontSize:      r.scaleFont(15),
                            fontWeight:    FontWeight.w700,
                            color:         DAColors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              SizedBox(height: r.scale(12)),

              // Cancel button — amber
              SizedBox(
                width:  double.infinity,
                height: r.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:         DAColors.amberLight,
                    disabledBackgroundColor: DAColors.amberLight.withOpacity(0.7),
                    foregroundColor:         DAColors.white,
                    elevation:               0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(r.scale(14)),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize:      r.scaleFont(15),
                      fontWeight:    FontWeight.w700,
                      color:         DAColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  size,
      height: size,
      child: Center(
        child: Text(
          'DA',
          style: TextStyle(
            fontSize:   size * 0.3,
            fontWeight: FontWeight.w800,
            color:      DAColors.white,
          ),
        ),
      ),
    );
  }
}