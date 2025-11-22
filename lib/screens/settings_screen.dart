import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.headlineMedium,
        ),
        backgroundColor: theme.canvasColor,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // App Section
            _buildSettingsSection(
              context,
              'App Settings',
              [
                _buildSwitchListTile(
                  context,
                  'Dark Mode',
                  'Enable dark theme',
                  themeProvider.isDarkMode,
                  (value) {
                    themeProvider.isDarkMode = value ?? false;
                  },
                ),
                _buildListTile(
                  context,
                  'Font Size',
                  'Adjust text size',
                  Icons.text_fields,
                  () {
                    // TODO: Implement font size adjustment
                  },
                ),
                _buildSwitchListTile(
                  context,
                  'Reduce Motion',
                  'Reduce animation effects',
                  themeProvider.reduceMotion,
                  (value) {
                    themeProvider.reduceMotion = value ?? false;
                  },
                ),
                _buildSwitchListTile(
                  context,
                  'High Contrast',
                  'Enhanced color contrast',
                  themeProvider.highContrast,
                  (value) {
                    themeProvider.highContrast = value ?? false;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Chat Section
            _buildSettingsSection(
              context,
              'Chat Settings',
              [
                _buildSwitchListTile(
                  context,
                  'Enable Markdown',
                  'Support for markdown formatting',
                  true,
                  (value) {
                    // TODO: Implement markdown toggle
                  },
                ),
                _buildSwitchListTile(
                  context,
                  'Enable Streaming',
                  'Real-time message streaming',
                  true,
                  (value) {
                    // TODO: Implement streaming toggle
                  },
                ),
                _buildSwitchListTile(
                  context,
                  'Speech to Text',
                  'Voice input support',
                  true,
                  (value) {
                    // TODO: Implement speech-to-text toggle
                  },
                ),
                _buildListTile(
                  context,
                  'Max Message History',
                  'Number of messages to keep',
                  Icons.history,
                  () {
                    // TODO: Implement message history limit
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Language Section
            _buildSettingsSection(
              context,
              'Language & Region',
              [
                _buildListTile(
                  context,
                  'Language',
                  'English (United States)',
                  Icons.language,
                  () {
                    // TODO: Implement language selection
                  },
                ),
                _buildSwitchListTile(
                  context,
                  'RTL Support',
                  'Right-to-left text direction',
                  false,
                  (value) {
                    // TODO: Implement RTL support
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // About Section
            _buildSettingsSection(
              context,
              'About',
              [
                _buildListTile(
                  context,
                  'Version',
                  '1.0.0',
                  Icons.info,
                  () {},
                ),
                _buildListTile(
                  context,
                  'Privacy Policy',
                  'Read our privacy policy',
                  Icons.privacy_tip,
                  () {
                    // TODO: Open privacy policy
                  },
                ),
                _buildListTile(
                  context,
                  'Terms of Service',
                  'Read our terms',
                  Icons.description,
                  () {
                    // TODO: Open terms of service
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.iconTheme.color?.withOpacity(0.6),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchListTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool?) onChanged,
  ) {
    final theme = Theme.of(context);
    
    return SwitchListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
      inactiveThumbColor: theme.canvasColor,
      inactiveTrackColor: theme.dividerColor,
    );
  }
}