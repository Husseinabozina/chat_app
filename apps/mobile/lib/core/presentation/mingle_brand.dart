import 'package:flutter/material.dart';

class MingleBrandPalette extends ThemeExtension<MingleBrandPalette> {
  const MingleBrandPalette(this.logoColor);
  final Color logoColor;
  @override
  MingleBrandPalette copyWith({Color? logoColor}) =>
      MingleBrandPalette(logoColor ?? this.logoColor);
  @override
  MingleBrandPalette lerp(covariant MingleBrandPalette? other, double t) =>
      other == null
      ? this
      : MingleBrandPalette(Color.lerp(logoColor, other.logoColor, t)!);
}

/// The transparent mark is exported from assets/brand/mingle-mark.svg.
/// Tint is supplied by the theme or overridden for a campaign/brand variant.
class MingleLogo extends StatelessWidget {
  const MingleLogo({this.size = 96, this.color, super.key});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/art/mingle-mark.png',
      width: size,
      height: size,
      color:
          color ??
          Theme.of(context).extension<MingleBrandPalette>()?.logoColor ??
          Theme.of(context).colorScheme.primary,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
    ),
  );
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
