import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'projects_screen.dart'; 
import 'ai_assistant_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isAdmin; 

  const DashboardScreen({super.key, required this.isAdmin});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0; // 0 = Chat, 1 = Projects (For Users)

  // User details state variables
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String _userInitials = "U";

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  // Fetch User Data from AWS Cognito
  Future<void> _fetchUserDetails() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      String email = "";
      String name = "";

      for (final element in attributes) {
        if (element.userAttributeKey.key == 'email') {
          email = element.value;
        } else if (element.userAttributeKey.key == 'name') {
          name = element.value;
        }
      }

      if (email.isNotEmpty && name.isEmpty) {
        name = email.split('@')[0]; 
      }

      if (mounted) {
        setState(() {
          _userEmail = email.isNotEmpty ? email : "user@example.com";
          _userName = name.isNotEmpty ? name : (widget.isAdmin ? "Super Admin" : "App User");
          _userInitials = _getInitials(_userName);
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
      if (mounted) {
        setState(() {
          _userName = widget.isAdmin ? "Super Admin" : "App User";
          _userEmail = "user@example.com";
          _userInitials = widget.isAdmin ? "SA" : "U";
        });
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text("Space Management", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF6A11CB),
        iconTheme: const IconThemeData(color: Colors.white), 
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(_userInitials, style: const TextStyle(color: Colors.white)), 
              ),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(_userEmail, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Divider(),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: ListTile(leading: Icon(Icons.person, color: Colors.grey), title: Text("Profile"), contentPadding: EdgeInsets.zero, dense: true),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(leading: Icon(Icons.settings, color: Colors.grey), title: Text("Settings"), contentPadding: EdgeInsets.zero, dense: true),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text("Logout", style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero, dense: true),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') _handleLogout();
              },
            ),
          )
        ],
      ),

      // --- DRAWER (Left Side Panel) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF6A11CB)),
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(_userInitials, style: const TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold)),
              ),
            ),
            
            // Tab 0: AI Assistant
            ListTile(
              leading: Icon(Icons.auto_awesome, color: _currentIndex == 0 ? const Color(0xFF6A11CB) : Colors.grey),
              title: Text("AI Assistant", style: TextStyle(fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.normal)),
              selected: _currentIndex == 0,
              selectedTileColor: Colors.blue.withOpacity(0.1),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            
            // Tab 1: Projects
            ListTile(
              leading: Icon(Icons.folder, color: _currentIndex == 1 ? const Color(0xFF6A11CB) : Colors.grey),
              title: Text("Projects", style: TextStyle(fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.normal)),
              selected: _currentIndex == 1,
              selectedTileColor: Colors.blue.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => ProjectsScreen(isAdmin: widget.isAdmin)
                  )
                );
              },
            ),
            
            // --- ADMIN ONLY TOOLS ---
            if (widget.isAdmin) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                child: Text("ADMIN TOOLS", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("Users"),
                onTap: () {},
              ),
            ],

            // --- USER ONLY PREFERENCES ---
            if (!widget.isAdmin) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                child: Text("PREFERENCES", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
            
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      // --- BODY ---
      // This checks the current index. If it is 0, it loads the new AI Assistant Screen!
      body: _currentIndex == 0 ? const AIAssistantScreen() : const ProjectsScreen(isAdmin: false),
    );
  }

  Future<void> _handleLogout() async {
    AuthService authService = AuthService();
    await authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}