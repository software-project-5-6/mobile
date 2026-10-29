import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final User? user = Supabase.instance.client.auth.currentUser;

      String email = "";
      String name = "";

      if (user != null) {
        email = user.email ?? "";
        name =
            user.userMetadata?['name'] ?? user.userMetadata?['full_name'] ?? "";
      }

      if (email.isNotEmpty && name.isEmpty) name = email.split('@')[0];

      if (mounted) {
        setState(() {
          _email = email.isNotEmpty ? email : "user@example.com";
          _name = name.isNotEmpty
              ? name
              : (widget.isAdmin ? "Super Admin" : "App User");
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
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase().substring(0, 2);
    }
    return name[0].toUpperCase();
  }

  String _getRoleLabel() {
    return widget.isAdmin ? "Administrator" : "User";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 60,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        automaticallyImplyLeading: false,
        leadingWidth: 70,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.arrow_back,
                color:
                    Theme.of(context).appBarTheme.foregroundColor ??
                    (isDark ? Colors.white : Colors.black87),
                size: 24,
              ),
            ),
          ),
        ),
      ),

      // --- Body Content (Mobile Optimized) ---
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A11CB)),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Profile Section ---
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.only(
                      top: 30,
                      bottom: 32,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFBCD1F4),
                          child: Text(
                            _initials,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF818CF8)
                                  : const Color(0xFF6A11CB),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isAdmin
                                ? Colors.redAccent.withValues(alpha: 0.1)
                                : const Color(
                                    0xFF6A11CB,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRoleLabel(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.isAdmin
                                  ? Colors.redAccent
                                  : const Color(0xFF6A11CB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Detailed Information List ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            bottom: 8.0,
                          ),
                          child: Text(
                            "ACCOUNT DETAILS",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                              letterSpacing: 1,
                            ),
                          ),
                        ),

                        // Grouped List Card
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMobileListRow(
                                context: context,
                                isDark: isDark,
                                icon: Icons.person_outline,
                                label: "Full Name",
                                value: _name,
                              ),
                              const Divider(height: 1, indent: 60),
                              _buildMobileListRow(
                                context: context,
                                isDark: isDark,
                                icon: Icons.email_outlined,
                                label: "Email Address",
                                value: _email,
                              ),
                              const Divider(height: 1, indent: 60),
                              _buildMobileListRow(
                                context: context,
                                isDark: isDark,
                                icon: Icons.admin_panel_settings_outlined,
                                label: "Account Role",
                                value: _getRoleLabel(),
                                valueColor: widget.isAdmin
                                    ? Colors.redAccent
                                    : const Color(0xFF6A11CB),
                              ),
                              const Divider(height: 1, indent: 60),
                              _buildMobileListRow(
                                context: context,
                                isDark: isDark,
                                icon: Icons.check_circle_outline,
                                label: "Account Status",
                                value: "Active & Verified",
                                valueColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper Widget for the native mobile list feel
  Widget _buildMobileListRow({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[400] : Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
