import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class MingleMotion {
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  static Duration duration(BuildContext context, {int milliseconds = 180}) =>
      reduced(context) ? Duration.zero : Duration(milliseconds: milliseconds);
}

class MingleTabs extends StatelessWidget {
  const MingleTabs({required this.index, required this.children, super.key});
  final int index;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => IndexedStack(
    index: index,
    children: [
      for (var i = 0; i < children.length; i++)
        TickerMode(
          enabled: index == i,
          child: AnimatedOpacity(
            opacity: index == i ? 1 : 0,
            duration: MingleMotion.duration(context),
            child: children[i],
          ),
        ),
    ],
  );
}

/// Pointer feedback does not replace the child's keyboard/semantic activation.
class MinglePress extends StatefulWidget {
  const MinglePress({required this.child, this.enabled = true, super.key});
  final Widget child;
  final bool enabled;
  @override
  State<MinglePress> createState() => _MinglePressState();
}

class _MinglePressState extends State<MinglePress> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => _pressed = true),
    onPointerUp: (_) => setState(() => _pressed = false),
    onPointerCancel: (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed && widget.enabled && !MingleMotion.reduced(context)
          ? .96
          : 1,
      duration: MingleMotion.duration(context, milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

class MinglePageTransitions extends PageTransitionsBuilder {
  const MinglePageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MingleMotion.reduced(context)) return child;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return const CupertinoPageTransitionsBuilder().buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return FadeTransition(opacity: animation, child: child);
  }
}

/// Only callers that have identified a genuinely new message opt in.
class MingleArrival extends StatefulWidget {
  const MingleArrival({required this.child, required this.animate, super.key});
  final Widget child;
  final bool animate;
  @override
  State<MingleArrival> createState() => _MingleArrivalState();
}

class _MingleArrivalState extends State<MingleArrival>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MingleMotion.reduced(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final t = Curves.easeOutCubic.transform(_controller.value);
      // Keep layout/read visibility bounds stable during this visual transition.
      return Opacity(
        opacity: .55 + .45 * t,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - t)),
          child: child,
        ),
      );
    },
  );
}

class MingleTyping extends StatefulWidget {
  const MingleTyping({super.key});
  @override
  State<MingleTyping> createState() => _MingleTypingState();
}

class _MingleTypingState extends State<MingleTyping>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MingleMotion.reduced(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('typing…', style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(width: 7),
      ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final lift = MingleMotion.reduced(context)
                  ? 0.0
                  : math.max(
                          0.0,
                          math.sin(_controller.value * math.pi * 2 - i * .8),
                        ) *
                        3;
              return Transform.translate(
                offset: Offset(0, -lift),
                child: Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ],
  );
}
