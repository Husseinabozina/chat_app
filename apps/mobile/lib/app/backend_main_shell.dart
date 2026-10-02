import 'dart:async';

import 'package:flutter/material.dart';

import '../core/presentation/chat_ui.dart';
import '../features/auth/domain/entities/auth_user.dart';
import '../features/conversations/presentation/pages/chats_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/users/domain/users_repository.dart';
import '../features/users/presentation/pages/people_page.dart';
import '../features/users/presentation/pages/profile_form.dart';
import 'backend_app_services.dart';

class BackendMainShell extends StatefulWidget {
  const BackendMainShell({
    required this.services,
    required this.user,
    super.key,
  });
  final BackendAppServices services;
  final AuthUser user;
  @override
  State<BackendMainShell> createState() => _BackendMainShellState();
}

class _BackendMainShellState extends State<BackendMainShell> {
  UserProfile? _profile;
  Object? _error;
  int _tab = 0;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await widget.services.users.getMe();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await widget.services.account.logout();
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => ProfileForm(
          users: widget.services.users,
          profile: _profile!,
          onSaved: (p) => Navigator.of(context).pop(p),
        ),
      ),
    );
    if (mounted && saved != null) setState(() => _profile = saved);
  }

  Future<void> _newChat() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          leading: const MingleBackButton(),
          title: const Text('New conversation'),
        ),
        body: MingleBackdrop(
          child: SafeArea(
            child: PeoplePage(
              users: widget.services.users,
              conversations: widget.services.conversations,
              currentUserId: widget.user.id,
              selectForConversation: true,
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _settings() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SettingsPage(
        preferences: widget.services.preferences,
        onEditProfile: _edit,
        onLogout: _logout,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          actions: [
            TextButton(onPressed: _logout, child: const Text('Sign out')),
          ],
        ),
        body: StatusPanel(friendlyError(_error!), action: _load),
      );
    }
    final p = _profile!;
    if (!p.isComplete) {
      return ProfileForm(
        users: widget.services.users,
        profile: p,
        completing: true,
        onLogout: _logout,
        onSaved: (p) => setState(() => _profile = p),
      );
    }
    return Scaffold(
      body: MingleBackdrop(
        child: SafeArea(
          child: MingleTabs(
            index: _tab,
            children: [
              ChatsPage(
                repository: widget.services.conversations,
                users: widget.services.users,
                currentUserId: widget.user.id,
                onFindPeople: () => setState(() => _tab = 1),
                onNewChat: _newChat,
              ),
              PeoplePage(
                users: widget.services.users,
                conversations: widget.services.conversations,
                currentUserId: widget.user.id,
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const WarmHeader('Your profile', 'A little about you.'),
                    const SizedBox(height: 24),
                    Center(
                      child: InitialAvatar(
                        p.label,
                        radius: 54,
                        avatarUrl: p.avatarUrl,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      p.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '@${p.username}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (p.bio?.isNotEmpty ?? false)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(p.bio!),
                        ),
                      ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _edit,
                      icon: const MingleIcon(MingleGlyph.edit, size: 20),
                      label: const Text('Edit profile'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _settings,
                      icon: const MingleIcon(MingleGlyph.settings, size: 20),
                      label: const Text('Settings'),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const MingleIcon(MingleGlyph.logout, size: 20),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MingleNavigation(
        selectedIndex: _tab,
        onSelected: (i) => setState(() => _tab = i),
      ),
    );
  }
}
