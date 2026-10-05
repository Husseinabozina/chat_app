import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mingle_empty_art.dart';
import 'mingle_motion.dart';

/// Mingle's original rounded vector vocabulary. These are decorative glyphs;
/// the surrounding controls own labels, hit targets and accessibility actions.
enum MingleGlyph {
  chats,
  people,
  profile,
  search,
  compose,
  plane,
  close,
  check,
  read,
  edit,
  logout,
  mail,
  lock,
  eye,
  eyeOff,
  back,
  next,
  reply,
  copy,
  trash,
  settings,
  photo,
  camera,
}

class MingleIcon extends StatefulWidget {
  const MingleIcon(
    this.glyph, {
    this.size = 24,
    this.color,
    this.selected = false,
    super.key,
  });
  final MingleGlyph glyph;
  final double size;
  final Color? color;
  final bool selected;
  @override
  State<MingleIcon> createState() => _MingleIconState();
}

class _MingleIconState extends State<MingleIcon>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: widget.selected ? 1 : 0,
  );
  @override
  void didUpdateWidget(MingleIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _animate();
  }

  void _animate() {
    final target = widget.selected ? 1.0 : 0.0;
    if (MingleMotion.reduced(context)) {
      _controller.value = target;
    } else {
      _controller.animateTo(target, curve: Curves.easeOutCubic);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MingleMotion.reduced(context)) {
      _controller.stop();
      _controller.value = widget.selected ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _GlyphPainter(
          widget.glyph,
          widget.color ??
              IconTheme.of(context).color ??
              Theme.of(context).colorScheme.onSurface,
          _controller.value,
          Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color, this.selection, this.rtl);
  final MingleGlyph glyph;
  final Color color;
  final double selection;
  final bool rtl;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32, size.height / 32);
    if (rtl &&
        {
          MingleGlyph.back,
          MingleGlyph.next,
          MingleGlyph.reply,
          MingleGlyph.logout,
        }.contains(glyph)) {
      canvas.translate(32, 0);
      canvas.scale(-1, 1);
    }
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), ink);
    void circle(double x, double y, double r) =>
        canvas.drawCircle(Offset(x, y), r, ink);
    void path(Path p, {bool fill = false}) {
      if (fill && selection > 0) {
        canvas.drawPath(
          p,
          Paint()..color = color.withValues(alpha: .16 * selection),
        );
      }
      canvas.drawPath(p, ink);
    }

    void round(double l, double t, double r, double b, double radius) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(l, t, r, b),
            Radius.circular(radius),
          ),
          ink,
        );
    switch (glyph) {
      case MingleGlyph.photo:
        round(3, 5, 29, 27, 5);
        circle(22, 11, 2);
        path(
          Path()
            ..moveTo(4, 24)
            ..lineTo(12, 15)
            ..lineTo(19, 23)
            ..lineTo(24, 18)
            ..lineTo(29, 24),
        );
      case MingleGlyph.camera:
        round(3, 9, 29, 27, 5);
        path(
          Path()
            ..moveTo(9, 9)
            ..lineTo(12, 5)
            ..lineTo(20, 5)
            ..lineTo(23, 9),
        );
        circle(16, 18, 5);

      case MingleGlyph.settings:
        circle(16, 16, 9);
        circle(16, 16, 3.5);
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          line(
            16 + math.cos(angle) * 9,
            16 + math.sin(angle) * 9,
            16 + math.cos(angle) * 13,
            16 + math.sin(angle) * 13,
          );
        }
      case MingleGlyph.chats:
        path(
          Path()
            ..moveTo(10, 7)
            ..quadraticBezierTo(4, 7, 4, 13)
            ..lineTo(4, 18)
            ..quadraticBezierTo(4, 22, 8, 22)
            ..lineTo(8, 27)
            ..lineTo(14, 22)
            ..lineTo(20, 22)
            ..quadraticBezierTo(25, 22, 25, 17)
            ..lineTo(25, 12)
            ..quadraticBezierTo(25, 7, 20, 7)
            ..close(),
          fill: true,
        );
        path(
          Path()
            ..moveTo(17, 3)
            ..lineTo(23, 3)
            ..quadraticBezierTo(29, 3, 29, 9)
            ..lineTo(29, 16 + selection * 2),
        );
        for (final x in [10.0, 15.0, 20.0]) {
          canvas.drawCircle(Offset(x, 15), 1.1, Paint()..color = color);
        }
      case MingleGlyph.people:
        circle(11 + selection, 10, 4.5);
        circle(23 - selection, 12, 3.5);
        path(
          Path()
            ..moveTo(3, 27)
            ..cubicTo(3, 16, 19, 16, 19, 27),
        );
        path(
          Path()
            ..moveTo(21, 20)
            ..quadraticBezierTo(29, 20, 29, 27),
        );
      case MingleGlyph.profile:
        path(
          Path()
            ..moveTo(16, 3)
            ..cubicTo(31, 3, 31, 29, 16, 29)
            ..cubicTo(1, 29, 1, 3, 16, 3)
            ..close(),
          fill: true,
        );
        circle(16, 12, 4);
        path(
          Path()
            ..moveTo(8, 25)
            ..cubicTo(8, 17, 24, 17, 24, 25),
        );
      case MingleGlyph.search:
        circle(13, 13, 8.5);
        line(19, 20, 27, 28);
        path(
          Path()
            ..moveTo(9, 9)
            ..quadraticBezierTo(12, 6, 15, 7),
        );
      case MingleGlyph.compose:
        path(
          Path()
            ..moveTo(13, 5)
            ..lineTo(8, 5)
            ..quadraticBezierTo(4, 5, 4, 9)
            ..lineTo(4, 24)
            ..quadraticBezierTo(4, 28, 8, 28)
            ..lineTo(23, 28)
            ..quadraticBezierTo(27, 28, 27, 24)
            ..lineTo(27, 19),
        );
        path(
          Path()
            ..moveTo(12, 18)
            ..lineTo(24, 4)
            ..quadraticBezierTo(26, 2, 29, 6)
            ..lineTo(16, 21)
            ..lineTo(10, 23)
            ..close(),
        );
        line(22, 7, 26, 11);
      case MingleGlyph.plane:
        path(
          Path()
            ..moveTo(3, 13)
            ..lineTo(29, 3)
            ..lineTo(21, 29)
            ..lineTo(15, 20)
            ..lineTo(8, 24)
            ..lineTo(9, 16)
            ..close(),
          fill: true,
        );
        line(9, 16, 29, 3);
        line(15, 20, 29, 3);
      case MingleGlyph.close:
        line(8, 8, 24, 24);
        line(24, 8, 8, 24);
      case MingleGlyph.check:
        path(
          Path()
            ..moveTo(5, 17)
            ..lineTo(12, 24)
            ..lineTo(27, 8),
        );
      case MingleGlyph.read:
        path(
          Path()
            ..moveTo(3, 17)
            ..lineTo(9, 23)
            ..lineTo(22, 8),
        );
        path(
          Path()
            ..moveTo(15, 21)
            ..lineTo(18, 24)
            ..lineTo(29, 11),
        );
      case MingleGlyph.edit:
        path(
          Path()
            ..moveTo(6, 21)
            ..lineTo(22, 5)
            ..quadraticBezierTo(24, 3, 28, 7)
            ..lineTo(11, 24)
            ..lineTo(4, 27)
            ..close(),
        );
        line(20, 7, 25, 12);
      case MingleGlyph.logout:
        path(
          Path()
            ..moveTo(14, 4)
            ..lineTo(7, 4)
            ..quadraticBezierTo(4, 4, 4, 7)
            ..lineTo(4, 25)
            ..quadraticBezierTo(4, 28, 7, 28)
            ..lineTo(14, 28),
        );
        line(12, 16, 29, 16);
        line(23, 10, 29, 16);
        line(23, 22, 29, 16);
      case MingleGlyph.mail:
        round(3, 7, 29, 26, 5);
        path(
          Path()
            ..moveTo(4, 9)
            ..lineTo(16, 18)
            ..lineTo(28, 9),
        );
      case MingleGlyph.lock:
        round(6, 13, 26, 29, 5);
        path(
          Path()
            ..moveTo(10, 13)
            ..lineTo(10, 9)
            ..cubicTo(10, 1, 22, 1, 22, 9)
            ..lineTo(22, 13),
        );
        circle(16, 20, 1.5);
        line(16, 22, 16, 25);
      case MingleGlyph.eye:
      case MingleGlyph.eyeOff:
        path(
          Path()
            ..moveTo(2, 16)
            ..cubicTo(9, 4, 23, 4, 30, 16)
            ..cubicTo(23, 28, 9, 28, 2, 16)
            ..close(),
        );
        circle(16, 16, 4);
        if (glyph == MingleGlyph.eyeOff) line(4, 4, 28, 28);
      case MingleGlyph.back:
        path(
          Path()
            ..moveTo(20, 5)
            ..quadraticBezierTo(15, 9, 9, 16)
            ..quadraticBezierTo(15, 23, 20, 27),
        );
      case MingleGlyph.next:
        path(
          Path()
            ..moveTo(12, 5)
            ..quadraticBezierTo(17, 9, 23, 16)
            ..quadraticBezierTo(17, 23, 12, 27),
        );
      case MingleGlyph.reply:
        path(
          Path()
            ..moveTo(12, 6)
            ..lineTo(4, 14)
            ..lineTo(12, 22),
        );
        path(
          Path()
            ..moveTo(4, 14)
            ..lineTo(18, 14)
            ..quadraticBezierTo(28, 14, 28, 27),
        );
      case MingleGlyph.copy:
        round(10, 9, 28, 29, 4);
        path(
          Path()
            ..moveTo(21, 5)
            ..lineTo(8, 5)
            ..quadraticBezierTo(4, 5, 4, 9)
            ..lineTo(4, 23),
        );
      case MingleGlyph.trash:
        line(4, 8, 28, 8);
        round(11, 3, 21, 8, 2);
        path(
          Path()
            ..moveTo(7, 8)
            ..lineTo(9, 26)
            ..quadraticBezierTo(9, 29, 12, 29)
            ..lineTo(20, 29)
            ..quadraticBezierTo(23, 29, 23, 26)
            ..lineTo(25, 8),
        );
        line(13, 14, 13, 23);
        line(19, 14, 19, 23);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.selection != selection ||
      old.rtl != rtl;
}

/// Shared empty-conversation illustration.
class MingleHello extends StatelessWidget {
  const MingleHello({super.key});
  @override
  Widget build(BuildContext context) => const MingleEmptyArt();
}
