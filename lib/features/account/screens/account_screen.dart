import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Centered container with text
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'Account Settings',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),

          // Bottom pinned logout button
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: () => _logout(context),
                  child: const Text('Logout'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}