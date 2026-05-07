import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_session_service.dart';
import '../../services/pending_draft_service.dart';
import '../../theme/da_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isProfileLoading = true;
  String _originalEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _isProfileLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? <String, dynamic>{};

      final firstName = (data['firstName'] as String?)?.trim() ?? '';
      final middleName = (data['middleName'] as String?)?.trim() ?? '';
      final lastName = ((data['lastName'] as String?)?.trim() ??
          (data['surname'] as String?)?.trim() ??
          '');
      final email = (data['email'] as String?)?.trim() ?? user.email ?? '';

      if (!mounted) return;
      setState(() {
        _firstNameCtrl.text = firstName;
        _middleNameCtrl.text = middleName;
        _lastNameCtrl.text = lastName;
        _emailCtrl.text = email;
        _originalEmail = email;
        _isProfileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active user session.',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      final nextEmail = _emailCtrl.text.trim();

      if (nextEmail != _originalEmail) {
        await user.updateEmail(nextEmail);
        _originalEmail = nextEmail;
      }

      final firstName = _firstNameCtrl.text.trim();
      final middleName = _middleNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final fullName = [firstName, middleName, lastName]
          .where((part) => part.isNotEmpty)
          .join(' ')
          .trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'uid': user.uid,
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'surname': lastName,
          'displayName': fullName,
          'email': nextEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated!',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: DAColors.greenMid,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message = 'Unable to update account.';
      if (error.code == 'requires-recent-login') {
        message = 'Please log out and log in again before updating email.';
      } else if (error.code == 'email-already-in-use') {
        message = 'Email is already in use by another account.';
      } else if (error.code == 'invalid-email') {
        message = 'Invalid email format.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update account.',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _confirmClearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All Data',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DAColors.textDark)),
        content: Text(
            'This will permanently delete all saved drafts and local data. This action cannot be undone. Are you sure?',
            style:
                GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DAColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            child: Text('Clear All',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      // Import the service at the top if not already imported
      // For now, we'll access it directly
      await PendingDraftService.instance.clearAllDrafts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All data cleared successfully!',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: DAColors.greenMid,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear data: $error',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DAColors.textDark)),
        content: Text('Are you sure you want to logout?',
            style:
                GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DAColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              UserSessionService.instance.signOut().then((_) {
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (r) => false);
              });
            },
            child: Text('Logout',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;
    final topPad = mq.padding.top;
    final botPad = mq.padding.bottom;
    final navH = kBottomNavigationBarHeight + botPad;
    final totalH = screenH - topPad - navH;

    const overlap = 20.0;
    final imageH = totalH * 0.22;
    final hPad = screenW * 0.048;

    const fieldBr = BorderRadius.all(Radius.circular(14));

    InputDecoration deco(String hint, {Widget? suffix}) => InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: const OutlineInputBorder(
              borderRadius: fieldBr,
              borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
          enabledBorder: const OutlineInputBorder(
              borderRadius: fieldBr,
              borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
          focusedBorder: const OutlineInputBorder(
              borderRadius: fieldBr,
              borderSide: BorderSide(color: DAColors.greenMid, width: 2.0)),
          errorBorder: const OutlineInputBorder(
              borderRadius: fieldBr,
              borderSide: BorderSide(color: Colors.red, width: 1.5)),
          focusedErrorBorder: const OutlineInputBorder(
              borderRadius: fieldBr,
              borderSide: BorderSide(color: Colors.red, width: 2.0)),
        );

    Widget lbl(String t) => Text(
          t,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DAColors.textDark,
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
          controller: ctrl,
          obscureText: obscure,
          keyboardType: kb,
          enabled: !_isLoading && !_isProfileLoading,
          style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
          validator: validator,
          decoration: deco(hint, suffix: suffix),
        );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: Container(
        color: const Color(0xFFF2F2F2),
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, botPad + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _isProfileLoading ? null : _onSave,
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
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: DAColors.white, strokeWidth: 2.5),
                    )
                  : Text('Save Changes',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DAColors.white,
                        letterSpacing: 0.5,
                      )),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmClearAllData(context),
              icon: const Icon(Icons.delete_forever_rounded,
                  color: Colors.white, size: 20),
              label: Text('Clear All Data',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded,
                  color: Colors.white, size: 20),
              label: Text('Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
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
                    Text(
                      'SETTINGS',
                      style: GoogleFonts.bebasNeue(
                        fontSize: (imageH * 0.32).clamp(24.0, 36.0),
                        color: DAColors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: imageH * 0.04),
                    Text(
                      'Manage your personal information',
                      style: GoogleFonts.poppins(
                        fontSize: (imageH * 0.09).clamp(10.0, 13.0),
                        fontStyle: FontStyle.italic,
                        color: DAColors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -overlap),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular((screenW * 0.07).clamp(20.0, 32.0)),
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
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: DAColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isProfileLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: DAColors.greenMid,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        lbl('First Name'),
                        const SizedBox(height: 8),
                        fld(
                            ctrl: _firstNameCtrl,
                            hint: 'Enter First Name',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null),
                        const SizedBox(height: 14),
                        lbl('Middle Name'),
                        const SizedBox(height: 8),
                        fld(ctrl: _middleNameCtrl, hint: 'Enter Middle Name'),
                        const SizedBox(height: 14),
                        lbl('Last Name'),
                        const SizedBox(height: 8),
                        fld(
                            ctrl: _lastNameCtrl,
                            hint: 'Enter Last Name',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null),
                        const SizedBox(height: 14),
                        lbl('Email'),
                        const SizedBox(height: 8),
                        fld(
                            ctrl: _emailCtrl,
                            hint: 'Enter Email Address',
                            kb: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              if (!v.contains('@')) return 'Invalid email';
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
