import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  bool  _obscurePass    = true;
  bool  _isLoading      = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated!',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: DAColors.greenMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: DAColors.textDark)),
        content: Text('Are you sure you want to logout?',
          style: GoogleFonts.poppins(
              fontSize: 14, color: DAColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: DAColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (r) => false);
            },
            child: Text('Logout',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;
    final topPad  = mq.padding.top;
    final botPad  = mq.padding.bottom;
    final navH    = kBottomNavigationBarHeight + botPad;
    final totalH  = screenH - topPad - navH;

    const overlap = 20.0;
    final imageH  = totalH * 0.22;
    final hPad    = screenW * 0.048;

    const fieldBr = BorderRadius.all(Radius.circular(14));

    InputDecoration deco(String hint, {Widget? suffix}) => InputDecoration(
      hintText:   hint,
      hintStyle:  GoogleFonts.poppins(
          fontSize: 14, color: DAColors.textMuted),
      suffixIcon: suffix,
      filled:     true,
      fillColor:  Colors.white,
      isDense:    true,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: fieldBr,
          borderSide: const BorderSide(
              color: Color(0xFFDDDDDD), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: fieldBr,
          borderSide: const BorderSide(
              color: Color(0xFFDDDDDD), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: fieldBr,
          borderSide: const BorderSide(
              color: DAColors.greenMid, width: 2.0)),
      errorBorder: OutlineInputBorder(borderRadius: fieldBr,
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: fieldBr,
          borderSide: const BorderSide(color: Colors.red, width: 2.0)),
    );

    Widget lbl(String t) => Text(t,
      style: GoogleFonts.poppins(
        fontSize:   14,
        fontWeight: FontWeight.w700,
        color:      DAColors.textDark,
      ),
    );

    Widget fld({
      required TextEditingController ctrl,
      required String hint,
      bool obscure = false,
      TextInputType kb = TextInputType.text,
      Widget? suffix,
      String? Function(String?)? validator,
    }) =>
        TextFormField(
          controller:   ctrl,
          obscureText:  obscure,
          keyboardType: kb,
          style: GoogleFonts.poppins(
              fontSize: 14, color: DAColors.textDark),
          validator:  validator,
          decoration: deco(hint, suffix: suffix),
        );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor:          const Color(0xFFF2F2F2),
      resizeToAvoidBottomInset: false,

      // ── Buttons fixed at bottom ──────────────────────────────────
      bottomNavigationBar: Container(
        color: const Color(0xFFF2F2F2),
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, botPad + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Save Changes
          SizedBox(
            height: 52, width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: DAColors.greenMid,
                disabledBackgroundColor: DAColors.greenMid.withOpacity(0.7),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: DAColors.white, strokeWidth: 2.5),
                    )
                  : Text('Save Changes',
                      style: GoogleFonts.poppins(
                        fontSize:      15,
                        fontWeight:    FontWeight.w700,
                        color:         DAColors.white,
                        letterSpacing: 0.5,
                      )),
            ),
          ),
          const SizedBox(height: 10),

          // Logout
          SizedBox(
            height: 52, width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded,
                  color: Colors.white, size: 20),
              label: Text('Logout',
                style: GoogleFonts.poppins(
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                  color:      Colors.white,
                )),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ]),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          SizedBox(height: topPad),

          // ── Image header ─────────────────────────────────────────
          SizedBox(
            height: imageH,
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
                      begin:  Alignment.topCenter,
                      end:    Alignment.bottomCenter,
                      colors: [
                        DAColors.greenDark.withOpacity(0.88),
                        DAColors.greenMid.withOpacity(0.75),
                        DAColors.greenLight.withOpacity(0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SETTINGS',
                      style: GoogleFonts.bebasNeue(
                        fontSize:      (imageH * 0.32).clamp(24.0, 36.0),
                        color:         DAColors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: imageH * 0.04),
                    Text('Manage your personal information',
                      style: GoogleFonts.poppins(
                        fontSize:  (imageH * 0.09).clamp(10.0, 13.0),
                        fontStyle: FontStyle.italic,
                        color:     DAColors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable card ──────────────────────────────────────
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -overlap),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                        (screenW * 0.07).clamp(20.0, 32.0)),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text('Edit Profile',
                          style: GoogleFonts.poppins(
                            fontSize:   18,
                            fontWeight: FontWeight.w800,
                            color:      DAColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 20),

                        lbl('First Name'),
                        const SizedBox(height: 8),
                        fld(ctrl: _firstNameCtrl, hint: 'Enter First Name',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required' : null),

                        const SizedBox(height: 14),
                        lbl('Middle Name'),
                        const SizedBox(height: 8),
                        fld(ctrl: _middleNameCtrl,
                            hint: 'Enter Middle Name'),

                        const SizedBox(height: 14),
                        lbl('Last Name'),
                        const SizedBox(height: 8),
                        fld(ctrl: _lastNameCtrl, hint: 'Enter Last Name',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required' : null),

                        const SizedBox(height: 14),
                        lbl('Email'),
                        const SizedBox(height: 8),
                        fld(ctrl: _emailCtrl,
                          hint: 'Enter Email Address',
                          kb:   TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          }),

                        const SizedBox(height: 14),
                        lbl('Password'),
                        const SizedBox(height: 8),
                        fld(ctrl: _passwordCtrl,
                          hint:    'Enter Password',
                          obscure: _obscurePass,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: DAColors.textMuted,
                              size:  20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePass = !_obscurePass),
                          ),
                          validator: (v) {
                            if (v != null &&
                                v.isNotEmpty &&
                                v.length < 6) {
                              return 'Min 6 characters';
                            }
                            return null;
                          }),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}