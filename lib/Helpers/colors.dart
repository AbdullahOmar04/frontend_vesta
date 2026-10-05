import 'package:flutter/material.dart';

// Design tokens and themes for the redesign, taken from the brand palette in
// Vesta Prototype.html. Screens read colours from the theme
// (Theme.of(context).colorScheme and context.vesta), never hard-code them.

const String headingFont = 'PixelifySans';
const String bodyFont = 'Poppins';

class VestaRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double button = 12;
  static const double lg = 14;
  static const double card = 16;
  static const double sheet = 24;
}

class VestaSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double gutter = 18;
  static const double xl = 24;
}

/// Colours the Material ColorScheme has no slot for.
class VestaColors extends ThemeExtension<VestaColors> {
  const VestaColors({
    required this.bgTop,
    required this.raised,
    required this.track,
    required this.muted,
    required this.divider,
    required this.edge,
    required this.tint,
    required this.tintText,
    required this.accentInk,
    required this.accentWash,
    required this.pos,
    required this.neg,
    required this.seg1,
    required this.seg2,
    required this.seg3,
    required this.seg4,
    required this.seg5,
    required this.pxBlue,
    required this.pxYellow,
    required this.pxGreen,
    required this.pxPurple,
    required this.pxTeal,
    required this.pxInk,
    required this.bucketSavings,
    required this.bucketEssential,
    required this.bucketLuxury,
  });

  /// Top of the page gradient and the header bars.
  final Color bgTop;

  /// Icon badges and pressed rows, one step up from a card.
  final Color raised;

  /// Unfilled part of progress bars.
  final Color track;

  /// Secondary text.
  final Color muted;
  final Color divider;

  /// Hairline around cards; transparent in dark mode.
  final Color edge;

  /// Selected pill in the bottom bar, and soft badges.
  final Color tint;
  final Color tintText;

  /// Accent for links and accent text; readable on cards in both themes.
  final Color accentInk;

  /// Translucent accent fill behind primary buttons and pills.
  final Color accentWash;

  /// Money in and money out.
  final Color pos;
  final Color neg;

  /// Chart and category colours, in order.
  final Color seg1;
  final Color seg2;
  final Color seg3;
  final Color seg4;
  final Color seg5;

  /// Pixel-art icon colours.
  final Color pxBlue;
  final Color pxYellow;
  final Color pxGreen;
  final Color pxPurple;
  final Color pxTeal;
  final Color pxInk;

  /// Budget buckets: savings, necessities and luxuries.
  final Color bucketSavings;
  final Color bucketEssential;
  final Color bucketLuxury;

  List<Color> get segments => [seg1, seg2, seg3, seg4, seg5];

  static const light = VestaColors(
    bgTop: Color(0xFFDDE7FF),
    raised: Color(0xFFDDE5F7),
    track: Color(0xFFD3DCF0),
    muted: Color(0xA8313031),
    divider: Color(0x1C313031),
    edge: Color(0x12313031),
    tint: Color(0xFFE1D9FE),
    tintText: Color(0xFF3711A9),
    accentInk: Color(0xFF5A32E8),
    accentWash: Color(0x1A6B43F7),
    pos: Color(0xFF2F8F3C),
    neg: Color(0xFFD0433A),
    seg1: Color(0xFF6B43F7),
    seg2: Color(0xFF4A86FF),
    seg3: Color(0xFF00ABA0),
    seg4: Color(0xFFFFDA00),
    seg5: Color(0xFF5FC16B),
    pxBlue: Color(0xFF4A86FF),
    pxYellow: Color(0xFFFFDA00),
    pxGreen: Color(0xFF5FC16B),
    pxPurple: Color(0xFF6B43F7),
    pxTeal: Color(0xFF00ABA0),
    pxInk: Color(0xFF313031),
    bucketSavings: Color(0xFF00ABA0),
    bucketEssential: Color(0xFF4A86FF),
    bucketLuxury: Color(0xFF6B43F7),
  );

  static const dark = VestaColors(
    bgTop: Color(0xFF3A393B),
    raised: Color(0xFF4C4C4C),
    track: Color(0xFF4C4C4C),
    muted: Color(0xA3E9F0FF),
    divider: Color(0x1FE9F0FF),
    edge: Color(0x00000000),
    tint: Color(0xFF3C3452),
    tintText: Color(0xFFB9A8FF),
    accentInk: Color(0xFFB4A2FF),
    accentWash: Color(0x386B43F7),
    pos: Color(0xFF86CE8C),
    neg: Color(0xFFFF8A7A),
    seg1: Color(0xFF92C1FF),
    seg2: Color(0xFF00ABA0),
    seg3: Color(0xFFFFE250),
    seg4: Color(0xFF86CE8C),
    seg5: Color(0xFF6B43F7),
    pxBlue: Color(0xFF92C1FF),
    pxYellow: Color(0xFFFFE250),
    pxGreen: Color(0xFF86CE8C),
    pxPurple: Color(0xFFB4A2FF),
    pxTeal: Color(0xFF00ABA0),
    pxInk: Color(0xFF313031),
    bucketSavings: Color(0xFF86CE8C),
    bucketEssential: Color(0xFF92C1FF),
    bucketLuxury: Color(0xFFFFE250),
  );

