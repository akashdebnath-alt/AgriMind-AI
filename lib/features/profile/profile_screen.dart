
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _weatherAlertsEnabled = true;
  String _selectedLanguage = 'English';

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available soon.')),
    );
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
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile & Settings',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your account and preferences.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 24),

              _buildProfileCard(),

              const SizedBox(height: 24),

              _buildSectionTitle('Account'),
              _buildSettingsCard([
                _settingsTile(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: 'Manage your name and contact details',
                  onTap: () => _showComingSoon('Personal information'),
                ),
                _settingsTile(
                  icon: Icons.landscape_outlined,
                  title: 'My Farms',
                  subtitle: 'View and manage your registered farms',
                  onTap: () => _showComingSoon('Farm settings'),
                ),
                _settingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () => _showComingSoon('Password settings'),
                ),
              ]),

              const SizedBox(height: 24),

              _buildSectionTitle('Preferences'),
              _buildSettingsCard([
                ListTile(
                  leading: const Icon(
                    Icons.language,
                    color: AppColors.green,
                  ),
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
                      DropdownMenuItem(
                        value: 'Hindi',
                        child: Text('Hindi'),
                      ),
                      DropdownMenuItem(
                        value: 'Bengali',
                        child: Text('Bengali'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedLanguage = value;
                      });
                      _showComingSoon('Language translation');
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
                    setState(() {
                      _notificationsEnabled = value;
                    });
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
                    setState(() {
                      _weatherAlertsEnabled = value;
                    });
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
                    applicationLegalese:
                        'Smart agricultural assistance for farmers.',
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
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.darkGreen,
            AppColors.green,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 39,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: const Icon(
              Icons.person,
              size: 43,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Farmer Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Welcome to AgriMind AI',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showComingSoon('Edit profile'),
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
      child: Column(
        children: children,
      ),
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
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
    );
  }
}
