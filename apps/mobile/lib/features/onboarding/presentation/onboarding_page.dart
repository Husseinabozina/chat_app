import 'package:flutter/material.dart';

import '../../../core/presentation/chat_ui.dart';
import '../../../core/presentation/mingle_brand.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.onFinished,
    this.replay = false,
    super.key,
  });
  final Future<void> Function() onFinished;
  final bool replay;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _index = 0;
  bool _busy = false;
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

  void _next() {
    if (MingleMotion.reduced(context)) {
      _pages.jumpToPage(_index + 1);
    } else {
      _pages.animateToPage(
        _index + 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
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
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: TextButton(
                  onPressed: _busy ? null : _finish,
                  child: Text(widget.replay ? 'Close' : 'Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
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
                                  Container(
                                    width: 144,
                                    height: 144,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: .7),
                                      borderRadius: BorderRadius.circular(48),
                                    ),
                                    child: Center(
                                      child: MingleIcon(
                                        i == 1
                                            ? MingleGlyph.people
                                            : MingleGlyph.chats,
                                        size: 76,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
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
                              Container(
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
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    MinglePress(
                      enabled: !_busy,
                      child: FilledButton(
                        onPressed: _busy
                            ? null
                            : _index == _copy.length - 1
                            ? _finish
                            : _next,
                        child: Text(
                          _busy
                              ? 'Please wait…'
                              : _index == _copy.length - 1
                              ? widget.replay
                                    ? 'Done'
                                    : 'Get started'
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
