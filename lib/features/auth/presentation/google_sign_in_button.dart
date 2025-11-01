import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// This is the global variable we created in main.dart
final supabase = Supabase.instance.client;

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    // 1. Start the Google Sign-In process
    // (VERY IMPORTANT: serverClientId is the Web client ID, not the Android one)
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: '619636674820-819kohgffbhd1betkosn1a6fe5ve1kui.apps.googleusercontent.com',
    );

    // Force the account picker to always be displayed
    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      // The user canceled the sign-in process
      print('Google sign in was cancelled.');
      return;
    }

    // 2. Get the authentication data
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final String? accessToken = googleAuth.accessToken;
    final String? idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'Google sign in failed: No Access Token found.';
    }
    if (idToken == null) {
      throw 'Google sign in failed: No ID Token found.';
    }

    // 3. Sign in to Supabase with the token
    final AuthResponse res = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    if (res.user != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بنجاح!')),
      );
      context.go('/home');
    }

  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during Google sign in: $error')),
      );
    }
    print('Error during Google sign in: $error');
  }
}

// ----------------------------------------------------
// (Example of how to call the function from a button)
// ----------------------------------------------------
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => signInWithGoogle(context),
      icon: Image.asset(
        "assets/images/google.png",
        height: 24,
        width: 24,
      ),
      label: const Text(
        "تسجيل الدخول باستخدام Google",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87, // Dark text for contrast
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // White background
        foregroundColor: Colors.black, // Dark foreground for ripple effect
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        side: const BorderSide(
          color: Colors.grey, // Light grey border
          width: 1,
        ),
        shadowColor: Colors.black12,
        elevation: 2,
      ),
    );
  }
}
