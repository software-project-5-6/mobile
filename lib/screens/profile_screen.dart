import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final bool isAdmin;
  
  const ProfileScreen({super.key, required this.isAdmin});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "Loading...";
  String _email = "Loading...";
  String _initials = "U";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
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
          _email = email.isNotEmpty ? email : "user@example.com";
          _name = name.isNotEmpty ? name : (widget.isAdmin ? "Super Admin" : "App User");
          _initials = _getInitials(_name);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _name = widget.isAdmin ? "Super Admin" : "App User";
          _email = "user@example.com";
          _initials = widget.isAdmin ? "SA" : "U";
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) return "${parts[0][0]}${parts[1][0]}".toUpperCase().substring(0, 2);
    return name[0].toUpperCase();
  }

  String _getRoleLabel() {
    return widget.isAdmin ? "Administrator" : "User";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Match the grey background
      
      // --- Top App Bar ---
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 158, 169, 218),
        elevation: 0,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        leadingWidth: 70,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: const Icon(
                Icons.arrow_back,
                color: Color.fromARGB(255, 0, 0, 0),
                size: 24,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "My Profile",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            SizedBox(height: 2),
            Text(
              "View your personal info and details",
              style: TextStyle(color: Color.fromARGB(255, 66, 66, 66), fontSize: 12),
            ),
          ],
        ),
      ),

      // --- Body Content ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
          : Center( // <-- ADDED THIS CENTER WIDGET
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Main Profile Card ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner & Avatar Stack
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Purple Banner
                              Container(
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6A11CB), // Primary theme color
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                              ),
                              // Overlapping Avatar
                              Positioned(
                                top: 40, // Halfway off the banner
                                left: 24,
                                child: Container(
                                  padding: const EdgeInsets.all(4), // Creates the white border
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 36,
                                    backgroundColor: const Color(0xFFBCD1F4), // Light blue from web
                                    child: Text(
                                      _initials,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6A11CB), // Dark text
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Spacer to push content down past the overlapping avatar
                          const SizedBox(height: 50), 

                          // User Name & Quick Badges
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(_email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                    const SizedBox(width: 8),
                                    Text("•", style: TextStyle(color: Colors.grey[400])),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getRoleLabel(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: widget.isAdmin ? Colors.redAccent : const Color(0xFF6A11CB),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Divider(height: 1),
                          ),

                          // Detailed Information Grid (Account Details)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ACCOUNT DETAILS",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[500],
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // InfoRows stacked vertically for mobile
                                _buildInfoRow(
                                  icon: Icons.person_outline,
                                  label: "FULL NAME",
                                  value: _name,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.email_outlined,
                                  label: "EMAIL ADDRESS",
                                  value: _email,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.admin_panel_settings_outlined,
                                  label: "ACCOUNT ROLE",
                                  value: _getRoleLabel(),
                                  valueColor: widget.isAdmin ? Colors.redAccent : const Color(0xFF6A11CB),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.check_circle_outline,
                                  label: "ACCOUNT STATUS",
                                  value: "Active & Verified", 
                                  valueColor: Colors.green,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper Widget to create the MUI <Paper variant="outlined"> effect
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26.0), // Aligns with text above, indented past icon
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}