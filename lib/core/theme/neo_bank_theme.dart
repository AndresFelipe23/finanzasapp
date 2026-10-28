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

  static const AppTokens light = AppTokens(
    brightness: Brightness.light,
    bg: Color(0xFFF4F6FB),
    bgTop: Color(0xFFF7F9FD),
    bgBottom: Color(0xFFEDF1F9),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF1E2340),
    accent: Color(0xFF5B5FEE),
    success: Color(0xFF22C55E),
    danger: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    transfer: Color(0xFF8B5CF6),
    textPrimary: Color(0xFF1E2340),
    textSecondary: Color(0xFF5A677D),
    border: Color(0xFFE2E8F0),
    divider: Color(0xFFF1F5F9),
    glassFill: Color(0x8CFFFFFF),
    glassFillStrong: Color(0xB8FFFFFF),
    glassStrokeStart: Color(0xBFFFFFFF),
    glassStrokeEnd: Color(0x26FFFFFF),
    glassShadow: Color(0x14000000),
    blobAccent: Color(0x2E5B5FEE),
    blobTransfer: Color(0x248B5CF6),
    blobSuccess: Color(0x1A22C55E),
    heroStart: Color(0xFF1E2340),
    heroEnd: Color(0xFF2D3461),
    blurChrome: 22,
    blurCard: 12,
    radiusSm: 16,
    radiusMd: 20,
    radiusLg: 28,
  );

  static const AppTokens dark = AppTokens(
    brightness: Brightness.dark,
    bg: Color(0xFF0B0F1E),
    bgTop: Color(0xFF0B0F1E),
    bgBottom: Color(0xFF070A14),
    surface: Color(0xFF151A2E),
    primary: Color(0xFFF1F5F9),
    accent: Color(0xFF7C82FF),
    success: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    transfer: Color(0xFFA78BFA),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    border: Color(0xFF2A3352),
    divider: Color(0xFF1E2540),
    glassFill: Color(0x0FFFFFFF),
    glassFillStrong: Color(0x1AFFFFFF),
    glassStrokeStart: Color(0x38FFFFFF),
    glassStrokeEnd: Color(0x0AFFFFFF),
    glassShadow: Color(0x66000000),
    blobAccent: Color(0x4D7C82FF),
    blobTransfer: Color(0x38A78BFA),
    blobSuccess: Color(0x2434D399),
    heroStart: Color(0xFF252C55),
    heroEnd: Color(0xFF39407A),
    blurChrome: 22,
    blurCard: 12,
    radiusSm: 16,
    radiusMd: 20,
    radiusLg: 28,
  );

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
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: t.textPrimary, displayColor: t.textPrimary);

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
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: t.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.isDark ? t.glassFillStrong : t.bg,
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
        hintStyle: GoogleFonts.plusJakartaSans(color: t.textSecondary),
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
