import 'package:flutter/material.dart';
import '../../services/project_service.dart';
import '../../services/chat_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // API Services
  final ProjectService _projectService = ProjectService();
  final ChatService _chatService = ChatService();
  
  bool _isSending = false;
  bool _isLoadingProjects = true;
  String? _error;
  
  // Project State
  List<dynamic> _projects = [];
  String? _selectedProjectId;

  // Messages State
  List<Map<String, dynamic>> _messages = [];

  // Theme Colors matching your frontend gradients.primary
  final Color primaryColor = const Color(0xFF6A11CB);

  @override
  void initState() {
    super.initState();
    _initChat();
    _fetchProjects();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initChat() {
    setState(() {
      _messages = [
        {
          "isUser": false,
          "text": "Hello! I'm your AI assistant. How can I help you with your projects today?",
          "time": DateTime.now(),
        }
      ];
    });
  }

  Future<void> _fetchProjects() async {
    try {
      setState(() {
        _isLoadingProjects = true;
        _error = null;
      });
      
      final data = await _projectService.getAllProjects();

      setState(() {
        _projects = data;
        // Leaving _selectedProjectId as null so "Current Project" placeholder shows
        _selectedProjectId = null;
        _isLoadingProjects = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load projects. Please try again later.";
        _isLoadingProjects = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (_selectedProjectId == null) {
      setState(() => _error = "Please select a Current Project from the dropdown first.");
      return;
    }

    setState(() {
      _error = null;
      _messages.add({
        "isUser": true,
        "text": text,
        "time": DateTime.now(),
      });
      _isSending = true;
      if (predefinedText == null) _messageController.clear();
    });
    
    _scrollToBottom();

    try {
      final response = await _chatService.askProject(
        _selectedProjectId!, 
        {"question": text}
      );
      
      setState(() {
        _messages.add({
          "isUser": false,
          "text": response['answer'] ?? "I couldn't process that. Please try again.", 
          "time": DateTime.now(),
        });
      });
    } catch (e) {
      setState(() => _error = "Failed to get AI response");
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          if (_error != null) _buildErrorBar(),
          Expanded(
            child: _isLoadingProjects
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _buildMessageList(),
          ),
          if (_isSending) _buildTypingIndicator(),
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  // --- 1. HEADER (Matches MUI Header) ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor,
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AI Assistant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text("Always ready to help", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          
          // Dropdown (Matches MUI Select outlined style)
          if (!_isLoadingProjects && _projects.isNotEmpty)
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProjectId,
                  hint: const Text("Current Project", style: TextStyle(color: Colors.black54, fontSize: 14)),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  items: _projects.map((p) {
                    final displayName = p['projectName'] ?? p['name'] ?? 'Unnamed Project';
                    return DropdownMenuItem<String>(
                      value: p['id'].toString(),
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedProjectId = val),
                ),
              ),
            ),
            
          const SizedBox(width: 12),
          
          // Refresh Button
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              onPressed: () {
                _initChat();
                _fetchProjects();
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. MESSAGE CHAT AREA (Matches MUI Paper Bubbles) ---
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['isUser'];
        
        // Format time (e.g. "01:35 PM")
        final DateTime time = msg['time'];
        final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
        final amPm = time.hour >= 12 ? "PM" : "AM";
        final timeString = "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm";

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
              ],
              
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? primaryColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8).copyWith(
                      topLeft: isUser ? const Radius.circular(8) : Radius.zero,
                      topRight: isUser ? Radius.zero : const Radius.circular(8),
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
                      const SizedBox(height: 8),
                      Text(
                        timeString,
                        style: TextStyle(
                          color: isUser ? Colors.white70 : Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (isUser) ...[
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.purple.shade300,
                  child: const Text("U", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- 3. TYPING INDICATOR ---
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryColor,
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8).copyWith(topLeft: Radius.zero),
            ),
            child: const Text("Typing...", style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  // --- 4. BOTTOM INPUT AREA (Matches MUI TextField & Chips) ---
  Widget _buildBottomInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Field and Send Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  enabled: !_isSending,
                  decoration: InputDecoration(
                    hintText: "Type your message here...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300, // Matches your web screenshot's send button color
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.black54),
                  onPressed: _isSending ? null : () => _handleSendMessage(),
                ),
              ),
            ],
          ),
          
          // Suggestion Chips (Only show when chat is new)
          if (_messages.length == 1 && !_isLoadingProjects) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip("How can you help me?"),
                _buildChip("Show my projects"),
                _buildChip("What can you do?"),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      backgroundColor: Colors.grey.shade200,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        _messageController.text = label;
        _focusNode.requestFocus();
      },
    );
  }

  Widget _buildErrorBar() {
    return Container(
      color: Colors.red.shade50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14))),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }
}