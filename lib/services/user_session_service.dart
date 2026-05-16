import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'connectivity_service.dart';

enum UserRole {
  profiler,
  moderator,
  admin,
  unknown,
}

class UserSession {
  const UserSession({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;

  bool get isProfiler => role == UserRole.profiler;
  bool get isModerator => role == UserRole.moderator || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;
}

class UserSessionService {
  UserSessionService._();

  static final UserSessionService instance = UserSessionService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Duration _sessionCacheTtl = Duration(seconds: 20);

  UserSession? _cachedSession;
  DateTime? _cachedSessionAt;
  Future<UserSession?>? _inFlightSessionFuture;

  late final Stream<UserSession?> _sessionStream =
      _auth.authStateChanges().asyncMap((user) async {
    _cachedSession = null;
    _cachedSessionAt = null;
    return _resolveSession(user);
  }).asBroadcastStream();

  Stream<UserSession?> get sessionStream => _sessionStream;

  User? get currentUser => _auth.currentUser;

  Future<UserSession?> getCurrentSession() async {
    final currentUid = _auth.currentUser?.uid;
    if (_cachedSession != null &&
        _cachedSessionAt != null &&
        _cachedSession!.uid == currentUid &&
        DateTime.now().difference(_cachedSessionAt!) <= _sessionCacheTtl) {
      return _cachedSession;
    }

    if (_inFlightSessionFuture != null) {
      return _inFlightSessionFuture;
    }

    _inFlightSessionFuture = _resolveSession(_auth.currentUser);
    try {
      return await _inFlightSessionFuture;
    } finally {
      _inFlightSessionFuture = null;
    }
  }

  Future<UserSession> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Sign in with timeout to prevent hanging
    await _auth
        .signInWithEmailAndPassword(
          email: email,
          password: password,
        )
        .timeout(const Duration(seconds: 10));

    // Get session with fallback to offline mode
    final session = await getCurrentSession();
    if (session == null) {
      final current = _auth.currentUser;
      if (current != null) {
        // ✅ Check actual internet before deciding if truly offline
        final hasInternet =
            await ConnectivityService.instance.hasInternetConnection();

        if (!hasInternet) {
          print('🔴 [SignIn] No internet - building offline session');
          return _buildOfflineSession(current);
        }

        // Has internet but session lookup failed
        print(
            '🟡 [SignIn] Internet OK but session lookup failed - building fallback session');
        return _buildOfflineSession(current);
      }
      throw FirebaseAuthException(
        code: 'session-unavailable',
        message: 'Failed to build authenticated session.',
      );
    }

    return session;
  }

  Future<void> signOut() {
    _cachedSession = null;
    _cachedSessionAt = null;
    _inFlightSessionFuture = null;
    return _auth.signOut();
  }

  Future<UserSession?> _resolveSession(User? user) async {
    try {
      final session = await _buildApprovedSession(user);
      _cachedSession = session;
      _cachedSessionAt = DateTime.now();
      return session;
    } catch (error) {
      // ✅ Only treat as offline if device has NO internet connection
      // Firebase errors might happen even with internet (auth issues, rules, timeouts)
      if (_isOfflineError(error)) {
        final hasInternet =
            await ConnectivityService.instance.hasInternetConnection();

        if (!hasInternet) {
          // TRUE offline - no internet at all
          print('🔴 [Session] No internet connection - entering offline mode');
          if (user != null) {
            final offline = _buildOfflineSession(user);
            _cachedSession = offline;
            _cachedSessionAt = DateTime.now();
            return offline;
          }
        } else {
          // Has internet but Firebase failed - might be temporary
          print(
              '🟡 [Session] Firebase unavailable but internet exists - using cached/fallback session');

          // Return cached session if available
          if (_cachedSession != null) {
            return _cachedSession;
          }

          // Or build offline session if we have user data
          if (user != null) {
            final fallback = _buildOfflineSession(user);
            _cachedSession = fallback;
            _cachedSessionAt = DateTime.now();
            return fallback;
          }
        }
      }

      _cachedSession = null;
      _cachedSessionAt = null;
      return null;
    }
  }

  Future<UserSession?> _buildApprovedSession(User? user) async {
    if (user == null) return null;

    print('🔵 [Auth] Verifying account: ${user.email} (UID: ${user.uid})');

    DocumentSnapshot<Map<String, dynamic>>? doc;
    try {
      print('🔵 [Auth] Fetching user document from Firestore...');
      doc = await _getUserDoc(user.uid);
      print('✅ [Auth] User document fetched successfully');
    } catch (error) {
      // ✅ Check if we actually have internet before deciding to downgrade
      final hasInternet =
          await ConnectivityService.instance.hasInternetConnection();

      if (!hasInternet) {
        // No internet - allow fallback to offline session
        print(
            '⚠️ [Session] Firebase unreachable and no internet - using fallback');
        return _buildOfflineSession(user);
      }

      // Has internet but can't reach Firebase (might be temp issue)
      print(
          '⚠️ [Session] Firebase error but internet available - using fallback: $error');
      return _buildOfflineSession(user);
    }

    if (!doc.exists) {
      // Allow valid Firebase Auth users even without profile doc.
      print('⚠️ [Auth] No user document in Firestore, using offline session');
      return _buildOfflineSession(user);
    }

    final data = doc.data() ?? <String, dynamic>{};
    print('🔵 [Auth] User document data: $data');

    final approved = _isApproved(data);
    print('🔵 [Auth] Account approved: $approved');

    if (!approved) {
      print('❌ [Auth] Account NOT approved - throwing error');
      throw FirebaseAuthException(
        code: 'account-not-approved',
        message: 'Account is pending admin approval.',
      );
    }

    final rawRole = data['role'] as String?;
    print('🔵 [Auth] Raw role from document: "$rawRole"');

    final role = _roleFromRaw(rawRole);
    print('🔵 [Auth] Parsed role: $role');

    final resolvedRole = role == UserRole.unknown ? UserRole.profiler : role;
    print('✅ [Auth] Final resolved role: $resolvedRole');

    final fallbackName = user.email?.split('@').first ?? 'User';
    final displayNameFromDoc = _displayNameFromData(data);
    final resolvedDisplayName =
        (displayNameFromDoc != null && displayNameFromDoc.isNotEmpty)
            ? displayNameFromDoc
            : ((user.displayName?.trim().isNotEmpty ?? false)
                ? user.displayName!.trim()
                : fallbackName);

    print(
        '✅ [Auth] Login successful! Role: $resolvedRole, Display Name: $resolvedDisplayName');

    return UserSession(
      uid: user.uid,
      email: user.email ?? '',
      displayName: resolvedDisplayName,
      role: resolvedRole,
    );
  }

  UserSession _buildOfflineSession(User user) {
    final fallbackName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email?.split('@').first ?? 'User');

    return UserSession(
      uid: user.uid,
      email: user.email ?? '',
      displayName: fallbackName,
      role: UserRole.unknown,
    );
  }

