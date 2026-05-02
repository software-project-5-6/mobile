import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';
import '../services/chat_service.dart';
import 'login_screen.dart';
import 'projects_screen.dart'; 
import 'ai_assistant_screen.dart';
import 'users/users_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isAdmin; 

  const DashboardScreen({super.key, required this.isAdmin});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0; 

  // User details state variables
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String _userInitials = "U";

  // --- Global State for AI Assistant ---
  Map<String, String>? _currentProjectWithAssistant;
  String? _currentConversationId;

  // Services for Drawer Data
  final ProjectService _projectService = ProjectService();
  final ChatService _chatService = ChatService();

  List<dynamic> _projects = [];
  List<dynamic> _conversations = [];
  bool _isLoadingSidebar = true;

@override
  void initState() {
    super.initState();
    // Replace the parallel calls with our new staggered initializer
    _safeInitializeDashboard();
  }

  // --- NEW STAGGERED BOOT SEQUENCE ---
  Future<void> _safeInitializeDashboard() async {
    // 1. Give the native AWS bridge a tiny moment to settle after the screen transition
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // 2. Safely fetch User Details first
    await _fetchUserDetails();
    if (!mounted) return;

    // 3. Finally, fetch Projects and chat data
    await _fetchProjectsForSidebar();
  }
  Future<void> _fetchUserDetails() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      String email = "";
      String name = "";

      for (final element in attributes) {
        if (element.userAttributeKey.key == 'email') email = element.value;
        else if (element.userAttributeKey.key == 'name') name = element.value;
      }

      if (email.isNotEmpty && name.isEmpty) name = email.split('@')[0]; 

      if (mounted) {
        setState(() {
          _userEmail = email.isNotEmpty ? email : "user@example.com";
          _userName = name.isNotEmpty ? name : (widget.isAdmin ? "Super Admin" : "App User");
          _userInitials = _getInitials(_userName);
        });
      }
    } catch (e) {
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

  Future<void> _fetchProjectsForSidebar() async {
    try {
      final data = await _projectService.getAllProjects();
      setState(() {
        _projects = data;
        if (data.isNotEmpty) {
          _setCurrentProject({
            "projectId": data[0]['id'].toString(),
            "projectName": data[0]['projectName'] ?? data[0]['name'] ?? "Unnamed",
          });
        }
        _isLoadingSidebar = false;
      });
    } catch (e) {
      setState(() => _isLoadingSidebar = false);
      debugPrint("Error loading projects for sidebar: $e");
    }
  }

  Future<void> _fetchConversations(String projectId) async {
    try {
      final response = await _chatService.getAllConversationsForProject(projectId);
      
      setState(() {
        if (response is List) {
          _conversations = response;
        } else if (response is Map && response.containsKey('conversations')) {
          _conversations = response['conversations'] ?? [];
        } else {
          _conversations = [];
        }

        if (_conversations.isNotEmpty) {
          _currentConversationId = _conversations.last['conversationId'].toString();
        } else {
          _currentConversationId = null;
        }
      });
    } catch (e) {
      debugPrint("Error fetching sidebar conversations: $e");
    }
  }

  void _setCurrentProject(Map<String, String> project) {
    setState(() {
      _currentProjectWithAssistant = project;
      _currentConversationId = null;
    });
    _fetchConversations(project['projectId']!);
  }

  // --- NEW: Delete Chat Logic ---
  Future<void> _confirmDeleteChat(String conversationId) async {
    // 1. Show confirmation popup
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Chat"),
        content: const Text("Are you sure you want to delete this chat history? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    // 2. If user clicked Delete, call the database
    if (confirm == true) {
      try {
        await _chatService.deleteAllMessagesForConversation(conversationId);
        
        // Refresh the list
        if (_currentProjectWithAssistant != null) {
          await _fetchConversations(_currentProjectWithAssistant!['projectId']!);
        }

        // If the user deleted the chat they were currently looking at, reset the screen
        if (_currentConversationId == conversationId) {
          setState(() {
            _currentConversationId = null;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat deleted successfully")));
        }
      } catch (e) {
        debugPrint("Failed to delete chat: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete chat"), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _showNewChatDialog() async {
    String newTitle = "";
    bool isCreating = false;
    
    String? dialogSelectedProjectId = _currentProjectWithAssistant?['projectId'];
    if (dialogSelectedProjectId == null && _projects.isNotEmpty) {
      dialogSelectedProjectId = _projects[0]['id'].toString();
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Start New Chat"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCreating) const LinearProgressIndicator(),
                const SizedBox(height: 10),
                
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Enter Chat Title", 
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (val) => newTitle = val,
                ),
                const SizedBox(height: 16),
                
                const Text("Assign to Project", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (_projects.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    value: dialogSelectedProjectId,
                    isExpanded: true,
                    items: _projects.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'].toString(),
                        child: Text(
                          p['projectName'] ?? p['name'] ?? 'Unnamed Project', 
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        dialogSelectedProjectId = val;
                      });
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB)),
                onPressed: (isCreating || dialogSelectedProjectId == null) ? null : () async {
                  if (newTitle.trim().isNotEmpty) {
                    setStateDialog(() => isCreating = true); 
                    try {
                      final newId = await _chatService.createConversation({
                        "projectId": dialogSelectedProjectId!, 
                        "title": newTitle.trim(),
                      });
                      
                      final proj = _projects.firstWhere((p) => p['id'].toString() == dialogSelectedProjectId);
                      setState(() {
                        _currentProjectWithAssistant = {
                          "projectId": proj['id'].toString(),
                          "projectName": proj['projectName'] ?? proj['name'] ?? "",
                        };
                      });
                      
                      await _fetchConversations(dialogSelectedProjectId!);
                      
                      setState(() {
                        _currentConversationId = newId.toString();
                        _currentIndex = 0; 
                      });
                      
                      Navigator.pop(ctx); 
                      Navigator.pop(context); 
                    } catch (e) {
                      debugPrint("Failed to create chat: $e");
                      setStateDialog(() => isCreating = false);
                    }
                  }
                },
                child: const Text("Create", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                const PopupMenuItem<String>(value: 'profile', child: ListTile(leading: Icon(Icons.person, color: Colors.grey), title: Text("Profile"), contentPadding: EdgeInsets.zero, dense: true)),
                const PopupMenuItem<String>(value: 'settings', child: ListTile(leading: Icon(Icons.settings, color: Colors.grey), title: Text("Settings"), contentPadding: EdgeInsets.zero, dense: true)),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text("Logout", style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero, dense: true)),
              ],
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => ProfileScreen(isAdmin: widget.isAdmin))
                  );
                } else if (value == 'logout') {
                  _handleLogout();
                }
              },
            ),
          )
        ],
      ),

      drawer: Drawer(
        child: Column(
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
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ExpansionTile(
                    initiallyExpanded: _currentIndex == 0,
                    leading: Icon(Icons.auto_awesome, color: _currentIndex == 0 ? const Color(0xFF6A11CB) : Colors.grey),
                    title: Text("AI Assistant", style: TextStyle(fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.normal)),
                    onExpansionChanged: (expanded) {
                      if (expanded) setState(() => _currentIndex = 0);
                    },
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 40, right: 16),
                        leading: const Icon(Icons.add, size: 20),
                        title: const Text("New Chat", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        onTap: _showNewChatDialog,
                      ),
                      
                      if (!_isLoadingSidebar && _projects.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 40, right: 16, top: 8, bottom: 8),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              labelText: "Project Category",
                            ),
                            value: _currentProjectWithAssistant?['projectId'],
                            items: _projects.map((p) {
                              return DropdownMenuItem<String>(
                                value: p['id'].toString(),
                                child: Text(p['projectName'] ?? p['name'] ?? 'Unnamed', style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final proj = _projects.firstWhere((p) => p['id'].toString() == val);
                                _setCurrentProject({
                                  "projectId": proj['id'].toString(),
                                  "projectName": proj['projectName'] ?? proj['name'] ?? "",
                                });
                              }
                            },
                          ),
                        ),

                      const Padding(
                        padding: EdgeInsets.only(left: 40, top: 8, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("RECENT CHATS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                      ),

                      if (_conversations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(left: 40, top: 8, bottom: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("No chats yet.", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ),
                        ),

                      ..._conversations.map((chat) {
                        final isSelected = chat['conversationId'].toString() == _currentConversationId;
                        return Container(
                          color: isSelected ? const Color(0xFF6A11CB).withValues(alpha: 0.1) : Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(left: 40, right: 8),
                            title: Text(chat['title'] ?? 'Untitled', style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            
                            // --- NEW: The Delete Icon Button ---
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                              onPressed: () => _confirmDeleteChat(chat['conversationId'].toString()),
                            ),
                            
                            onTap: () {
                              setState(() {
                                _currentConversationId = chat['conversationId'].toString();
                                _currentIndex = 0;
                              });
                              Navigator.pop(context); 
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.folder, color: _currentIndex == 1 ? const Color(0xFF6A11CB) : Colors.grey),
                    title: Text("Projects", style: TextStyle(fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.normal)),
                    selected: _currentIndex == 1,
                    selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                    onTap: () {
                      Navigator.pop(context); 
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectsScreen(isAdmin: widget.isAdmin)));
                    },
                  ),
                  
                  if (widget.isAdmin) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                      child: Text("ADMIN TOOLS", style: TextStyle(color: Color.fromARGB(255, 139, 135, 135), fontSize: 12)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text("Users"),
                      onTap: () {
                        Navigator.pop(context); 
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersScreen()));
                      },
                    ),
                  ],

                  if (!widget.isAdmin) const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("Settings"),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: _currentIndex == 0 
        ? AIAssistantScreen(
            currentProjectWithAssistant: _currentProjectWithAssistant,
            currentConversationId: _currentConversationId,
          ) 
        : const ProjectsScreen(isAdmin: false),
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