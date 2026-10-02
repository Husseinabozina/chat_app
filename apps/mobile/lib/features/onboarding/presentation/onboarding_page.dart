import 'package:flutter/material.dart';

import '../../../core/presentation/chat_ui.dart';
import '../../../core/presentation/mingle_brand.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.onFinished, super.key});
  final Future<void> Function() onFinished;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _index = 0;
  bool _busy = false;
  bool _moving = false;
  String? _error;
  static const _copy = [
    (
      'Good chats.\nBrighter days.',
      'A calmer place to connect, share ideas, and be yourself.',
    ),
    (
      'A name away\nfrom hello.',
      'Find someone by name or username, visit their profile, and start a conversation.',
    ),
    (
      'Keep the\nconversation going.',
      'Send messages, reply to a thought, and pick up where you left off.',
    ),
  ];

  Future<void> _finish() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onFinished();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save your choice. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(int page) async {
    if (_busy || _moving || !_pages.hasClients) return;
    setState(() => _moving = true);
    try {
      if (MingleMotion.reduced(context)) {
        _pages.jumpToPage(page);
      } else {
        await _pages.animateToPage(
          page,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: MingleBackdrop(
      intensity: .65,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  if (_index > 0)
                    IconButton(
                      tooltip: 'Previous page',
                      onPressed: _busy || _moving
                          ? null
                          : () => _move(_index - 1),
                      icon: const MingleIcon(MingleGlyph.back),
                    )
                  else
                    const SizedBox(width: 48, height: 48),
                  const Spacer(),
                  TextButton(
                    onPressed: _busy ? null : _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                physics: _busy ? const NeverScrollableScrollPhysics() : null,
                itemCount: _copy.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (i == 0)
                                  const MingleBrand(size: 112)
                                else
                                  _IntroductionScene(people: i == 1),
                                const SizedBox(height: 32),
                                Text(
                                  _copy[i].$1,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _copy[i].$2,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Page ${_index + 1} of ${_copy.length}',
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _copy.length; i++)
                              AnimatedContainer(
                                duration: MingleMotion.duration(
                                  context,
                                  milliseconds: 180,
                                ),
                                curve: Curves.easeOutCubic,
                                width: i == _index ? 24 : 7,
                                height: 7,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: i == _index
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    MinglePress(
                      enabled: !_busy && !_moving,
                      child: FilledButton(
                        onPressed: _busy || _moving
                            ? null
                            : _index == _copy.length - 1
                            ? _finish
                            : () => _move(_index + 1),
                        child: Text(
                          _busy
                              ? 'Please wait…'
                              : _index == _copy.length - 1
                              ? 'Get started'
                              : 'Continue',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Decorative examples explain the real People and messaging flows.
/// They are not controls or accounts returned by the backend.
class _IntroductionScene extends StatelessWidget {
  const _IntroductionScene({required this.people});
  final bool people;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: people
                  ? [
                      Row(
                        children: [
                          MingleIcon(
                            MingleGlyph.search,
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Find a familiar name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _IntroductionPerson(
                        name: 'Nour',
                        username: '@nour',
                      ),
                      const SizedBox(height: 16),
                      const _IntroductionPerson(
                        name: 'Omar',
                        username: '@omar',
                      ),
                    ]
                  : [
                      const _IntroductionPerson(
                        name: 'Nour',
                        username: 'A little hello goes a long way',
                      ),
                      const SizedBox(height: 20),
                      _IntroductionBubble(
                        text: 'Hi! How’s your day?',
                        own: false,
                      ),
                      const SizedBox(height: 10),
                      _IntroductionBubble(
                        text: 'Better with a good chat.',
                        own: true,
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroductionPerson extends StatelessWidget {
  const _IntroductionPerson({required this.name, required this.username});
  final String name;
  final String username;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      InitialAvatar(name, radius: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleSmall),
            Text(
              username,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _IntroductionBubble extends StatelessWidget {
  const _IntroductionBubble({required this.text, required this.own});
  final String text;
  final bool own;
  @override
  Widget build(BuildContext context) => Align(
    alignment: own
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 215),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: own
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadiusDirectional.only(
          topStart: const Radius.circular(18),
          topEnd: const Radius.circular(18),
          bottomStart: Radius.circular(own ? 18 : 5),
          bottomEnd: Radius.circular(own ? 5 : 18),
        ),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    ),
  );
}
