import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  static const _key = 'themeMode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: _key);
      if (saved == null) return;
      state = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      // Sin preferencia guardada se mantiene ThemeMode.system
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {
      // El cambio ya se aplicó en memoria aunque no persista
    }
  }
}

/// Tokens del design system. Se resuelven por brillo — usar `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.brightness,
    required this.bg,
    required this.bgTop,
    required this.bgBottom,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.success,
    required this.danger,
    required this.warning,
    required this.transfer,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassStrokeStart,
    required this.glassStrokeEnd,
    required this.glassShadow,
    required this.blobAccent,
    required this.blobTransfer,
    required this.blobSuccess,
    required this.heroStart,
    required this.heroEnd,
    required this.blurChrome,
    required this.blurCard,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
  });

  final Brightness brightness;
  final Color bg;
  final Color bgTop;
  final Color bgBottom;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color success;
  final Color danger;
  final Color warning;
  final Color transfer;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color divider;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassStrokeStart;
  final Color glassStrokeEnd;
  final Color glassShadow;
  final Color blobAccent;
  final Color blobTransfer;
  final Color blobSuccess;
  final Color heroStart;
  final Color heroEnd;
  final double blurChrome;
  final double blurCard;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;

  bool get isDark => brightness == Brightness.dark;

  // Paleta del diseño "Financially · App móvil" (los mismos valores que
  // Brand): superficies sólidas, sin vidrio. Los tokens glass*, blob* y blur*
  // se conservan por compatibilidad, pero ya resuelven a opacos o a cero.
  static const AppTokens light = AppTokens(
    brightness: Brightness.light,
    bg: Color(0xFFF4F5F1),
    bgTop: Color(0xFFF4F5F1),
    bgBottom: Color(0xFFF4F5F1),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF10201B),
    accent: Color(0xFF0B6E4F),
    success: Color(0xFF0B6E4F),
    danger: Color(0xFFB4531A),
    warning: Color(0xFFA86A0C),
    transfer: Color(0xFF1F5FAD),
    textPrimary: Color(0xFF10201B),
    textSecondary: Color(0xFF5A6762),
    border: Color(0xFFE3E6E0),
    divider: Color(0xFFE9ECE6),
    glassFill: Color(0xFFFFFFFF),
    glassFillStrong: Color(0xFFFFFFFF),
    glassStrokeStart: Color(0xFFE3E6E0),
    glassStrokeEnd: Color(0xFFE3E6E0),
    glassShadow: Color(0x00000000),
    blobAccent: Color(0x00000000),
    blobTransfer: Color(0x00000000),
    blobSuccess: Color(0x00000000),
    heroStart: Color(0xFF10201B),
    heroEnd: Color(0xFF10201B),
    blurChrome: 0,
    blurCard: 0,
    radiusSm: 14,
    radiusMd: 18,
    radiusLg: 24,
  );

  // La app es solo de modo claro; el alias se deja por compatibilidad
  static const AppTokens dark = light;

  @override
  AppTokens copyWith({
    Brightness? brightness,
    Color? bg,
    Color? bgTop,
    Color? bgBottom,
    Color? surface,
    Color? primary,
    Color? accent,
    Color? success,
    Color? danger,
    Color? warning,
    Color? transfer,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? divider,
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassStrokeStart,
    Color? glassStrokeEnd,
    Color? glassShadow,
    Color? blobAccent,
    Color? blobTransfer,
    Color? blobSuccess,
    Color? heroStart,
    Color? heroEnd,
    double? blurChrome,
    double? blurCard,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
  }) {
    return AppTokens(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      bgTop: bgTop ?? this.bgTop,
      bgBottom: bgBottom ?? this.bgBottom,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      transfer: transfer ?? this.transfer,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassStrokeStart: glassStrokeStart ?? this.glassStrokeStart,
      glassStrokeEnd: glassStrokeEnd ?? this.glassStrokeEnd,
      glassShadow: glassShadow ?? this.glassShadow,
      blobAccent: blobAccent ?? this.blobAccent,
      blobTransfer: blobTransfer ?? this.blobTransfer,
      blobSuccess: blobSuccess ?? this.blobSuccess,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      blurChrome: blurChrome ?? this.blurChrome,
      blurCard: blurCard ?? this.blurCard,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: Color.lerp(bg, other.bg, t)!,
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassStrokeStart: Color.lerp(
        glassStrokeStart,
        other.glassStrokeStart,
        t,
      )!,
      glassStrokeEnd: Color.lerp(glassStrokeEnd, other.glassStrokeEnd, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      blobAccent: Color.lerp(blobAccent, other.blobAccent, t)!,
      blobTransfer: Color.lerp(blobTransfer, other.blobTransfer, t)!,
      blobSuccess: Color.lerp(blobSuccess, other.blobSuccess, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      blurChrome: lerpDouble(blurChrome, other.blurChrome, t)!,
      blurCard: lerpDouble(blurCard, other.blurCard, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}

/// Sistema de diseño para Financially
class NeoBankTheme {
  static ThemeData lightTheme() => _build(AppTokens.light);

  static ThemeData darkTheme() => _build(AppTokens.dark);

  static ThemeData _build(AppTokens t) {
    final base = t.isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.manropeTextTheme(
      base.textTheme,
    ).apply(bodyColor: t.textPrimary, displayColor: t.textPrimary);
    TextStyle font({double? size, FontWeight? weight, Color? color}) =>
        GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[t],
      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: t.accent,
        onPrimary: Colors.white,
        secondary: t.transfer,
        onSecondary: Colors.white,
        surface: t.surface,
        onSurface: t.textPrimary,
        surfaceContainerHighest: t.divider,
        outline: t.border,
        error: t.danger,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: t.bg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: t.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: t.textPrimary),
        titleTextStyle: font(size: 20, weight: FontWeight.w800, color: t.textPrimary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.accent,
          textStyle: font(size: 14, weight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: font(size: 14, weight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          side: BorderSide(color: t.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: font(size: 14, weight: FontWeight.w700),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : null,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.textPrimary,
        contentTextStyle: font(size: 14, color: Colors.white),
        actionTextColor: const Color(0xFF7FD1AE),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: font(size: 14, weight: FontWeight.w600, color: t.textPrimary),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: t.textPrimary,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusLg)),
        dayStyle: font(size: 14, weight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surface,
        selectedColor: t.textPrimary,
        side: BorderSide(color: t.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: font(size: 13, weight: FontWeight.w700, color: t.textPrimary),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.textPrimary,
        titleTextStyle: font(size: 15, weight: FontWeight.w600, color: t.textPrimary),
        subtitleTextStyle: font(size: 12, color: t.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusSm),
          side: BorderSide(color: t.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: t.divider, space: 1, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: font(size: 15, weight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.accent, width: 1.5),
        ),
        hintStyle: font(color: t.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusLg),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.surface,
        selectedItemColor: t.accent,
        unselectedItemColor: t.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent),
    );
  }
}
