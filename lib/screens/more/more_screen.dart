import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/iot_provider.dart';
import '../../config/api_keys.dart';
import '../tasks/task_screen.dart';
import '../ai/ai_chat_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final iot = Provider.of<IoTProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      (user?.name ?? 'F')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Farmer',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user?.farmName != null)
                        Text(
                          user!.farmName!,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      if (user?.email != null)
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Features section
          const Text(
            'Features',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildTile(
            context,
            icon: Icons.task_alt,
            color: Colors.orange,
            title: 'Farm Tasks',
            subtitle: 'Manage planting, watering & harvest tasks',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaskScreen()),
            ),
          ),

          _buildTile(
            context,
            icon: Icons.smart_toy,
            color: Colors.green,
            title: 'AI Assistant',
            subtitle: 'Get smart farming advice',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            ),
          ),

          _buildTile(
            context,
            icon: Icons.notifications_outlined,
            color: Colors.red,
            title: 'Alerts',
            subtitle: '${iot.unreadAlertCount} unread alerts',
            badge: iot.unreadAlertCount > 0 ? '${iot.unreadAlertCount}' : null,
            onTap: () {
              // Navigate to IoT tab alerts
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('View alerts from the IoT tab → 🔔 icon'),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Settings section
          const Text(
            'Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildTile(
            context,
            icon: Icons.language,
            color: Colors.blue,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),

          _buildTile(
            context,
            icon: Icons.dark_mode_outlined,
            color: Colors.indigo,
            title: 'Appearance',
            subtitle: 'Light mode',
            onTap: () {},
          ),

          _buildTile(
            context,
            icon: Icons.key,
            color: Colors.deepPurple,
            title: 'API Keys',
            subtitle: ApiKeys.hasGeminiKey
                ? 'Gemini AI configured ✅'
                : 'Configure Gemini AI key',
            onTap: () => _showApiKeyDialog(context),
          ),

          _buildTile(
            context,
            icon: Icons.cloud_outlined,
            color: Colors.teal,
            title: 'Supabase Sync',
            subtitle: 'Connected to cloud database',
            onTap: () {},
          ),

          _buildTile(
            context,
            icon: Icons.info_outline,
            color: Colors.grey,
            title: 'About',
            subtitle: 'Smart Agriculture v1.0.0',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Smart Agriculture',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 Smart Agriculture',
              children: [
                const SizedBox(height: 12),
                const Text(
                  'A comprehensive farm management app with '
                  'IoT sensor monitoring, crop tracking, '
                  'finance management, and AI-powered farming advice.',
                ),
              ],
            ),
          ),
          _buildTile(
            context,
            icon: Icons.logout,
            color: Colors.red,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final geminiCtrl = TextEditingController(text: ApiKeys.geminiKey);
    final tsChannelCtrl = TextEditingController(
      text: ApiKeys.thingSpeakChannelId,
    );
    final tsKeyCtrl = TextEditingController(text: ApiKeys.thingSpeakReadKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Keys'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini AI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Get free key at aistudio.google.com/apikey',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: geminiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIza...',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              const Text(
                'ThingSpeak (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect real IoT sensors from ThingSpeak',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tsChannelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Channel ID',
                  hintText: '123456',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tsKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Read API Key',
                  hintText: 'ABCD1234...',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ApiKeys.setGeminiKey(geminiCtrl.text);
              ApiKeys.setThingSpeakKeys(tsChannelCtrl.text, tsKeyCtrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ApiKeys.hasGeminiKey
                        ? '✅ Gemini AI key saved!'
                        : 'Keys cleared. Using offline mode.',
                  ),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
