import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
//import 'admin_projects_screen.dart';
//import 'user_projects_view.dart';
import 'projects_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  // ADDED: This flag determines if the user sees Admin features or User features
  final bool isAdmin; 

  const DashboardScreen({super.key, required this.isAdmin});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0; // 0 = Chat, 1 = Projects (For Users)
  final TextEditingController _messageController = TextEditingController();

  // User details state variables
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String _userInitials = "U";

  // Dummy Messages for the UI
  final List<Map<String, dynamic>> _messages = [
    {
      "isUser": false,
      "text": "Hello! I'm your AI assistant. How can I help you with your projects today?",
      "time": "10:03 PM"
    }
  ];

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
                
                // BOOM! Now BOTH roles push to the exact same full-screen view!
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
      body: _currentIndex == 0 ? _buildChatScreen() : _buildProjectsScreen(),
    );
  }

  // --- AI CHAT SCREEN ---
  Widget _buildChatScreen() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['isUser'];

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF6A11CB) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(15),
                      topRight: const Radius.circular(15),
                      bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg['text'], style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(msg['time'], style: TextStyle(color: isUser ? Colors.white70 : Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        if (_messages.length == 1) 
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildSuggestionChip("How can you help me?"),
                _buildSuggestionChip("Show my projects"),
                _buildSuggestionChip("What can you do?"),
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: "Type your message here...",
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF6A11CB),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      setState(() {
                        _messages.add({"isUser": true, "text": _messageController.text, "time": "Now"});
                        _messageController.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- PROJECTS SCREEN (For Regular Users Only) ---
  Widget _buildProjectsScreen() {
    return const ProjectsScreen(isAdmin: false); 
  }

  Widget _buildSuggestionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: const Color(0xFFEFEFEF),
        onPressed: () {
          setState(() {
             _messageController.text = label;
          });
        },
      ),
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