  UserRole _roleFromRaw(String? rawRole) {
    switch (rawRole?.trim().toLowerCase()) {
      case 'profiler':
      case 'profier':
        return UserRole.profiler;
      case 'moderator':
        return UserRole.moderator;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  String? _displayNameFromData(Map<String, dynamic> data) {
    final displayName = (data['displayName'] as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final middleName = (data['middleName'] as String?)?.trim() ?? '';
    final lastName = (data['lastName'] as String?)?.trim() ??
        (data['surname'] as String?)?.trim() ??
        '';

    final fullName = [firstName, middleName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();

    return fullName.isEmpty ? null : fullName;
  }

  bool _isApproved(Map<String, dynamic> data) {
    final approvedRaw = data['approved'];
    if (approvedRaw is bool) return approvedRaw;
    if (approvedRaw is String) {
      final normalized = approvedRaw.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }

    final statusRaw = (data['status'] as String?)?.trim().toLowerCase();
    if (statusRaw == 'approved') return true;
    if (statusRaw == 'pending' || statusRaw == 'rejected') return false;

    final accountStatusRaw =
        (data['accountStatus'] as String?)?.trim().toLowerCase();
    if (accountStatusRaw == 'approved') return true;
    if (accountStatusRaw == 'pending' || accountStatusRaw == 'rejected') {
      return false;
    }

    final approvalStatusRaw =
        (data['approvalStatus'] as String?)?.trim().toLowerCase();
    if (approvalStatusRaw == 'approved') return true;
    if (approvalStatusRaw == 'pending' || approvalStatusRaw == 'rejected') {
      return false;
    }

    // Backward compatibility: if no explicit approval fields exist,
    // treat the account as allowed.
    return true;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc(String uid) async {
    final ref = _firestore.collection('users').doc(uid);

    // Try cache first for speed, then fall back to server if needed
    try {
      // First try cache with a short timeout
      final cacheDoc = await ref
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(milliseconds: 500));

      if (cacheDoc.exists) {
        return cacheDoc;
      }
    } catch (_) {
      // Cache miss or timeout, continue to server fetch
    }

    // If cache fails, fetch from server with timeout
    return ref
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 5));
  }

  bool _isOfflineError(Object error) {
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      if (code == 'unavailable' || code == 'network-request-failed') {
        return true;
      }
    }

    final message = error.toString().toLowerCase();
    return message.contains('network-request-failed') ||
        message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('unavailable') ||
        message.contains('network is unreachable');
  }
}
