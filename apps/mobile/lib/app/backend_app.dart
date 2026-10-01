import 'dart:async';

import 'package:flutter/material.dart';

import '../core/presentation/chat_ui.dart';
import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/presentation/pages/backend_account_page.dart';
import 'backend_app_services.dart';
import 'backend_main_shell.dart';

class BackendChatApp extends StatefulWidget {
  const BackendChatApp({required this.services, super.key});
  final BackendAppServices services;
  @override
  State<BackendChatApp> createState() => _BackendChatAppState();
}

class _BackendChatAppState extends State<BackendChatApp>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  StreamSubscription<AuthUser?>? _subscription;
  AuthUser? _user;
  bool _loading = true;
  Object? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = widget.services.account.watchAuthState().listen(
      (user) {
        if (!mounted) return;
        if (_user?.id != user?.id) {
          _navigator.currentState?.popUntil((r) => r.isFirst);
        }
        setState(() => _user = user);
      },
      onError: (Object _) {
        /* Repository shows connection failures independently. */
      },
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.services.account.initialize();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_user == null) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.services.resume().catchError((Object _) {}));
    } else {
      widget.services.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigator,
    debugShowCheckedModeBanner: false,
    title: 'Mingle',
    theme: backendTheme(Brightness.light),
    darkTheme: backendTheme(Brightness.dark),
    home: _loading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _error != null
        ? Scaffold(
            body: StatusPanel(friendlyError(_error!), action: _initialize),
          )
        : _user == null
        ? BackendAccountPage(account: widget.services.account)
        : BackendMainShell(
            key: ValueKey(_user!.id),
            services: widget.services,
            user: _user!,
          ),
  );
}
