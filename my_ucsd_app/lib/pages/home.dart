import 'package:flutter/material.dart';


/// ------------------------------------------------------------
/// HOME PAGE
///   - Shows sample content blocks
/// ------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildContentBlock(
            'Block 1',
            'This is the first content block with some random text.',
            Colors.blue[100]!,
          ),
          _buildContentBlock(
            'Block 2',
            'Second block with different content and color.',
            Colors.green[100]!,
          ),
          _buildContentBlock(
            'Block 3',
            'Third block showing another example of content.',
            Colors.orange[100]!,
          ),
          _buildContentBlock(
            'Block 4',
            'Final block completing our set of four content sections.',
            Colors.purple[100]!,
          ),
        ],
      ),
    );
  }

  Widget _buildContentBlock(String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}