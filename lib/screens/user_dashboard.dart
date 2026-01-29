import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0; // 0 = Chat, 1 = Projects
  final TextEditingController _messageController = TextEditingController();

  // Dummy Messages for the UI
  final List<Map<String, dynamic>> _messages = [
    {
      "isUser": false,
      "text": "Hello! I'm your AI assistant. How can I help you with your projects today?",
      "time": "10:03 PM"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // APP BAR (Purple)
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B6BBF), // Matches your Web Header
        title: const Text("Space Management", style: TextStyle(color: Colors.white)),
        actions: [
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 10),
          // User Avatar
          const CircleAvatar(
            backgroundColor: Color(0xFF9FA8DA),
            child: Text("P", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 15),
        ],
      ),

      // BODY: Switches between Chat and Projects
      body: _currentIndex == 0 ? _buildChatScreen() : _buildProjectsScreen(),

      // BOTTOM NAVIGATION (Instead of Side Menu for Mobile)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF5B6BBF),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: "AI Assistant",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: "Projects",
          ),
        ],
      ),
    );
  }

  // --- TAB 1: AI CHAT SCREEN ---
  Widget _buildChatScreen() {
    return Column(
      children: [
        // 1. MESSAGES LIST
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
                    color: isUser ? const Color(0xFF5B6BBF) : const Color(0xFFF5F5F5),
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
                      Text(
                        msg['text'],
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        msg['time'],
                        style: TextStyle(
                          color: isUser ? Colors.white70 : Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 2. SUGGESTION CHIPS (Optional, matches your design)
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

        // 3. MESSAGE INPUT AREA
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFFE0E0E0),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.grey),
                  onPressed: () {
                    // Logic to send message would go here
                    if (_messageController.text.isNotEmpty) {
                      setState(() {
                        _messages.add({
                          "isUser": true,
                          "text": _messageController.text,
                          "time": "Now"
                        });
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

  // --- TAB 2: PROJECTS SCREEN (Placeholder) ---
  Widget _buildProjectsScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text("Projects will appear here", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Helper for Suggestion Chips
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

  // Logout Logic
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