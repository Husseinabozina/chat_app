import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mingle_motion.dart';

/// A brief send-and-arrive scene, then a quiet still illustration.
class MingleEmptyArt extends StatefulWidget {
  const MingleEmptyArt({super.key});
  @override
  State<MingleEmptyArt> createState() => _MingleEmptyArtState();
}

class _MingleEmptyArtState extends State<MingleEmptyArt>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MingleMotion.reduced(context)) {
      _motion.value = 1;
    } else if (!_started) {
      _motion.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        width: 252,
        height: 188,
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => CustomPaint(
            painter: _ConversationScene(
              _motion.value,
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ConversationScene extends CustomPainter {
  const _ConversationScene(this.progress, this.dark);
  final double progress;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 224);
    final teal = dark ? const Color(0xFF9CCEC8) : const Color(0xFF285E67);
    final paper = dark ? const Color(0xFF33444D) : const Color(0xFFFFFCF5);
    final soft = dark ? const Color(0xFF23363F) : const Color(0xFFF1E9E1);
    final coral = dark ? const Color(0xFFF5AC9C) : const Color(0xFFED998F);
    final arrive = Curves.easeOutCubic.transform(progress);
    final reply = Curves.easeOutCubic.transform(
      ((progress - .3) / .7).clamp(0.0, 1.0),
    );
    Paint fill(Color color) => Paint()..color = color;
    canvas.drawOval(const Rect.fromLTWH(40, 29, 221, 174), fill(soft));
    canvas.drawOval(
      const Rect.fromLTWH(75, 199, 150, 9),
      fill(teal.withValues(alpha: .08)),
    );
    // The dashed route makes the plane read as a sent message.
    final trail = Path()
      ..moveTo(41, 139)
      ..cubicTo(2, 87, 60, 53, 89, 88)
      ..cubicTo(117, 124, 57, 154, 65, 103)
      ..cubicTo(70, 69, 110, 50, 170, 53);
    final stroke = Paint()
      ..color = teal.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final metric in trail.computeMetrics()) {
      for (double d = 0; d < metric.length * arrive; d += 11) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 4, metric.length)),
          stroke,
        );
      }
    }
    // A rear reply card slides in a little later than the main card.
    canvas.save();
    canvas.translate(12 * (1 - reply), 9 * (1 - reply));
    final rear = RRect.fromRectAndRadius(
      const Rect.fromLTWH(150, 103, 106, 72),
      const Radius.circular(20),
    );
    canvas.drawRRect(rear, fill(teal.withValues(alpha: .1 + .9 * reply)));
    canvas.drawPath(
      Path()
        ..moveTo(222, 171)
        ..lineTo(244, 186)
        ..lineTo(241, 164)
        ..close(),
      fill(teal),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(181 + i * 20, 139),
        4,
        fill(paper.withValues(alpha: .85)),
      );
    }
    canvas.restore();
    // Main message, with a subtle paper edge and a clear bubble tail.
    final front = Path()
      ..moveTo(75, 76)
      ..lineTo(161, 76)
      ..quadraticBezierTo(182, 76, 182, 97)
      ..lineTo(182, 141)
      ..quadraticBezierTo(182, 162, 161, 162)
      ..lineTo(103, 162)
      ..lineTo(78, 182)
      ..lineTo(81, 162)
      ..lineTo(75, 162)
      ..quadraticBezierTo(54, 162, 54, 141)
      ..lineTo(54, 97)
      ..quadraticBezierTo(54, 76, 75, 76)
      ..close();
    canvas.drawShadow(front, Colors.black.withValues(alpha: .16), 8, false);
    canvas.drawPath(front, fill(paper));
    canvas.drawPath(
      front,
      Paint()
        ..color = teal.withValues(alpha: .12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final line = Paint()
      ..color = teal.withValues(alpha: .55)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(78, 108), const Offset(154, 108), line);
    canvas.drawLine(const Offset(78, 126), const Offset(133, 126), line);
    // Folded paper plane, arriving along a short arc and settling for capture.
    canvas.save();
    canvas.translate(-32 * (1 - arrive), 22 * (1 - arrive));
    final plane = Path()
      ..moveTo(150, 56)
      ..lineTo(248, 20)
      ..quadraticBezierTo(254, 18, 252, 25)
      ..lineTo(224, 108)
      ..quadraticBezierTo(222, 114, 217, 109)
      ..lineTo(193, 83)
      ..lineTo(174, 99)
      ..lineTo(176, 70)
      ..close();
    canvas.drawShadow(plane, Colors.black.withValues(alpha: .16), 4, false);
    canvas.drawPath(plane, fill(coral));
    canvas.drawPath(
      Path()
        ..moveTo(150, 56)
        ..lineTo(240, 29)
        ..lineTo(176, 70)
        ..close(),
      fill(const Color(0xFFFFE9DC)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(176, 70)
        ..lineTo(240, 29)
        ..lineTo(193, 83)
        ..lineTo(174, 99)
        ..close(),
      fill(const Color(0xFFBC6D70)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(176, 70)
        ..lineTo(240, 29)
        ..lineTo(182, 77)
        ..lineTo(174, 99)
        ..close(),
      fill(const Color(0xFFF3B6A2)),
    );
    canvas.restore();
    // Small botanical details echo the app's existing illustrated backdrop.
    final stem = Paint()
      ..color = teal.withValues(alpha: .5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(248, 200)
        ..quadraticBezierTo(241, 181, 263, 165),
      stem,
    );
    canvas.drawOval(
      const Rect.fromLTWH(246, 166, 17, 9),
      fill(teal.withValues(alpha: .45)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(237, 182, 16, 8),
      fill(teal.withValues(alpha: .3)),
    );
    canvas.drawCircle(
      const Offset(40, 183),
      4,
      fill(coral.withValues(alpha: .5)),
    );
    canvas.drawCircle(
      const Offset(270, 82),
      3,
      fill(teal.withValues(alpha: .3)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ConversationScene oldDelegate) =>
      progress != oldDelegate.progress || dark != oldDelegate.dark;
}
