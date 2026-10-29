import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Supabase must be initialized in main.dart first.
  SupabaseClient get _supabase => Supabase.instance.client;

  // Log errors in debug mode only.
  void _logError(String operation, Object error) {
    if (kDebugMode) {
      debugPrint('AuthService [$operation]: $error');
    }
  }

  // ==========================================
  // 1. SIGN UP
  // ==========================================

  Future<String?> signUp(String email, String password, String name) async {
    final cleanEmail = email.trim();
    final cleanName = name.trim();

    if (cleanEmail.isEmpty || password.isEmpty || cleanName.isEmpty) {
      return 'Please fill in all required fields.';
    }

    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'name': cleanName},
      );

      // User created, email confirmation may be required.
      if (response.user != null || response.session != null) {
        return null;
      }

      return 'Signup could not be completed.';
    } on AuthException catch (e) {
      _logError('Sign Up', e.message);

      if (e.message.toLowerCase().contains('already registered')) {
        return 'Account already exists. Please login.';
      }

      return e.message;
    } catch (e) {
      _logError('Sign Up', e);
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ==========================================
  // 2. VERIFY EMAIL OTP
  // ==========================================

  Future<bool> confirmSignUp(String email, String confirmationCode) async {
    final cleanEmail = email.trim();
    final cleanCode = confirmationCode.trim();

    if (cleanEmail.isEmpty || cleanCode.isEmpty) {
      return false;
    }

    try {
      final AuthResponse response = await _supabase.auth.verifyOTP(
        email: cleanEmail,
        token: cleanCode,
        type: OtpType.email,
      );

      return response.user != null || response.session != null;
    } on AuthException catch (e) {
      _logError('Email Verification', e.message);
      return false;
    } catch (e) {
      _logError('Email Verification', e);
      return false;
    }
  }

  // ==========================================
  // 3. RESEND SIGNUP VERIFICATION CODE
  // ==========================================

  Future<void> resendCode(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      throw ArgumentError('Email is required.');
    }

    try {
      await _supabase.auth.resend(type: OtpType.signup, email: cleanEmail);
    } on AuthException catch (e) {
      _logError('Resend Code', e.message);
      rethrow;
    } catch (e) {
      _logError('Resend Code', e);
      rethrow;
    }
  }

  // ==========================================
  // 4. LOGIN
  // ==========================================

  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty || password.isEmpty) {
      return false;
    }

    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      return response.session != null;
    } on AuthException catch (e) {
      _logError('Login', e.message);
      return false;
    } catch (e) {
      _logError('Login', e);
      return false;
    }
  }

  // ==========================================
  // 5. LOGOUT
  // ==========================================

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      _logError('Logout', e.message);
      rethrow;
    } catch (e) {
      _logError('Logout', e);
      rethrow;
    }
  }

  // ==========================================
  // 6. RESET PASSWORD - SEND EMAIL
  // ==========================================

  Future<bool> resetPassword(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      return false;
    }

    try {
      await _supabase.auth.resetPasswordForEmail(cleanEmail);

      return true;
    } on AuthException catch (e) {
      _logError('Reset Password', e.message);
      return false;
    } catch (e) {
      _logError('Reset Password', e);
      return false;
    }
  }

  // ==========================================
  // 7. VERIFY RECOVERY OTP + UPDATE PASSWORD
  // ==========================================

  Future<bool> confirmResetPassword(
    String email,
    String newPassword,
    String code,
  ) async {
    final cleanEmail = email.trim();
    final cleanCode = code.trim();

    if (cleanEmail.isEmpty || newPassword.isEmpty || cleanCode.isEmpty) {
      return false;
    }

    try {
      // Verify the password recovery OTP.
      final AuthResponse response = await _supabase.auth.verifyOTP(
        email: cleanEmail,
        token: cleanCode,
        type: OtpType.recovery,
      );

      // Recovery verification must create a session.
      if (response.session == null) {
        return false;
      }

      // User is now authenticated for password update.
      final UserResponse updatedUser = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return updatedUser.user != null;
    } on AuthException catch (e) {
      _logError('Confirm Reset Password', e.message);
      return false;
    } catch (e) {
      _logError('Confirm Reset Password', e);
      return false;
    }
  }

  // ==========================================
  // 8. CHECK LOGIN STATUS
  // ==========================================

  bool isLoggedIn() {
    return _supabase.auth.currentSession != null;
  }

  // ==========================================
  // 9. GET CURRENT USER
  // ==========================================

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // ==========================================
  // 10. GET CURRENT ACCESS TOKEN
  // ==========================================

  // ==========================================
  // 11. UPDATE PASSWORD (AUTHENTICATED)
  // ==========================================

  Future<bool> updatePassword(String newPassword) async {
    final cleanPassword = newPassword.trim();
    if (cleanPassword.isEmpty || cleanPassword.length < 6) {
      return false;
    }

    try {
      final UserResponse response = await _supabase.auth.updateUser(
        UserAttributes(password: cleanPassword),
      );
      return response.user != null;
    } on AuthException catch (e) {
      _logError('Update Password', e.message);
      rethrow;
    } catch (e) {
      _logError('Update Password', e);
      rethrow;
    }
  }

  String? getAccessToken() {
    return _supabase.auth.currentSession?.accessToken;
  }
}
