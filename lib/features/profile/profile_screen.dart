import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_storage.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenFarms;

  const ProfileScreen({super.key, this.onOpenFarms});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  bool _notificationsEnabled = true;
  bool _weatherAlertsEnabled = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cached = AuthStorage.getUser();
    if (cached != null) {
      _user = cached;
      _selectedLanguage = cached.language;
      _notificationsEnabled = cached.notificationsEnabled;
      _weatherAlertsEnabled = cached.weatherAlertsEnabled;
    }

    try {
      final user = await ApiService().getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _selectedLanguage = user.language;
          _notificationsEnabled = user.notificationsEnabled;
          _weatherAlertsEnabled = user.weatherAlertsEnabled;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePreferences({
    String? language,
    bool? notifications,
    bool? weatherAlerts,
  }) async {
    try {
      final updated = await ApiService().updateProfile(
        language: language,
        notificationsEnabled: notifications,
        weatherAlertsEnabled: weatherAlerts,
      );
      if (mounted) {
        setState(() {
          _user = updated;
          if (language != null) _selectedLanguage = updated.language;
          if (notifications != null) {
            _notificationsEnabled = updated.notificationsEnabled;
          }
          if (weatherAlerts != null) {
            _weatherAlertsEnabled = updated.weatherAlertsEnabled;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _user?.fullName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update your display name:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              Navigator.pop(ctx);
              try {
                final updated = await ApiService().updateProfile(
                  fullName: newName,
                );
                if (mounted) {
                  setState(() => _user = updated);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (min 8 characters)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final current = currentPassController.text;
              final newPass = newPassController.text;
              if (current.isEmpty || newPass.isEmpty) return;
              if (newPass.length < 8) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('New password must be at least 8 chars'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);

              try {
                await ApiService().changePassword(current, newPass);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showServerSettingsDialog() {
    final controller = TextEditingController(text: AuthStorage.getBaseUrl());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Backend Base URL:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://127.0.0.1:8000/api/v1',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await AuthStorage.saveBaseUrl(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                _loadProfile();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Server URL set to: ${AuthStorage.getBaseUrl()}',
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPersonalInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person, color: AppColors.green),
              title: const Text('Full Name'),
              subtitle: Text(_user?.fullName ?? 'Not set'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: AppColors.green),
              title: const Text('Email Address'),
              subtitle: Text(_user?.email ?? 'farmer@example.com'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: AppColors.green),
              title: const Text('Language'),
              subtitle: Text(_selectedLanguage),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditProfileDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature will be available soon.')));
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'Are you sure you want to log out of AgriMind AI?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                Navigator.pop(dialogContext);
                await AuthStorage.clearAuth();
                if (!mounted) return;
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.displayName ?? 'Farmer Account';
    final emailText = _user?.email ?? 'Welcome to AgriMind AI';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile & Settings',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.green,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your account and preferences.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),

              const SizedBox(height: 24),

              _buildProfileCard(displayName, emailText),

              const SizedBox(height: 24),

              _buildSectionTitle('Account'),
              _buildSettingsCard([
                _settingsTile(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: 'Manage your name and contact details',
                  onTap: _showPersonalInfo,
                ),
                _settingsTile(
                  icon: Icons.landscape_outlined,
                  title: 'My Farms',
                  subtitle: 'View and manage your registered farms',
                  onTap:
                      widget.onOpenFarms ??
                      () => _showComingSoon('Farm settings'),
                ),
                _settingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: _showChangePasswordDialog,
                ),
                _settingsTile(
                  icon: Icons.cloud_sync_outlined,
                  title: 'Backend Server Connection',
                  subtitle: AuthStorage.getBaseUrl(),
                  onTap: _showServerSettingsDialog,
                ),
              ]),

              const SizedBox(height: 24),

              _buildSectionTitle('Preferences'),
              _buildSettingsCard([
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.green),
                  title: const Text(
                    'Language',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Choose your app language'),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                      DropdownMenuItem(
                        value: 'Bengali',
                        child: Text('Bengali'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _updatePreferences(language: value);
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.green,
                  ),
                  title: const Text(
                    'Notifications',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Receive app notifications'),
                  activeThumbColor: AppColors.green,
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    _updatePreferences(notifications: value);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.cloud_outlined,
                    color: AppColors.green,
                  ),
                  title: const Text(
                    'Weather Alerts',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Receive weather notifications'),
                  activeThumbColor: AppColors.green,
                  value: _weatherAlertsEnabled,
                  onChanged: (value) {
                    _updatePreferences(weatherAlerts: value);
                  },
                ),
              ]),

              const SizedBox(height: 24),

              _buildSectionTitle('Support'),
              _buildSettingsCard([
                _settingsTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get assistance with the application',
                  onTap: () => _showComingSoon('Help and support'),
                ),
                _settingsTile(
                  icon: Icons.info_outline,
                  title: 'About AgriMind AI',
                  subtitle: 'Learn more about our application',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'AgriMind AI',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Smart agricultural assistance for farmers with FAO-56 irrigation planning.',
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _showLogoutConfirmation,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  'AgriMind AI • Version 1.0.0',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(String displayName, String emailText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, AppColors.green],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 39,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: const Icon(Icons.person, size: 43, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            emailText,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGreen,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.green),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
