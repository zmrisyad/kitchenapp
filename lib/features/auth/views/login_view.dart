import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:welcome/core/utils/toast.dart';
import 'package:welcome/features/auth/controllers/login_controller.dart';
import 'package:welcome/features/auth/widgets/email_input.dart';
import 'package:welcome/features/auth/widgets/password_input.dart';
import 'package:welcome/features/auth/widgets/login_button.dart';
import 'package:welcome/features/auth/widgets/google_sign_in_button.dart';

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
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _submitted = true);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final error = await LoginController.loginWithEmail(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (error != null) {
      AppToast.show(error);
      return;
    }

    Navigator.pushReplacementNamed(context, '/app');
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);

    final error = await LoginController.loginWithGoogle();

    if (!mounted) return;

    if (error != null) {
      setState(() => _loading = false);
      AppToast.show(error);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/app');
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
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
                            EmailInputField(controller: _emailController),
                            const SizedBox(height: 16),
                            PasswordInputField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              toggleObscureText: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            LoginButton(loading: false, onPressed: _login),
                            const SizedBox(height: 24),
                            GoogleSignInButton(onPressed: _handleGoogleSignIn),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_loading) ...[
            const ModalBarrier(dismissible: false, color: Colors.black45),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