  @override
  VestaColors copyWith({
    Color? bgTop,
    Color? raised,
    Color? track,
    Color? muted,
    Color? divider,
    Color? edge,
    Color? tint,
    Color? tintText,
    Color? accentInk,
    Color? accentWash,
    Color? pos,
    Color? neg,
    Color? seg1,
    Color? seg2,
    Color? seg3,
    Color? seg4,
    Color? seg5,
    Color? pxBlue,
    Color? pxYellow,
    Color? pxGreen,
    Color? pxPurple,
    Color? pxTeal,
    Color? pxInk,
    Color? bucketSavings,
    Color? bucketEssential,
    Color? bucketLuxury,
  }) {
    return VestaColors(
      bgTop: bgTop ?? this.bgTop,
      raised: raised ?? this.raised,
      track: track ?? this.track,
      muted: muted ?? this.muted,
      divider: divider ?? this.divider,
      edge: edge ?? this.edge,
      tint: tint ?? this.tint,
      tintText: tintText ?? this.tintText,
      accentInk: accentInk ?? this.accentInk,
      accentWash: accentWash ?? this.accentWash,
      pos: pos ?? this.pos,
      neg: neg ?? this.neg,
      seg1: seg1 ?? this.seg1,
      seg2: seg2 ?? this.seg2,
      seg3: seg3 ?? this.seg3,
      seg4: seg4 ?? this.seg4,
      seg5: seg5 ?? this.seg5,
      pxBlue: pxBlue ?? this.pxBlue,
      pxYellow: pxYellow ?? this.pxYellow,
      pxGreen: pxGreen ?? this.pxGreen,
      pxPurple: pxPurple ?? this.pxPurple,
      pxTeal: pxTeal ?? this.pxTeal,
      pxInk: pxInk ?? this.pxInk,
      bucketSavings: bucketSavings ?? this.bucketSavings,
      bucketEssential: bucketEssential ?? this.bucketEssential,
      bucketLuxury: bucketLuxury ?? this.bucketLuxury,
    );
  }

  @override
  VestaColors lerp(covariant VestaColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return VestaColors(
      bgTop: l(bgTop, other.bgTop),
      raised: l(raised, other.raised),
      track: l(track, other.track),
      muted: l(muted, other.muted),
      divider: l(divider, other.divider),
      edge: l(edge, other.edge),
      tint: l(tint, other.tint),
      tintText: l(tintText, other.tintText),
      accentInk: l(accentInk, other.accentInk),
      accentWash: l(accentWash, other.accentWash),
      pos: l(pos, other.pos),
      neg: l(neg, other.neg),
      seg1: l(seg1, other.seg1),
      seg2: l(seg2, other.seg2),
      seg3: l(seg3, other.seg3),
      seg4: l(seg4, other.seg4),
      seg5: l(seg5, other.seg5),
      pxBlue: l(pxBlue, other.pxBlue),
      pxYellow: l(pxYellow, other.pxYellow),
      pxGreen: l(pxGreen, other.pxGreen),
      pxPurple: l(pxPurple, other.pxPurple),
      pxTeal: l(pxTeal, other.pxTeal),
      pxInk: l(pxInk, other.pxInk),
      bucketSavings: l(bucketSavings, other.bucketSavings),
      bucketEssential: l(bucketEssential, other.bucketEssential),
      bucketLuxury: l(bucketLuxury, other.bucketLuxury),
    );
  }
}

extension VestaThemeContext on BuildContext {
  VestaColors get vesta => Theme.of(this).extension<VestaColors>()!;
}

/// Pixelify Sans is a variable font, so its weight is set on the wght axis.
TextStyle headingStyle(double size, {Color? color}) => TextStyle(
  fontFamily: headingFont,
  fontSize: size,
  fontWeight: FontWeight.w500,
  fontVariations: const [FontVariation('wght', 500)],
  // Pixelify's "fi" ligature reads as an "A" ("Shared Ainances").
  fontFeatures: const [FontFeature.disable('liga')],
  height: 1.2,
  color: color,
);

