import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _secureStorage = FlutterSecureStorage();

class MyCalenderApp extends StatelessWidget {
  const MyCalenderApp({super.key});

  final String webAppUrl = 'https://ucsd-app-project.onrender.com';

  Future<void> _launchWebApp() async {
    final accessToken = await _secureStorage.read(key: 'googleAccessToken');

    if (accessToken == null) {
      _showMessage('Google sign-in required before launching calendar.');
      return;
    }

    final url = Uri.parse('$webAppUrl?access_token=$accessToken');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _showMessage(String msg) {
    // fallback message if run outside of widget context
    print(msg);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCSD Class Scheduler',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('UCSD Class Scheduler')),
        body: Center(
          child: ElevatedButton(
            onPressed: _launchWebApp,
            child: const Text('Open Schedule App'),
          ),
        ),
      ),
    );
  }
}
