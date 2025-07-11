import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  final _fieldTextStyle = const TextStyle(fontSize: 16);
  final _contentPadding = const EdgeInsets.symmetric(vertical: 12, horizontal: 12);
  final _borderRadius = BorderRadius.circular(6);

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

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
        final data = jsonDecode(response.body);
        final token = data['result']['auth_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        print(prefs.getKeys());
        for (final key in prefs.getKeys()) {
          print('$key => ${prefs.get(key)}');
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['error'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Unable to connect to server');
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
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  keyboardType: TextInputType.emailAddress,
                  style: _fieldTextStyle,
                  decoration: _buildInputDecoration('Email'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!_emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: _fieldTextStyle,
                  decoration: _buildInputDecoration('Password'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _login,
                    style: FilledButton.styleFrom(
                      textStyle: _fieldTextStyle.copyWith(fontWeight: FontWeight.bold),
                      padding: _contentPadding,
                      shape: RoundedRectangleBorder(borderRadius: _borderRadius),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}