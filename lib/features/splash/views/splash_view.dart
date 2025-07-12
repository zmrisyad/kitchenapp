import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:welcome/features/home/views/home_view.dart';
import 'package:welcome/features/auth/views/login_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  late final AnimationController _slideInController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );

  late final AnimationController _slideOutController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  late final Animation<double> _fade = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

  late final Animation<Offset> _slideIn = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _slideInController, curve: Curves.easeOut));

  late final Animation<Offset> _slideOut = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-1.0, 0.0),
  ).animate(CurvedAnimation(parent: _slideOutController, curve: Curves.easeIn));

  bool _spinner = false;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  void _showConnectionError() {
    Fluttertoast.showToast(
      msg: 'Failed to connect to server. Retrying in 10 seconds.',
      gravity: ToastGravity.TOP,
    );
  }

  static const Duration _delay = Duration(milliseconds: 300);
  Future<void> _startSequence() async {
    await _fadeController.forward();
    await _slideInController.forward();
    await Future.delayed(_delay);

    setState(() => _spinner = true);

    final success = await _attemptConnectionLoop();
    if (!success) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await Future.delayed(_delay);
    setState(() => _spinner = false);

    await Future.wait([
      _slideOutController.forward(),
      _fadeController.reverse(),
    ]);

    if (!mounted) return;
    final routeName = (token != null && token.isNotEmpty) ? '/app' : '/login';

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) =>
            routeName == '/home' ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<bool> _attemptConnectionLoop() async {
    final baseUrl = dotenv.env['API_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      Fluttertoast.showToast(msg: 'Missing API_URL in .env file');
      return false; // skip trying to connect
    }
    while (mounted) {
      try {
        final response = await http
            .get(Uri.parse(baseUrl))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) return true;
      } catch (_) {
        _showConnectionError();
      }
      await Future.delayed(const Duration(seconds: 10));
    }
    return false;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideInController.dispose();
    _slideOutController.dispose();
    super.dispose();
  }

  Widget _buildSplashContent(Color spinnerColor) {
    return Stack(
      children: [
        const Center(
          child: Text(
            'WELCOME',
            style: TextStyle(
              fontSize: 32,
              color: Color(0xFFFAFAFA),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: spinnerColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF212121);
    final spinnerColor = _spinner ? const Color(0xFFFAFAFA) : bgColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fade,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _slideInController,
            _slideOutController,
          ]),
          builder: (context, child) {
            final offset =
                _slideOutController.isAnimating ||
                    _slideOutController.isCompleted
                ? _slideOut
                : _slideIn;
            return ClipRect(
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: _buildSplashContent(spinnerColor),
        ),
      ),
    );
  }
}
