import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../constants/app_strings.dart';
import 'avatar_service.dart';
import 'event_reminder_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Authentication Service
/// 公式ドキュメントに従った実装
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    try {
      // Google Sign-In initialization (silent)
    } catch (e, stackTrace) {
    }
  }


  // Firebase Auth instance
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Current user
  User? get currentUser => _auth.currentUser;

  // Authentication state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Google Sign In provider instance with explicit configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Explicitly specify scopes if needed
    scopes: [
      'email',
      'profile',
    ],
  );

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {

      // Check GoogleSignIn instance

      // Check platform and environment

      // Check current user state
      try {
        final currentUser = _googleSignIn.currentUser;
      } catch (e) {
      }

      // Trigger the authentication flow

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User canceled the sign-in
      }


      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;


      // Validate required tokens
      if (googleAuth.accessToken == null) {
        throw Exception('Google Sign-In failed: No access token received');
      }

      if (googleAuth.idToken == null) {
        throw Exception('Google Sign-In failed: No ID token received');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // サインイン成功後の処理
      await _onSignInSuccess();

      return userCredential;
    } catch (e, stackTrace) {

      // Specific error handling for common Google Sign-In errors
      if (e.toString().contains('network_error')) {
      } else if (e.toString().contains('sign_in_canceled')) {
      } else if (e.toString().contains('sign_in_failed')) {
      } else {
      }

      return null;
    }
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {

      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();

      if (!isAvailable) {
        throw Exception('Apple Sign-In is not available on this device');
      }

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );


      // Validate required credentials
      if (appleCredential.identityToken == null) {
        throw Exception('Apple Sign-In failed: No identity token received');
      }

      if (appleCredential.authorizationCode == null) {
        throw Exception('Apple Sign-In failed: No authorization code received');
      }

      // Create OAuth credential
      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oAuthCredential);

      // サインイン成功後の処理
      await _onSignInSuccess();

      return userCredential;
    } catch (e) {
      // Silent error handling - no logging in production
      return null;
    }
  }

  /// サインイン成功後の共通処理
  Future<void> _onSignInSuccess() async {
    try {
      // イベントリマインダーサービスを開始
      EventReminderService.instance.startReminderService();
    } catch (e) {
      // Silent error handling
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      // イベントリマインダーサービスを停止
      EventReminderService.instance.stopReminderService();

      // Clear FCM token before signing out
      final user = currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
        });
      }

      // Clear avatar cache
      await AvatarService.instance.deleteAvatar();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _auth.signOut();

    } catch (e) {
    }
  }

  /// Get display name for current user
  String getDisplayName() {
    final user = currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return AppStrings.guestUser;
  }

  /// Get photo URL for current user
  String? getPhotoUrl() {
    return currentUser?.photoURL;
  }

  /// Get user ID
  String getUserId() {
    return currentUser?.uid ?? 'guest_001';
  }

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Record terms of service acceptance
  Future<void> recordTermsAcceptance() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      await firestore.collection('users').doc(user.uid).set({
        'termsAccepted': true,
        'termsVersion': '2025-12-08', // Current version
        'termsAcceptedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

    } catch (e) {
      // 規約同意の記録失敗は無視
    }
  }
}