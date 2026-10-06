import 'package:flutter/material.dart';

import 'mingle_logo_paths.dart';

class MingleBrandPalette extends ThemeExtension<MingleBrandPalette> {
  const MingleBrandPalette(
    this.logoColor, {
    this.primaryStartColor = const Color(0xFF285E67),
    this.primaryEndColor = const Color(0xFF173C47),
    this.highlightStartColor = const Color(0xFFFFFDF6),
    this.highlightEndColor = const Color(0xFFF2E7DA),
    this.foldStartColor = const Color(0xFFFFC2AA),
    this.foldEndColor = const Color(0xFFED897F),
  });

  factory MingleBrandPalette.fromColor(Color color) => MingleBrandPalette(
    color,
    primaryStartColor: color,
    primaryEndColor: Color.lerp(color, Colors.black, .3)!,
  );

  final Color logoColor;
  final Color primaryStartColor;
  final Color primaryEndColor;
  final Color highlightStartColor;
  final Color highlightEndColor;
  final Color foldStartColor;
  final Color foldEndColor;

  @override
  MingleBrandPalette copyWith({
    Color? logoColor,
    Color? primaryStartColor,
    Color? primaryEndColor,
    Color? highlightStartColor,
    Color? highlightEndColor,
    Color? foldStartColor,
    Color? foldEndColor,
  }) {
    final base = logoColor == null
        ? this
        : MingleBrandPalette.fromColor(logoColor);
    return MingleBrandPalette(
      base.logoColor,
      primaryStartColor: primaryStartColor ?? base.primaryStartColor,
      primaryEndColor: primaryEndColor ?? base.primaryEndColor,
      highlightStartColor: highlightStartColor ?? base.highlightStartColor,
      highlightEndColor: highlightEndColor ?? base.highlightEndColor,
      foldStartColor: foldStartColor ?? base.foldStartColor,
      foldEndColor: foldEndColor ?? base.foldEndColor,
    );
  }

  @override
  MingleBrandPalette lerp(covariant MingleBrandPalette? other, double t) =>
      other == null
      ? this
      : MingleBrandPalette(
          Color.lerp(logoColor, other.logoColor, t)!,
          primaryStartColor: Color.lerp(
            primaryStartColor,
            other.primaryStartColor,
            t,
          )!,
          primaryEndColor: Color.lerp(
            primaryEndColor,
            other.primaryEndColor,
            t,
          )!,
          highlightStartColor: Color.lerp(
            highlightStartColor,
            other.highlightStartColor,
            t,
          )!,
          highlightEndColor: Color.lerp(
            highlightEndColor,
            other.highlightEndColor,
            t,
          )!,
          foldStartColor: Color.lerp(foldStartColor, other.foldStartColor, t)!,
          foldEndColor: Color.lerp(foldEndColor, other.foldEndColor, t)!,
        );
}

/// Native vector geometry is generated from assets/brand/mingle-launcher.svg.
/// The theme supplies independently editable gradient stops, not a flat tint.
class MingleLogo extends StatelessWidget {
  const MingleLogo({this.size = 96, this.color, super.key});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final palette = color == null
        ? Theme.of(context).extension<MingleBrandPalette>() ??
              const MingleBrandPalette(Color(0xFF285E67))
        : MingleBrandPalette.fromColor(color!);
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MingleLogoPainter(palette),
      ),
    );
  }
}

class _MingleLogoPainter extends CustomPainter {
  const _MingleLogoPainter(this.palette);
  final MingleBrandPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / MingleLogoPaths.viewBoxSize,
      size.height / MingleLogoPaths.viewBoxSize,
    );
    void layer(
      Path path,
      Color start,
      Color end, {
      Alignment endAlignment = Alignment.bottomRight,
    }) => canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: endAlignment,
          colors: [start, end],
        ).createShader(path.getBounds()),
    );
    const bounds = Rect.fromLTWH(0, 0, 1024, 1024);
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(220)),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primaryStartColor, palette.primaryEndColor],
        ).createShader(bounds),
    );
    canvas.drawCircle(
      const Offset(880, 120),
      470,
      Paint()..color = const Color(0xFF7CB9B3).withValues(alpha: .07),
    );
    canvas.save();
    canvas.translate(0, 18);
    canvas.drawPath(
      MingleLogoPaths.bubbleShadow,
      Paint()..color = const Color(0xFF0C2E37).withValues(alpha: .22),
    );
    canvas.restore();
    layer(
      MingleLogoPaths.bubble,
      palette.highlightStartColor,
      palette.highlightEndColor,
      endAlignment: const Alignment(.6, 1),
    );
    canvas.drawPath(
      MingleLogoPaths.lines,
      Paint()
        ..color = const Color(0xFF8EAEAB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round,
    );
    canvas.save();
    canvas.translate(0, 12);
    canvas.drawPath(
      MingleLogoPaths.planeShadow,
      Paint()..color = const Color(0xFF173C47).withValues(alpha: .15),
    );
    canvas.restore();
    layer(MingleLogoPaths.plane, palette.foldStartColor, palette.foldEndColor);
    canvas.drawPath(
      MingleLogoPaths.highlight,
      Paint()..color = const Color(0xFFFFF2E8),
    );
    canvas.drawPath(
      MingleLogoPaths.fold,
      Paint()..color = const Color(0xFFC86C69),
    );
    canvas.drawPath(
      MingleLogoPaths.crease,
      Paint()..color = const Color(0xFFF6AB99),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MingleLogoPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class MingleBrand extends StatelessWidget {
  const MingleBrand({this.size = 96, this.color, super.key});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MingleLogo(size: size, color: color),
      const SizedBox(height: 12),
      Text('Mingle', style: Theme.of(context).textTheme.headlineLarge),
    ],
  );
}

class MingleSplash extends StatelessWidget {
  const MingleSplash({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MingleBrand(size: 112),
                    const SizedBox(height: 16),
                    Text(
                      'Real conversations.\nBrighter days.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    const CircularProgressIndicator(
                      semanticsLabel: 'Opening Mingle',
                      strokeWidth: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
