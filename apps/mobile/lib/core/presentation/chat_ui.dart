import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../failures/app_failure.dart';
import 'mingle_brand.dart';
import 'mingle_icons.dart';
import 'mingle_motion.dart';

export 'mingle_icons.dart';
export 'mingle_motion.dart';

const blush = Color(0xFFCA326E);
const mingleInk = Color(0xFF22254E);
const mingleCream = Color(0xFFFFF8F5);
const minglePink = Color(0xFFFFDCE7);
const mingleMuted = Color(0xFF666A86);

SystemUiOverlayStyle mingleSystemOverlay(Brightness brightness) =>
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );

ThemeData backendTheme(Brightness brightness, {Color? logoColor}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: blush, brightness: brightness)
      .copyWith(
        primary: dark ? const Color(0xFFFFA6C7) : blush,
        onPrimary: dark ? const Color(0xFF46152C) : Colors.white,
        primaryContainer: dark ? const Color(0xFF543343) : minglePink,
        onPrimaryContainer: dark ? const Color(0xFFFFECF3) : mingleInk,
        surface: dark ? const Color(0xFF282631) : mingleCream,
        onSurface: dark ? const Color(0xFFF8EEF3) : mingleInk,
        onSurfaceVariant: dark ? const Color(0xFFC2BBCD) : mingleMuted,
        outline: dark ? const Color(0xFF83778B) : const Color(0xFFEADDE2),
        outlineVariant: dark
            ? const Color(0xFF443C4C)
            : const Color(0xFFF1E5E8),
      );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Nunito',
    fontFamilyFallback: const ['Tajawal'],
  );
  final text = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  TextStyle heading(TextStyle? style) => style!.copyWith(
    fontFamily: 'Quicksand',
    fontFamilyFallback: const ['Tajawal', 'Nunito'],
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -.5,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: scheme.outline),
  );
  return base.copyWith(
    extensions: [MingleBrandPalette(logoColor ?? scheme.primary)],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: MinglePageTransitions(),
        TargetPlatform.iOS: MinglePageTransitions(),
        TargetPlatform.macOS: MinglePageTransitions(),
        TargetPlatform.windows: MinglePageTransitions(),
        TargetPlatform.linux: MinglePageTransitions(),
        TargetPlatform.fuchsia: MinglePageTransitions(),
      },
    ),
    scaffoldBackgroundColor: dark ? const Color(0xFF1D1B24) : mingleCream,
    textTheme: text.copyWith(
      headlineLarge: heading(text.headlineLarge),
      headlineMedium: heading(text.headlineMedium),
      headlineSmall: heading(text.headlineSmall),
      titleLarge: heading(text.titleLarge),
      titleMedium: text.titleMedium!.copyWith(fontWeight: FontWeight.w800),
      bodyLarge: text.bodyLarge!.copyWith(height: 1.45),
      bodyMedium: text.bodyMedium!.copyWith(height: 1.4),
      labelSmall: text.labelSmall!.copyWith(
        color: scheme.onSurfaceVariant,
        fontSize: 12,
      ),
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: mingleSystemOverlay(brightness),
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: heading(text.titleLarge).copyWith(fontSize: 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? scheme.surface : const Color(0xFFFFFBFA),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontFamilyFallback: ['Tajawal'],
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: dark ? scheme.surface : const Color(0xFFF4EBEF),
      selectedColor: scheme.primaryContainer,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w700,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurface,
      titleTextStyle: text.titleMedium!.copyWith(fontWeight: FontWeight.w800),
      subtitleTextStyle: text.bodyMedium!.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
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

/// Real raster decoration stays behind live controls and outside semantics.
class MingleBackdrop extends StatelessWidget {
  const MingleBackdrop({required this.child, this.intensity = .65, super.key});
  final Widget child;
  final double intensity;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      IgnorePointer(
        child: ExcludeSemantics(
          child: Image.asset(
            'assets/art/pastel_frame.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            opacity: AlwaysStoppedAnimation(
              Theme.of(context).brightness == Brightness.dark ? .09 : intensity,
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class InitialAvatar extends StatelessWidget {
  const InitialAvatar(this.name, {super.key, this.radius = 24});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: Image.asset(
                'assets/art/landscape_avatar.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          PositionedDirectional(
            end: -2,
            bottom: -2,
            child: Container(
              constraints: BoxConstraints(
                minWidth: radius * .68,
                minHeight: radius * .68,
              ),
              padding: const EdgeInsets.all(2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: radius * .44,
                  fontWeight: FontWeight.w800,
                ),
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class StatusPanel extends StatelessWidget {
  const StatusPanel(
    this.message, {
    super.key,
    this.action,
    this.label = 'Retry',
    this.brandMoment = false,
  });
  final String message;
  final VoidCallback? action;
  final String label;
  final bool brandMoment;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (brandMoment)
            const MingleHello()
          else
            const MingleIcon(MingleGlyph.chats, size: 42),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (action != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: MinglePress(
                child: FilledButton(onPressed: action, child: Text(label)),
              ),
            ),
        ],
      ),
    ),
  );
}

class WarmHeader extends StatelessWidget {
  const WarmHeader(this.title, this.subtitle, {this.trailing, super.key});
  final String title;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    ),
  );
}

class MingleNavigation extends StatelessWidget {
  const MingleNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget tab(int index, String label, MingleGlyph icon) => Expanded(
      child: Semantics(
        selected: selectedIndex == index,
        button: true,
        child: MinglePress(
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MingleIcon(
                    icon,
                    selected: selectedIndex == index,
                    color: selectedIndex == index
                        ? scheme.primary
                        : scheme.onSurface,
                    size: 27,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedIndex == index
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: selectedIndex == index
                          ? scheme.primary
                          : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              tab(0, 'Chats', MingleGlyph.chats),
              tab(1, 'People', MingleGlyph.people),
              tab(2, 'Profile', MingleGlyph.profile),
            ],
          ),
        ),
      ),
    );
  }
}

class MingleBackButton extends StatelessWidget {
  const MingleBackButton({super.key});
  @override
  Widget build(BuildContext context) => MinglePress(
    child: IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const MingleIcon(MingleGlyph.back),
    ),
  );
}
