import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/presentation/chat_ui.dart';
import '../core/presentation/mingle_brand.dart';
import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/presentation/pages/backend_account_page.dart';
import '../features/media/presentation/media_scope.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import 'backend_app_services.dart';
import 'backend_main_shell.dart';

class BackendChatApp extends StatefulWidget {
  const BackendChatApp({required this.services, this.logoColor, super.key});
  final BackendAppServices services;
  final Color? logoColor;
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
    widget.services.preferences.addListener(_preferencesChanged);
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
      await Future.wait([
        widget.services.preferences.load(),
        widget.services.account.initialize(),
        // Keep the opening mark readable even when local storage resolves at once.
        Future<void>.delayed(const Duration(milliseconds: 800)),
      ]);
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
    widget.services.preferences.removeListener(_preferencesChanged);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _preferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigator,
    debugShowCheckedModeBanner: false,
    title: 'Mingle',
    theme: backendTheme(Brightness.light, logoColor: widget.logoColor),
    darkTheme: backendTheme(Brightness.dark, logoColor: widget.logoColor),
    themeMode: widget.services.preferences.themeMode,
    themeAnimationDuration: widget.services.preferences.reduceMotion
        ? Duration.zero
        : kThemeAnimationDuration,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations:
            MediaQuery.disableAnimationsOf(context) ||
            widget.services.preferences.reduceMotion,
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: mingleSystemOverlay(Theme.of(context).brightness),
        child: MediaScope(
          repository: widget.services.media,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
    home: _loading
        ? const MingleSplash()
        : _error != null
        ? Scaffold(
            body: StatusPanel(friendlyError(_error!), action: _initialize),
          )
        : !widget.services.preferences.onboardingComplete
        ? OnboardingPage(
            onFinished: widget.services.preferences.completeOnboarding,
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
