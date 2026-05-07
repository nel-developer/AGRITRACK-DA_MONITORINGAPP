import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../services/user_session_service.dart';
import '../../theme/da_colors.dart';
import '../../theme/da_text_styles.dart';
import '../../theme/responsive_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await UserSessionService.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage(error),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('user-not-found')) return 'Account not found.';
    if (message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (message.contains('account-not-approved')) {
      return 'Your account is still pending admin approval.';
    }
    if (message.contains('profile-not-found')) {
      return 'Account profile not found. Please contact admin.';
    }
    if (message.contains('permission-denied')) {
      return 'Login succeeded but account profile access is restricted.';
    }
    if (message.contains('role-not-configured')) {
      return 'Account has no role yet. Please contact admin.';
    }
    if (message.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    }
    return 'Login failed. Please try again.';
  }

  void _onForgotPassword() =>
      Navigator.of(context).pushNamed(AppRoutes.forgotPassword);

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
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

  // ── Image block ───────────────────────────────────────────────────
  Widget _buildImageBlock(ResponsiveHelper r) {
    final imageH = r.screenW * (563 / 938);
    final logoSize = (imageH * 0.38).clamp(56.0, 110.0);

    return SizedBox(
      width: r.screenW,
      height: imageH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/auth_bg.png',
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => Container(color: DAColors.greenDark),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: r.scale(12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/da_logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _FallbackLogo(size: logoSize),
                  ),
                  SizedBox(height: r.scale(6)),
                  Text(
                    'AGRI-TRACK',
                    style: DATextStyles.brandDisplay(
                      fontSize: r.scaleFont(44),
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
          r.scale(20),
          r.pageHPad,
          r.scale(32),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Login',
                style: GoogleFonts.poppins(
                  fontSize: r.scaleFont(30),
                  fontWeight: FontWeight.w800,
                  color: DAColors.greenDark,
                ),
              ),

              SizedBox(height: r.scale(4)),

              Text(
                'Sign in to continue',
                style: DATextStyles.bodyMd(
                  color: DAColors.textMid,
                  fontSize: r.scaleFont(13),
                ),
              ),

              SizedBox(height: r.scale(22)),

              // Email
              _FieldLabel(text: 'Email', r: r),
              SizedBox(height: r.scale(6)),
              _AuthTextField(
                controller: _emailCtrl,
                hint: 'Enter Email Address',
                keyboardType: TextInputType.emailAddress,
                r: r,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),

              SizedBox(height: r.scale(16)),

              // Password
              _FieldLabel(text: 'Password', r: r),
              SizedBox(height: r.scale(6)),
              _AuthTextField(
                controller: _passwordCtrl,
                hint: 'Enter Password',
                obscureText: _obscurePass,
                r: r,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: DAColors.textMuted,
                    size: r.scale(22),
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),

              SizedBox(height: r.scale(28)),

              _LoginButton(isLoading: _isLoading, onTap: _onLogin, r: r),

              SizedBox(height: r.scale(14)),

              GestureDetector(
                onTap: _onForgotPassword,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: r.scale(6)),
                  child: Text(
                    'Forgot Password',
                    style: GoogleFonts.poppins(
                      fontSize: r.scaleFont(13),
                      fontWeight: FontWeight.w500,
                      color: DAColors.greenMid,
                    ),
                  ),
                ),
              ),

              SizedBox(height: r.scale(10)),

              Text(
                'You stay signed in on this device until you log out.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: r.scaleFont(11),
                  fontWeight: FontWeight.w400,
                  color: DAColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Reusable widgets
// ═══════════════════════════════════════════════════════════════════

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.r});
  final String text;
  final ResponsiveHelper r;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: r.scaleFont(14),
          fontWeight: FontWeight.w600,
          color: DAColors.textDark,
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.r,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final ResponsiveHelper r;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: DATextStyles.fieldValue(fontSize: r.scaleFont(14)),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: DATextStyles.fieldHint(fontSize: r.scaleFont(14)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: DAColors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: r.scale(18),
          vertical: r.scale(16),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.scale(12)),
          borderSide: const BorderSide(color: DAColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.scale(12)),
          borderSide: const BorderSide(color: DAColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.scale(12)),
          borderSide: const BorderSide(color: DAColors.greenMid, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.scale(12)),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.scale(12)),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.isLoading,
    required this.onTap,
    required this.r,
  });

  final bool isLoading;
  final VoidCallback onTap;
  final ResponsiveHelper r;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: r.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: DAColors.amberLight,
          disabledBackgroundColor: DAColors.amberLight.withOpacity(0.7),
          foregroundColor: DAColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.scale(14)),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: r.scale(22),
                height: r.scale(22),
                child: const CircularProgressIndicator(
                  color: DAColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Login',
                style: GoogleFonts.poppins(
                  fontSize: r.scaleFont(15),
                  fontWeight: FontWeight.w700,
                  color: DAColors.white,
                  letterSpacing: 0.5,
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
      width: size,
      height: size,
      child: Center(
        child: Text(
          'DA',
          style: TextStyle(
            fontSize: size * 0.3,
            fontWeight: FontWeight.w800,
            color: DAColors.white,
          ),
        ),
      ),
    );
  }
}
