import 'package:flutter/material.dart';

import '../failures/app_failure.dart';

const blush = Color(0xFFC83279);
ThemeData backendTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: blush, brightness: brightness)
      .copyWith(
        primary: dark ? const Color(0xFFFF8FBC) : blush,
        surface: dark ? const Color(0xFF292327) : Colors.white,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF1C181B)
        : const Color(0xFFF8F4F6),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(16),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}

String friendlyError(Object error) => switch (error) {
  AppFailure(kind: FailureKind.unauthorized) =>
    'Please sign in again or check your details.',
  AppFailure(kind: FailureKind.conflict) =>
    'Those details are already in use. Please try another.',
  AppFailure(kind: FailureKind.validation) =>
    'Please check your details and try again.',
  AppFailure(kind: FailureKind.network) =>
    'Could not connect. Check your connection and try again.',
  _ => 'Something went wrong. Please try again.',
};
void showFailure(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(friendlyError(error))));

class InitialAvatar extends StatelessWidget {
  const InitialAvatar(this.name, {super.key, this.radius = 24});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase()),
  );
}

class StatusPanel extends StatelessWidget {
  const StatusPanel(
    this.message, {
    super.key,
    this.action,
    this.label = 'Retry',
  });
  final String message;
  final VoidCallback? action;
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton(onPressed: action, child: Text(label)),
            ),
        ],
      ),
    ),
  );
}

class WarmHeader extends StatelessWidget {
  const WarmHeader(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.surface,
        ],
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle),
            ],
          ),
        ),
        ExcludeSemantics(
          child: Icon(
            Icons.send_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}
