import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'weather.dart';

class BlockData {
  final String title;
  final Color color;
  final double height;

  const BlockData({
    required this.title,
    required this.color,
    this.height = 100,
  });
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // List of blocks you can easily edit, reorder, or expand.
  final List<BlockData> blocks = const [
    BlockData(
      title: 'Health & Well Being',
      color: Color.fromARGB(255, 63, 63, 63),
      height: 200,
    ),
    BlockData(
      title: 'Weather',
      color: Color.fromARGB(255, 63, 63, 63),
      height: 350,
    ),
  ];

  // URL launcher helper.
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45,
        title: Image.asset(
          'lib/images/ucsdLogo.png',
          height: 200,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];

          if (block.title == 'Health & Well Being') {
            return Container(
              height: block.height,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.fromLTRB(1, 1, 1, 0),
              decoration: BoxDecoration(
                color: block.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title inset farther from the left edge.
                  const Padding(
                    padding: EdgeInsets.only(left: 14.0, top: 7),
                    child: Text(
                      'Health & Well Being',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openUrl('https://caps.ucsd.edu/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('CAPS'),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openUrl('https://healthpromotion.ucsd.edu/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('Health Promotion Services'),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openUrl('https://studenthealth.ucsd.edu/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('Student Health Services'),
                    ),
                  ),
                ],
              ),
            );
          }

/***************************Block2*******************************************/

          if (block.title == 'Weather') {
            return Container(
              height: block.height,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: block.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                    child: Text(
                      'Weather',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: const WeatherWidget(),
                    ),
                  ),
                ],
              ),
            );
          }

          // Default block rendering for other blocks.
          return Container(
            height: block.height,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: block.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    );
  }
}
