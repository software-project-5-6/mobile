import 'package:flutter/material.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. APP BAR (Matches the Purple Header in your screenshot)
      appBar: AppBar(
        title: const Text("Space Management", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF6A11CB), // Purple
        iconTheme: const IconThemeData(color: Colors.white), // White Hamburger Icon
        actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 50), // Moves the menu down slightly
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // Rounded corners like screenshot
                ),
                // THE TRIGGER (The Avatar Icon)
                child: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text("SA", style: TextStyle(color: Colors.white)),
                ),
                
                // THE MENU ITEMS
                itemBuilder: (context) => [
                  // 1. User Info Header
                  const PopupMenuItem<String>(
                    enabled: false, // Cannot click the header
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Super Admin", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text("admin@psms.com", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Divider(),
                      ],
                    ),
                  ),
                  
                  // 2. Profile Button
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.grey),
                      title: Text("Profile"),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  
                  // 3. Settings Button
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings, color: Colors.grey),
                      title: Text("Settings"),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  
                  // Divider before Logout
                  const PopupMenuDivider(),
                  
                  // 4. Logout Button (Red)
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red), // Red Icon
                      title: Text("Logout", style: TextStyle(color: Colors.red)), // Red Text
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
                
                // WHAT HAPPENS WHEN YOU CLICK AN ITEM
                onSelected: (value) {
                  if (value == 'logout') {
                    // Navigate back to Login Screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  } else {
                    // Placeholder for Profile/Settings
                    print("Clicked: $value"); 
                  }
                },
              ),
            )
          ],
      ),

      // 2. THE DRAWER (This replaces the Web Sidebar)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF6A11CB)),
              accountName: Text("Super Admin"),
              accountEmail: Text("admin@psms.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text("SA", style: TextStyle(color: Color(0xFF6A11CB))),
              ),
            ),
            // Menu Items from your screenshot
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Color(0xFF6A11CB)),
              title: const Text("AI Assistant"),
              selected: true, // Highlights this item
              selectedTileColor: Colors.blue.withOpacity(0.1),
              onTap: () { Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text("Projects"),
              onTap: () {},
            ),
            const Divider(), // Admin Tools Section
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
              child: Text("ADMIN TOOLS", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Users"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),
          ],
        ),
      ),

      // 3. THE BODY (The AI Chat Interface from your screenshot)
      body: Column(
        children: [
          // Chat History Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // The AI's Message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF6A11CB),
                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Hello! I'm your AI assistant. How can I help you with your projects today?",
                              style: TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 5),
                            Text("03:15 PM", style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // The Input Box at the bottom
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Type your message here...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}