import 'package:flutter/material.dart';

import 'mingle_logo_paths.dart';

class MingleBrandPalette extends ThemeExtension<MingleBrandPalette> {
  const MingleBrandPalette(
    this.logoColor, {
    this.primaryStartColor = const Color(0xFFCD3470),
    this.primaryEndColor = const Color(0xFFC72F6A),
    this.highlightStartColor = const Color(0xFFFDD3E1),
    this.highlightEndColor = const Color(0xFFFDD7E4),
    this.foldStartColor = const Color(0xFFFDACC9),
    this.foldEndColor = const Color(0xFFF7A5C2),
  });

  factory MingleBrandPalette.fromColor(Color color) => MingleBrandPalette(
    color,
    primaryStartColor: Color.lerp(color, Colors.white, .02)!,
    primaryEndColor: Color.lerp(color, Colors.black, .015)!,
    highlightStartColor: Color.lerp(color, Colors.white, .8)!,
    highlightEndColor: Color.lerp(color, Colors.white, .82)!,
    foldStartColor: Color.lerp(color, Colors.white, .65)!,
    foldEndColor: Color.lerp(color, Colors.white, .6)!,
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

/// Native vector geometry is generated from assets/brand/mingle-mark.svg.
/// The theme supplies independently editable gradient stops, not a flat tint.
class MingleLogo extends StatelessWidget {
  const MingleLogo({this.size = 96, this.color, super.key});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final palette = color == null
        ? Theme.of(context).extension<MingleBrandPalette>() ??
              const MingleBrandPalette(Color(0xFFCA306C))
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
    void layer(Path path, Color start, Color end) => canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ).createShader(path.getBounds()),
    );
    layer(
      MingleLogoPaths.bubble,
      palette.primaryStartColor,
      palette.primaryEndColor,
    );
    layer(
      MingleLogoPaths.plane,
      palette.primaryStartColor,
      palette.primaryEndColor,
    );
    layer(
      MingleLogoPaths.highlight,
      palette.highlightStartColor,
      palette.highlightEndColor,
    );
    canvas.save();
    canvas.clipPath(MingleLogoPaths.highlight);
    layer(MingleLogoPaths.fold, palette.foldStartColor, palette.foldEndColor);
    canvas.restore();
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