/// Poppins Medium with fixed-width digits, for money.
TextStyle amountStyle(double size, {Color? color}) => TextStyle(
  fontFamily: bodyFont,
  fontSize: size,
  fontWeight: FontWeight.w500,
  fontFeatures: const [FontFeature.tabularFigures()],
  color: color,
);

ThemeData _buildTheme({
  required Brightness brightness,
  required Color bg,
  required Color surface,
  required Color text,
  required VestaColors v,
}) {
  const accent = Color(0xFF6B43F7);
  final outline = text.withValues(alpha: 0.35);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: Colors.white,
    secondary: v.accentInk,
    onSecondary: brightness == Brightness.light ? Colors.white : bg,
    error: v.neg,
    onError: Colors.white,
    surface: bg,
    onSurface: text,
    onSurfaceVariant: v.muted,
    surfaceContainerLowest: surface,
    surfaceContainerLow: surface,
    surfaceContainer: surface,
    surfaceContainerHigh: surface,
    surfaceContainerHighest: v.raised,
    outline: outline,
    outlineVariant: v.divider,
    inverseSurface: text,
    onInverseSurface: bg,
    surfaceTint: Colors.transparent,
  );

  final textTheme = TextTheme(
    headlineMedium: headingStyle(28, color: text).copyWith(letterSpacing: -0.5),
    headlineSmall: headingStyle(22, color: text),
    titleLarge: headingStyle(17, color: text),
    // Material's own widgets (dropdowns, chips, tabs) default to the title
    // and label roles, so those stay in Poppins; Pixelify headings come from
    // headingStyle() where the prototype uses them.
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: text),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text),
    bodyLarge: TextStyle(fontSize: 15, color: text),
    bodyMedium: TextStyle(fontSize: 14, color: text),
    bodySmall: TextStyle(fontSize: 12, color: v.muted),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text),
    labelMedium: TextStyle(fontSize: 13, color: text),
    labelSmall: TextStyle(fontSize: 11, color: text),
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(VestaRadius.button),
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: bodyFont,
    textTheme: textTheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    dividerColor: v.divider,
    splashFactory: InkRipple.splashFactory,
    extensions: [v],
    iconTheme: IconThemeData(color: text, size: 20),
    appBarTheme: AppBarTheme(
      backgroundColor: v.bgTop,
      foregroundColor: text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: text, size: 20),
      actionsIconTheme: IconThemeData(color: v.accentInk, size: 22),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: v.tint,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          color: states.contains(WidgetState.selected) ? text : v.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 20,
          color: states.contains(WidgetState.selected) ? text : v.muted,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VestaRadius.card),
        side: BorderSide(color: v.edge),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: v.accentWash,
        foregroundColor: v.accentInk,
        disabledBackgroundColor: v.raised,
        disabledForegroundColor: v.muted,
        textStyle: headingStyle(14),
        padding: buttonPadding,
        shape: buttonShape,
        side: BorderSide(color: v.accentInk),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        textStyle: headingStyle(14),
        padding: buttonPadding,
        shape: buttonShape,
        side: BorderSide(color: outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: v.accentInk,
        textStyle: const TextStyle(fontFamily: bodyFont, fontSize: 13),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: headingStyle(14),
        padding: buttonPadding,
        shape: buttonShape,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VestaRadius.card),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: TextStyle(fontSize: 13, color: v.muted),
      hintStyle: TextStyle(fontSize: 14, color: v.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VestaRadius.md),
        borderSide: BorderSide(color: v.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VestaRadius.md),
        borderSide: BorderSide(color: v.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VestaRadius.md),
        borderSide: const BorderSide(color: accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VestaRadius.md),
        borderSide: BorderSide(color: v.neg),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VestaRadius.md),
        borderSide: BorderSide(color: v.neg),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VestaRadius.sheet),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: v.muted,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VestaRadius.sheet),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? accent : v.track,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accent,
      linearTrackColor: v.track,
      circularTrackColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: text,
      contentTextStyle: TextStyle(fontFamily: bodyFont, fontSize: 14, color: bg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VestaRadius.md),
      ),
    ),
    dividerTheme: DividerThemeData(color: v.divider, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(iconColor: v.accentInk, textColor: text),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

final ThemeData lightTheme = _buildTheme(
  brightness: Brightness.light,
  bg: const Color(0xFFE9F0FF),
  surface: const Color(0xFFF7F9FF),
  text: const Color(0xFF313031),
  v: VestaColors.light,
);

final ThemeData darkTheme = _buildTheme(
  brightness: Brightness.dark,
  bg: const Color(0xFF313031),
  surface: const Color(0xFF3B3A3B),
  text: const Color(0xFFE9F0FF),
  v: VestaColors.dark,
);
