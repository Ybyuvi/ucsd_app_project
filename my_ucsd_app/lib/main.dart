import 'package:flutter/material.dart';
import 'pages/google_map_page.dart';
import 'pages/GPTSchedulePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCSD',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 2, 38, 69),
          titleTextStyle: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255), 
            fontSize: 20,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
          iconTheme: const IconThemeData(color: Color(0xff03045E)),
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const HomePage(),
    const GoogleMapPage(),
    const GptSchedulePage(),
    const Page3(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50, 
        title: Image.asset(
          'lib/images/ucsdLogo.png',
          height: 200,
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: "Maps",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "Search",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildContentBlock(
            "Block 1",
            "This is the first content block with some random text.",
            Colors.blue[100]!,
          ),
          _buildContentBlock(
            "Block 2",
            "Second block with different content and color.",
            Colors.green[100]!,
          ),
          _buildContentBlock(
            "Block 3",
            "Third block showing another example of content.",
            Colors.orange[100]!,
          ),
          _buildContentBlock(
            "Block 4",
            "Final block completing our set of four content sections.",
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

class Page2 extends StatelessWidget {
  const Page2({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Search Content",
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class Page3 extends StatelessWidget {
  const Page3({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Profile Content",
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
