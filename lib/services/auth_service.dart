import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  
  // 1. SIGN UP (Handles "User Already Exists" automatically)
  Future<String?> signUp(String email, String password, String name) async {
    try {
      final userAttributes = {
        AuthUserAttributeKey.email: email,
        AuthUserAttributeKey.name: name,
      };

      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );

      if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
        return null; // SUCCESS
      } else {
        return "Signup not complete. Step: ${result.nextStep.signUpStep}";
      }
      
    } on AuthException catch (e) {
      // If user exists but is unconfirmed, resend code
      if (e.message.contains('already exists')) {
        try {
          await Amplify.Auth.resendSignUpCode(username: email);
          return null; 
        } on AuthException { 
          return "Account already exists. Please Log In.";
        }
      }
      print('❌ AWS Error: ${e.message}');
      return e.message; 
    } catch (e) {
      print('❌ Unknown Error: $e');
      return "An unknown error occurred.";
    }
  }

  // 2. CONFIRM EMAIL
  Future<bool> confirmSignUp(String email, String confirmationCode) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );
      return result.isSignUpComplete;
    } on AuthException catch (e) {
      print('Confirmation Error: ${e.message}');
      return false;
    }
  }

  // 3. RESEND CODE
  Future<void> resendCode(String email) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: email);
    } on AuthException catch (e) {
      print('Resend Error: ${e.message}');
    }
  }

  // 4. LOGIN (Fixed: Handles "Already Signed In" error)
  Future<bool> login(String email, String password) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      return result.isSignedIn;
    } on AuthException catch (e) {
      
      // FIX: If a user is already signed in, sign them out first!
      if (e.message.contains('already signed in')) {
        await Amplify.Auth.signOut(); // Log out the old session
        return login(email, password); // Try logging in again immediately
      }

      print('Login Error: ${e.message}');
      return false;
    }
  }

  // 5. LOGOUT
  Future<void> logout() async {
    try {
      await Amplify.Auth.signOut();
    } on AuthException catch (e) {
      print('Logout Error: ${e.message}');
    }
  }

// 6. RESET PASSWORD (Send Code) - FIXED
  Future<bool> resetPassword(String email) async {
    try {
      final result = await Amplify.Auth.resetPassword(username: email);
      
      return result.nextStep.updateStep == AuthResetPasswordStep.confirmResetPasswordWithCode;
      
    } on AuthException catch (e) {
      print('Reset Password Error: ${e.message}');
      return false;
    }
  }

  // 7. CONFIRM NEW PASSWORD
  Future<bool> confirmResetPassword(String email, String newPassword, String code) async {
    try {
      final result = await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: code,
      );
      return result.isPasswordReset; 
    } on AuthException catch (e) {
      print('Confirm Reset Error: ${e.message}');
      return false;
    }
  }
}