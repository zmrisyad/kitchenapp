import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class LoginController {
  static Future<String?> loginWithEmail(String email, String password) async {
    final baseUrl = dotenv.env['API_URL'] ?? '';
    final url = Uri.parse('$baseUrl/api/login');

    final requestBody = {'email': email.trim(), 'password': password};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['result']['auth_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data['error'] ?? 'Login failed';
      }
    } catch (_) {
      return 'Unable to connect to server';
    }
  }

  static Future<String?> loginWithGoogle() async {
    try {
      final googleSignIn = Platform.isAndroid
          ? GoogleSignIn(
              clientId: dotenv.env['GOOGLE_CLIENT_ID'],
              scopes: ['email', 'profile'],
            )
          : GoogleSignIn(scopes: ['email', 'profile']);

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled
        return null;
      }

      // Get user info
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase to confirm identity
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Prepare user info for server
      final email = googleUser.email;
      final displayName = googleUser.displayName ?? '';
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final baseUrl = dotenv.env['API_URL'] ?? '';
      final url = Uri.parse('$baseUrl/api/login-google');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body)['error'] ?? 'Login failed';
        return error;
      }

      final data = jsonDecode(response.body);
      final token = data['result']['auth_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      return null; // success
    } catch (e) {
      return 'Google Sign-In failed: $e';
    }
  }
}
