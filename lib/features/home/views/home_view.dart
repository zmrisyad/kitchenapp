import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _fullName;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final baseUrl = dotenv.env['API_URL'] ?? '';

    if (token == null) {
      setState(() {
        _error = 'No token found';
        _loading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'];
        final fullName = '${result['first_name']} ${result['last_name']}';

        setState(() {
          _fullName = fullName;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load profile';
          _loading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _error = 'Unable to connect to server';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
        elevation: 2,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _loading
                  ? const CircularProgressIndicator()
                  : _error != null
                  ? Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : Text(
                      'Hello, $_fullName!',
                      textAlign: TextAlign.start,
                      style: const TextStyle(fontSize: 20),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
