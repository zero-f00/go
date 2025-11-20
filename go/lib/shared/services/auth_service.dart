import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../constants/app_strings.dart';
import 'avatar_service.dart';

/// Firebase Authentication Service
/// 公式ドキュメントに従った実装
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    print('🚀 AuthService: Initializing AuthService singleton...');
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    try {
      print('🔄 AuthService: Initializing Google Sign-In...');
      print('   - GoogleSignIn instance: $_googleSignIn');
      print('   - Configured scopes: ${_googleSignIn.scopes}');

      // Run diagnostics
      _runGoogleSignInDiagnostics();

      print('✅ AuthService: Google Sign-In initialization completed');
    } catch (e, stackTrace) {
      print('❌ AuthService: Error during Google Sign-In initialization: $e');
      print('❌ AuthService: Stack trace: $stackTrace');
    }
  }

  void _runGoogleSignInDiagnostics() {
    print('🔍 AuthService: Running Google Sign-In diagnostics...');

    try {
      // Check if GoogleService-Info.plist values are accessible
      print('🔍 Diagnostic: Checking platform configuration...');

      if (Platform.isIOS) {
        print('   - Platform: iOS (Google Sign-In should work)');
        print('   - Bundle ID should match GoogleService-Info.plist');
        print('   - URL scheme should be configured in Info.plist');
      }

      // Check if Firebase is initialized
      try {
        final currentUser = _auth.currentUser;
        print('   - Firebase Auth: ${currentUser != null ? 'User signed in' : 'No user signed in'}');
        print('   - Firebase Auth instance: $_auth');
      } catch (e) {
        print('   - Firebase Auth error: $e');
      }

      print('✅ Diagnostics completed');
    } catch (e) {
      print('❌ Diagnostic error: $e');
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
      print('🚀 AuthService: Google Sign-In method called');
      print('🔄 AuthService: Starting Google Sign-In...');

      // Check GoogleSignIn instance
      print('🔍 AuthService: Checking GoogleSignIn instance...');
      print('   - _googleSignIn: $_googleSignIn');
      print('   - _googleSignIn.runtimeType: ${_googleSignIn.runtimeType}');
      print('   - _googleSignIn.scopes: ${_googleSignIn.scopes}');

      // Check platform and environment
      print('📱 Platform info:');
      print('   - iOS: ${Platform.isIOS}');
      print('   - Debug mode: ${kDebugMode}');
      print('   - Platform: ${defaultTargetPlatform}');

      // Check current user state
      print('🔍 AuthService: Checking current Google user state...');
      try {
        final currentUser = _googleSignIn.currentUser;
        print('   - Current Google User: ${currentUser?.email ?? 'null'}');
      } catch (e) {
        print('   - Error getting current user: $e');
      }

      // Trigger the authentication flow
      print('🔄 AuthService: About to call GoogleSignIn.signIn()...');
      print('   - This is where crashes often occur in Google Sign-In');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('✅ AuthService: GoogleSignIn.signIn() completed without crashing');

      if (googleUser == null) {
        print('ℹ️ AuthService: User canceled Google Sign-In');
        return null; // User canceled the sign-in
      }

      print('✅ AuthService: Google user selected: ${googleUser.email}');
      print('   - Display Name: ${googleUser.displayName}');
      print('   - Photo URL: ${googleUser.photoUrl}');
      print('   - ID: ${googleUser.id}');

      // Obtain the auth details from the request
      print('🔄 AuthService: Getting Google authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('✅ AuthService: Google authentication details received');
      print('   - Access Token exists: ${googleAuth.accessToken != null}');
      print('   - ID Token exists: ${googleAuth.idToken != null}');

      // Validate required tokens
      if (googleAuth.accessToken == null) {
        print('❌ AuthService: accessToken is null - this will cause Firebase sign-in failure');
        throw Exception('Google Sign-In failed: No access token received');
      }

      if (googleAuth.idToken == null) {
        print('❌ AuthService: idToken is null - this will cause Firebase sign-in failure');
        throw Exception('Google Sign-In failed: No ID token received');
      }

      // Create a new credential
      print('🔄 AuthService: Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔄 AuthService: Signing in to Firebase with Google credential...');
      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ AuthService: Firebase Google Sign-In successful: ${userCredential.user?.email}');

      return userCredential;
    } catch (e, stackTrace) {
      print('❌ AuthService: Google Sign In Error: $e');
      print('❌ AuthService: Error Type: ${e.runtimeType}');

      // Specific error handling for common Google Sign-In errors
      if (e.toString().contains('network_error')) {
        print('❌ AuthService: Network error - check internet connection');
      } else if (e.toString().contains('sign_in_canceled')) {
        print('❌ AuthService: User canceled sign-in');
      } else if (e.toString().contains('sign_in_failed')) {
        print('❌ AuthService: Sign-in failed - check Google Services configuration');
      } else {
        print('❌ AuthService: Unknown Google Sign-In error');
        print('   - This error will cause null return from signInWithGoogle()');
      }

      print('❌ AuthService: Stack trace: $stackTrace');
      print('❌ AuthService: Returning null due to exception');
      return null;
    }
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      print('🔄 AuthService: Starting Apple Sign-In...');

      // Check platform and environment
      print('📱 Platform info:');
      print('   - iOS: ${Platform.isIOS}');
      print('   - Debug mode: ${kDebugMode}');
      print('   - Platform: ${defaultTargetPlatform}');

      // Check if Apple Sign-In is available
      if (!(await SignInWithApple.isAvailable())) {
        print('❌ AuthService: Apple Sign-In is not available on this device');
        print('❌ AuthService: This will cause null return - isAvailable() returned false');
        throw Exception('Apple Sign-In is not available on this device');
      }

      print('✅ AuthService: Apple Sign-In is available, requesting credential...');

      // Simulator warning and handling
      if (kDebugMode) {
        print('⚠️  Note: Running in debug mode - Apple Sign-In may have limitations in simulator');
        print('⚠️  Common simulator issues:');
        print('   - Error 1000: Authorization failed (expected in simulator)');
        print('   - Error 1001: User canceled (user action)');
        print('   - This feature typically works only on real devices with Apple ID signed in');
      }

      // Request Apple ID credential
      print('🔄 AuthService: Calling SignInWithApple.getAppleIDCredential...');
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      print('✅ AuthService: Apple ID credential received');
      print('   - identityToken exists: ${appleCredential.identityToken != null}');
      print('   - authorizationCode exists: ${appleCredential.authorizationCode != null}');
      print('   - userIdentifier: ${appleCredential.userIdentifier}');
      print('   - givenName: ${appleCredential.givenName}');
      print('   - familyName: ${appleCredential.familyName}');
      print('   - email: ${appleCredential.email}');

      // Validate required credentials
      if (appleCredential.identityToken == null) {
        print('❌ AuthService: identityToken is null - this will cause null return');
        throw Exception('Apple Sign-In failed: No identity token received');
      }

      if (appleCredential.authorizationCode == null) {
        print('❌ AuthService: authorizationCode is null - this will cause null return');
        throw Exception('Apple Sign-In failed: No authorization code received');
      }

      // Create OAuth credential
      print('🔄 AuthService: Creating Firebase OAuth credential...');
      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      print('🔄 AuthService: Signing in to Firebase with Apple credential...');
      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oAuthCredential);
      print('✅ AuthService: Firebase Apple Sign-In successful: ${userCredential.user?.email}');

      return userCredential;
    } catch (e, stackTrace) {
      print('❌ AuthService: Apple Sign In Error: $e');
      print('❌ AuthService: Error Type: ${e.runtimeType}');

      // Specific error handling for common Apple Sign-In errors
      if (e.toString().contains('1000')) {
        print('❌ AuthService: Error 1000 - Authorization failed');
        print('   - This typically occurs in iOS Simulator');
        print('   - Apple Sign-In requires real device with signed-in Apple ID');
        print('   - This is expected behavior in simulator environment');
      } else if (e.toString().contains('1001')) {
        print('❌ AuthService: Error 1001 - User canceled');
        print('   - User canceled the Apple Sign-In process');
      } else {
        print('❌ AuthService: Unknown Apple Sign-In error');
        print('   - This error will cause null return from signInWithApple()');
      }

      print('❌ AuthService: Stack trace: $stackTrace');
      print('❌ AuthService: Returning null due to exception');
      return null;
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      print('🔄 AuthService: Starting sign out process');

      // Clear avatar cache
      print('🗑️ AuthService: Clearing avatar cache');
      await AvatarService.instance.deleteAvatar();
      print('✅ AuthService: Avatar cache cleared');

      // Sign out from Google
      print('🔄 AuthService: Signing out from Google');
      await _googleSignIn.signOut();
      print('✅ AuthService: Google sign out completed');

      // Sign out from Firebase
      print('🔄 AuthService: Signing out from Firebase');
      await _auth.signOut();
      print('✅ AuthService: Firebase sign out completed');

      print('✅ AuthService: Sign out process completed');
    } catch (e) {
      print('❌ AuthService: Sign Out Error: $e');
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
}