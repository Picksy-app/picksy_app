import 'package:flutter/material.dart';
import 'package:picksy/screens/category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Example pages; replace with your actual widgets.
  final List<Widget> _pages = [
    const Center(child: Text("Welcome to Home Screen!", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Instamart", style: TextStyle(fontSize: 20))),
    CategoryScreen(),
    const Center(child: Text("Reorder", style: TextStyle(fontSize: 20))),
    const Center(child: Text("Offers", style: TextStyle(fontSize: 20))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onDrawerSelected(String value) {
    Navigator.pop(context);
    // Add navigation logic depending on 'value'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Hello User!",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => _onDrawerSelected("home"),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text("My Cart"),
              onTap: () => _onDrawerSelected("cart"),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text("My Orders"),
              onTap: () => _onDrawerSelected("orders"),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              onTap: () => _onDrawerSelected("about"),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => _onDrawerSelected("logout"),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: "Instamart"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.refresh), label: "Reorder"),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: "Offers"),
        ],
      ),
    );
  }
}
