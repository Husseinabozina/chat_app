import 'package:flutter/material.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/presentation/chat_ui.dart';
import '../../../core/presentation/mingle_brand.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.preferences,
    required this.onEditProfile,
    required this.onLogout,
    super.key,
  });
  final AppPreferences preferences;
  final Future<void> Function() onEditProfile;
  final Future<void> Function() onLogout;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;
  Future<void> _save(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this setting. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your conversations will be here when you sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await widget.onLogout();
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 24, 8, 10),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MingleBackButton(),
      title: const Text('Settings'),
    ),
    body: MingleBackdrop(
      intensity: .35,
      child: ListenableBuilder(
        listenable: widget.preferences,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const MingleLogo(size: 52),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Make yourself at home.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'A few things, just the way you like them.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _heading('Appearance'),
            Card(
              child: RadioGroup<ThemeMode>(
                groupValue: widget.preferences.themeMode,
                onChanged: (value) {
                  if (value != null && !_busy) {
                    _save(() => widget.preferences.setThemeMode(value));
                  }
                },
                child: Column(
                  children: [
                    for (final mode in ThemeMode.values)
                      RadioListTile<ThemeMode>(
                        value: mode,
                        enabled: !_busy,
                        title: Text(switch (mode) {
                          ThemeMode.system => 'Use device setting',
                          ThemeMode.light => 'Light',
                          ThemeMode.dark => 'Dark',
                        }),
                      ),
                  ],
                ),
              ),
            ),
            _heading('Motion'),
            Card(
              child: SwitchListTile.adaptive(
                title: const Text('Reduce motion'),
                subtitle: const Text(
                  'Keep transitions and decorative movement still. Your device preference is always respected.',
                ),
                value: widget.preferences.reduceMotion,
                onChanged: _busy
                    ? null
                    : (value) => _save(
                        () => widget.preferences.setReduceMotion(value),
                      ),
              ),
            ),
            _heading('Account'),
            Card(
              child: ListTile(
                leading: const MingleIcon(MingleGlyph.edit),
                title: const Text('Edit profile'),
                trailing: const MingleIcon(MingleGlyph.next, size: 20),
                onTap: _busy ? null : widget.onEditProfile,
              ),
            ),
            _heading('Mingle'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const MingleIcon(MingleGlyph.chats),
                    title: const Text('About Mingle'),
                    trailing: const MingleIcon(MingleGlyph.next, size: 20),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Mingle',
                      applicationVersion: '1.0.0',
                      applicationIcon: const MingleLogo(size: 48),
                      children: [
                        const Text(
                          'Real conversations. Brighter days.\n\nA calm space for direct conversations.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _signOut,
              icon: const MingleIcon(MingleGlyph.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
}
