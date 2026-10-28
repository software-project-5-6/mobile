import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'users/users_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isAdmin;

  const SettingsScreen({super.key, required this.isAdmin});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // User profile details from Supabase session
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String _userInitials = "U";
  bool _isLoadingUser = true;

  // Password update form state
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isUpdatingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  // Admin health check diagnostic state
  bool _isCheckingHealth = false;
  String? _healthStatus;
  bool _healthOk = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final User? user = Supabase.instance.client.auth.currentUser;
      String email = "";
      String name = "";

      if (user != null) {
        email = user.email ?? "";
        name = user.userMetadata?['name'] ??
            user.userMetadata?['full_name'] ??
            "";
      }

      if (email.isNotEmpty && name.isEmpty) {
        name = email.split('@')[0];
      }

      if (mounted) {
        setState(() {
          _userEmail = email.isNotEmpty ? email : "user@example.com";
          _userName = name.isNotEmpty
              ? name
              : (widget.isAdmin ? "Super Admin" : "App User");
          _userInitials = _getInitials(_userName);
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = widget.isAdmin ? "Super Admin" : "App User";
          _userEmail = "user@example.com";
          _userInitials = widget.isAdmin ? "SA" : "U";
          _isLoadingUser = false;
        });
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _handlePasswordUpdate() async {
    setState(() {
      _passwordError = null;
      _passwordSuccess = null;
    });

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      setState(() {
        _passwordError = "Please enter a new password.";
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _passwordError = "Password must be at least 6 characters long.";
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _passwordError = "Passwords do not match. Please re-enter.";
      });
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
    });

    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw const AuthException("Failed to update password.");
      }

      if (mounted) {
        setState(() {
          _passwordSuccess =
              "Your password has been updated successfully in Supabase.";
          _isUpdatingPassword = false;
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _passwordError = err is AuthException
              ? err.message
              : "Failed to update password. Please check your session.";
          _isUpdatingPassword = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text(
          "Are you sure you want to terminate your active session on this device?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await PushNotificationService().unregister('');
    } catch (e) {
      debugPrint("Push notification unregister error during logout: $e");
    }

    try {
      final authService = AuthService();
      await authService.logout();
    } catch (e) {
      debugPrint("AuthService logout error: $e");
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleHealthCheck() async {
    setState(() {
      _isCheckingHealth = true;
      _healthStatus = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      await ApiService().get('/health');
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _isCheckingHealth = false;
          _healthOk = true;
          _healthStatus = "${stopwatch.elapsedMilliseconds}ms";
        });
      }
    } catch (err) {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _isCheckingHealth = false;
          _healthOk = false;
          _healthStatus = "Issue (${stopwatch.elapsedMilliseconds}ms)";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeProvider.of(context);
    final isDark = themeController.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? Theme.of(context).appBarTheme.backgroundColor
            : AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context, isDark),
            _buildAppearanceCard(context, isDark, themeController),
            const SizedBox(height: 16),
            _buildAccountCard(context, isDark),
            const SizedBox(height: 16),
            _buildPasswordCard(context, isDark),
            const SizedBox(height: 16),
            _buildSessionCard(context, isDark),
            if (widget.isAdmin) ...[
              const SizedBox(height: 16),
              _buildAdminCard(context, isDark),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Settings",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isAdmin
                      ? Colors.red.withValues(alpha: 0.12)
                      : AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isAdmin
                        ? (isDark ? Colors.redAccent.shade100 : Colors.red)
                        : (isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 14,
                          color:
                              isDark ? Colors.redAccent.shade100 : Colors.red,
                        ),
                      ),
                    Text(
                      widget.isAdmin ? "Administrator" : "Personal Settings",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.isAdmin
                            ? (isDark ? Colors.redAccent.shade100 : Colors.red)
                            : (isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Manage your appearance preferences, account details, and security credentials.",
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // ==========================================
  // 1. APPEARANCE (LIGHT / DARK THEME SWITCHER)
  // ==========================================
  Widget _buildAppearanceCard(
    BuildContext context,
    bool isDark,
    ThemeController themeController,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.palette_outlined,
            iconBg: AppTheme.primaryColor.withValues(alpha: 0.12),
            iconColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
            title: "Appearance",
            subtitle:
                "Select a theme mode to customize the entire workspace appearance",
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primaryLight.withValues(alpha: 0.15)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isDark ? "Dark Mode Active" : "Light Mode Active",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Light Mode Option
                InkWell(
                  onTap: () => themeController.setThemeMode(ThemeMode.light),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: !isDark
                          ? AppTheme.primaryColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isDark
                            ? AppTheme.primaryColor
                            : (isDark
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder),
                        width: !isDark ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.light_mode,
                            color: Color(0xFFD97706),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Light Mode",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Clean white workspace with royal purple accents",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isDark)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Dark Mode Option
                InkWell(
                  onTap: () => themeController.setThemeMode(ThemeMode.dark),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.primaryLight.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.primaryLight
                            : (isDark
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder),
                        width: isDark ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFF312E81),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.dark_mode,
                            color: Color(0xFFA5B4FC),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Dark Mode",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Sleek dark slate palette for low-light comfort",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDark)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryLight,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Changes take effect immediately across all application pages, navigation, and dialogs, and persist on this device.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. MY ACCOUNT
  // ==========================================
  Widget _buildAccountCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.person_outline,
            iconBg: AppTheme.primaryColor.withValues(alpha: 0.12),
            iconColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
            title: "My Account",
            subtitle:
                "Authenticated profile details retrieved from Supabase and Render backend",
            action: OutlinedButton.icon(
              icon: const Icon(Icons.account_circle_outlined, size: 16),
              label: const Text(
                "View Profile",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(isAdmin: widget.isAdmin),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoadingUser
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFBCD1F4),
                        child: Text(
                          _userInitials,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF6A11CB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _userEmail,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isAdmin
                                    ? Colors.red.withValues(alpha: 0.12)
                                    : AppTheme.primaryColor
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.isAdmin ? "APP_ADMIN" : "APP_USER",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isAdmin
                                      ? (isDark
                                          ? Colors.redAccent.shade100
                                          : Colors.red)
                                      : (isDark
                                          ? AppTheme.primaryLight
                                          : AppTheme.primaryColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. CHANGE PASSWORD
  // ==========================================
  Widget _buildPasswordCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.lock_outline,
            iconBg: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFF991B1B),
            title: "Change Password",
            subtitle:
                "Update your authenticated password securely via Supabase Auth",
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_passwordSuccess != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _passwordSuccess!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _passwordSuccess = null),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_passwordError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _passwordError!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _passwordError = null),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _newPasswordController,
                  obscureText: !_showNewPassword,
                  enabled: !_isUpdatingPassword,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    hintText: "Enter new password",
                    helperText: "Minimum 6 characters",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _showNewPassword = !_showNewPassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  enabled: !_isUpdatingPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    hintText: "Re-enter new password",
                    helperText: "Must match new password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed:
                        _isUpdatingPassword ? null : _handlePasswordUpdate,
                    icon: _isUpdatingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock, size: 18),
                    label: Text(
                      _isUpdatingPassword
                          ? "Updating Password..."
                          : "Update Password",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. SESSION & SIGN OUT
  // ==========================================
  Widget _buildSessionCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.security_outlined,
            iconBg: AppTheme.primaryColor.withValues(alpha: 0.12),
            iconColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
            title: "Session & Sign Out",
            subtitle: "Terminate your active session on this device",
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Active Session ($_userEmail)",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Secured via Supabase Authentication with HTTPS Bearer Tokens.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text(
                      "Sign Out",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. ADMINISTRATOR TOOLS (APP_ADMIN ONLY)
  // ==========================================
  Widget _buildAdminCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.admin_panel_settings_outlined,
            iconBg: AppTheme.primaryColor.withValues(alpha: 0.12),
            iconColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
            title: "Administrator Tools",
            subtitle:
                "Backend-authorized administrator management and diagnostics",
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.redAccent.shade100 : Colors.red,
                ),
              ),
              child: Text(
                "APP_ADMIN Authorized",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.redAccent.shade100 : Colors.red,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Tool 1: User Management
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "User Management",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Review all registered workspace users, inspect global roles, and manage invitations.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UsersScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.people_outline, size: 16),
                        label: const Text(
                          "Open User Management",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Tool 2: Backend Health Diagnostic
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Backend Health Diagnostic",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_healthStatus != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _healthOk
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _healthStatus!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _healthOk
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Perform a real-time connectivity ping to the Render Spring Boot /health API.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            _isCheckingHealth ? null : _handleHealthCheck,
                        icon: _isCheckingHealth
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh, size: 16),
                        label: Text(
                          _isCheckingHealth
                              ? "Pinging..."
                              : "Run Health Check",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

