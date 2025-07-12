import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:welcome/core/utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _submitted = false;

  final _fieldTextStyle = const TextStyle(fontSize: 16);
  final _contentPadding = const EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 12,
  );
  final _borderRadius = BorderRadius.all(Radius.circular(6));

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _submitted = true;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    final baseUrl = dotenv.env['API_URL'] ?? '';
    final url = Uri.parse('$baseUrl/api/login');

    final requestBody = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    };

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

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/app');
      } else {
        final data = jsonDecode(response.body);
        final error = data['error'];
        setState(
          () => _errorMessage = error is String ? error : 'Login failed',
        );
      }
    } catch (_) {
      setState(() => _errorMessage = 'Unable to connect to server');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId:
        '310568746138-c0kqf9kr1on4hrgrt9g7f111tv1rm6c3.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  Future<void> handleGoogleSignIn() async {
    try {
      final googleSignInInstance = Platform.isAndroid
          ? GoogleSignIn(
              clientId: dotenv.env['GOOGLE_CLIENT_ID'],
              scopes: ['email', 'profile'],
            )
          : GoogleSignIn(scopes: ['email', 'profile']); // iOS auto-reads plist

      await googleSignInInstance
          .signOut(); // ✅ Reset any previous incomplete login

      final googleUser = await googleSignInInstance.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final token = await userCredential.user?.getIdToken();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token ?? '');

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/app');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed: $e';
      });
      print('❌ Google Sign-In failed: $e');
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: _borderRadius),
      contentPadding: _contentPadding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 128),
                  Image.asset('assets/images/logo.png', height: 100),
                  const SizedBox(height: 48),
                  Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      children: [
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          autofocus: true,
                          keyboardType: TextInputType.emailAddress,
                          style: _fieldTextStyle,
                          decoration: _buildInputDecoration('Email'),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: _fieldTextStyle,
                          decoration: _buildInputDecoration('Password')
                              .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: _loading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : FilledButton(
                                  onPressed: _login,
                                  style: FilledButton.styleFrom(
                                    textStyle: _fieldTextStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    padding: _contentPadding,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: _borderRadius,
                                    ),
                                  ),
                                  child: const Text('Login'),
                                ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: handleGoogleSignIn,
                            icon: Image.asset(
                              'assets/icons/google.png',
                              height: 20,
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(6),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
