import 'package:flutter/material.dart';

/// A simple model to hold data for each block
class BlockData {
  final String title;
  final String description;
  final Color color;
  final double height;

  const BlockData({
    required this.title,
    required this.description,
    required this.color,
    this.height = 100,
  });
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // List of blocks you can easily edit, reorder, or expand
  final List<BlockData> blocks = const [
    BlockData(
      title: 'Health & Well Being',
      description: 'Description/Links',
      color: Colors.red,
    ),
    BlockData(
      title: 'Block 2',
      description: 'Description/Links',
      color: Colors.grey,
    ),
    BlockData(title: 'Block 3', description: 'Standard block.', color: Colors.grey),
    BlockData(title: 'Block 4', description: 'Standard block.', color: Colors.grey),
    BlockData(title: 'Block 5', description: 'Standard block.', color: Colors.grey),
    BlockData(title: 'Block 6', description: 'Standard block.', color: Colors.grey),
    BlockData(title: 'Block 7', description: 'Standard block.', color: Colors.grey),
    BlockData(title: 'Block 8', description: 'Standard block.', color: Colors.grey),
    BlockData(title: 'Block 9', description: 'Standard block.', color: Colors.grey),
    BlockData(title: 'Block 10', description: 'Standard block.', color: Colors.grey),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return Container(
          height: block.height,
          margin: const EdgeInsets.only(bottom: 16),
          color: block.color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                block.title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                block.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
