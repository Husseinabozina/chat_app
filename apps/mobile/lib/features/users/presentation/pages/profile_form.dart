import 'package:flutter/material.dart';

import '../../../../core/presentation/chat_ui.dart';
import '../../domain/users_repository.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({
    required this.users,
    required this.profile,
    required this.onSaved,
    this.completing = false,
    this.onLogout,
    super.key,
  });
  final UsersRepository users;
  final UserProfile profile;
  final ValueChanged<UserProfile> onSaved;
  final bool completing;
  final VoidCallback? onLogout;
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.displayName);
  late final _username = TextEditingController(text: widget.profile.username);
  late final _bio = TextEditingController(text: widget.profile.bio);
  bool _busy = false;
  String? _error;
  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await widget.users.updateMe(
        username: _username.text,
        displayName: _name.text,
        bio: _bio.text,
      );
      if (mounted) widget.onSaved(p);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.completing ? 'Complete your profile' : 'Edit profile'),
      actions: [
        if (widget.onLogout != null)
          TextButton(
            onPressed: _busy ? null : widget.onLogout,
            child: const Text('Sign out'),
          ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: InitialAvatar(widget.profile.label, radius: 42)),
                const SizedBox(height: 24),
                if (widget.completing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Choose the name people will see and a username they can find.',
                    ),
                  ),
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter a display name.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _username,
                  enabled: !_busy,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixText: '@',
                  ),
                  validator: (v) =>
                      v == null ||
                          !RegExp(r'^[a-zA-Z0-9_]{3,40}$').hasMatch(v.trim())
                      ? 'Use 3–40 letters, numbers or underscores.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bio,
                  enabled: !_busy,
                  maxLength: 280,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio (optional)',
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(
                    _busy
                        ? 'Saving…'
                        : (widget.completing
                              ? 'Start chatting'
                              : 'Save profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
