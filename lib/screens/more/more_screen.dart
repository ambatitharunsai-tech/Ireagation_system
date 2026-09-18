import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/iot_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/api_keys.dart';
import '../tasks/task_screen.dart';
import '../ai/ai_chat_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final iot = Provider.of<IoTProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    
    String t(String key) => langProvider.t(key);

    return Scaffold(
      appBar: AppBar(title: Text(t('More'))),
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
                        user?.name ?? t('Farmer'),
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
          Text(
            t('Features'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildTile(
            context,
            icon: Icons.task_alt,
            color: Colors.orange,
            title: t('Farm Tasks'),
            subtitle: t('Manage tasks'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaskScreen()),
            ),
          ),

          _buildTile(
            context,
            icon: Icons.smart_toy,
            color: Colors.green,
            title: t('AI Assistant'),
            subtitle: t('Get advice'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            ),
          ),

          _buildTile(
            context,
            icon: Icons.notifications_outlined,
            color: Colors.red,
            title: t('Alerts'),
            subtitle: '${iot.unreadAlertCount} ${t('unread alerts')}',
            badge: iot.unreadAlertCount > 0 ? '${iot.unreadAlertCount}' : null,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('View alerts from the IoT tab → 🔔 icon'),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Settings section
          Text(
            t('Settings'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          
          _buildTile(
            context,
            icon: Icons.vpn_key,
            color: Colors.purple,
            title: t('API Keys'),
            subtitle: t('Configure Gemini & IoT'),
            onTap: () => _showApiKeysDialog(context, langProvider),
          ),
          _buildTile(
            context,
            icon: Icons.language,
            color: Colors.blue,
            title: t('Language'),
            subtitle: langProvider.currentLanguage,
            onTap: () => _showLanguageDialog(langProvider),
          ),

          _buildTile(
            context,
            icon: Icons.info_outline,
            color: Colors.grey,
            title: t('About'),
            subtitle: t('Smart Agriculture'),
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
            title: t('Logout'),
            subtitle: t('Sign out'),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLanguageDialog(LanguageProvider langProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(langProvider.t('Select Language')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: langProvider.supportedLanguages.length,
            itemBuilder: (context, index) {
              final lang = langProvider.supportedLanguages[index];
              return ListTile(
                title: Text(lang),
                trailing: langProvider.currentLanguage == lang
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  langProvider.setLanguage(lang);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(langProvider.t('Cancel')),
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

  void _showApiKeysDialog(BuildContext context, LanguageProvider lang) {
    final geminiCtrl = TextEditingController(text: ApiKeys.geminiKey);
    final tsChannelCtrl = TextEditingController(text: ApiKeys.thingSpeakChannelId);
    final tsKeyCtrl = TextEditingController(text: ApiKeys.thingSpeakReadKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('API Configuration')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: geminiCtrl,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AI Studio Key',
                  prefixIcon: const Icon(Icons.auto_awesome),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tsChannelCtrl,
                decoration: InputDecoration(
                  labelText: 'ThingSpeak Channel ID',
                  prefixIcon: const Icon(Icons.cloud),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tsKeyCtrl,
                decoration: InputDecoration(
                  labelText: 'ThingSpeak Read Key',
                  prefixIcon: const Icon(Icons.key),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.t('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              ApiKeys.setGeminiKey(geminiCtrl.text);
              ApiKeys.setThingSpeakKeys(tsChannelCtrl.text, tsKeyCtrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.t('API keys saved locally!'))),
              );
            },
            child: Text(lang.t('Save')),
          ),
        ],
      ),
    );
  }

}