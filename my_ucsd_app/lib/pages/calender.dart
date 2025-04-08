import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyCalenderApp());
}

class MyCalenderApp extends StatelessWidget {
  const MyCalenderApp({super.key});

  // This is the Render URL for your Flask app
  final String webAppUrl = 'https://ucsd-app-project.onrender.com';

  Future<void> _launchWebApp() async {
    final url = Uri.parse(webAppUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $webAppUrl';
    }
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
