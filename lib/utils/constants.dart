import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const Color primary = Color(0xFF5B5BF0); // Índigo
  static const Color primaryDark = Color(0xFF3F3DC8);
  static const Color secondary = Color(0xFF8B5CF6); // Violeta
  static const Color success = Color(0xFF10B981); // Verde
  static const Color warning = Color(0xFFF59E0B); // Amarelo
  static const Color danger = Color(0xFFEF4444); // Vermelho
  static const Color info = Color(0xFF0EA5E9); // Azul
  static const Color orange = Color(0xFFF97316);

  // Light Mode
  static const Color lightBg = Color(0xFFF4F5FA);
  static const Color lightCardBg = Colors.white;
  static const Color lightText = Color(0xFF111827);
  static const Color lightSubText = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE6E8F0);

  // Dark Mode
  static const Color darkBg = Color(0xFF0B0F1C);
  static const Color darkCardBg = Color(0xFF161B2E);
  static const Color darkText = Color(0xFFF3F4F6);
  static const Color darkSubText = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF242B42);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF5B5BF0), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCardBg : lightCardBg;

  static Color subText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSubText : lightSubText;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// Formatação padrão de valores e datas.
class Fmt {
  static final NumberFormat _money =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final DateFormat _dayMonth = DateFormat('dd/MM');

  static String money(double v) => _money.format(v);
  static String dayMonth(DateTime d) => _dayMonth.format(d);

  /// Aceita "1.234,56", "1234,56" ou "1234.56".
  static double? parseMoney(String text) {
    var t = text.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (t.isEmpty) return null;
    if (t.contains(',')) t = t.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(t);
  }
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.danger,
      surface: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
    );
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final radius = BorderRadius.circular(14);
    // Estilos derivados da tipografia da plataforma (mantém a fonte padrão)
    final typo = Typography.material2021(platform: defaultTargetPlatform);
    final base = isDark ? typo.white : typo.black;
    final buttonText = base.labelLarge!.copyWith(fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: bg,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.titleLarge!
            .copyWith(color: text, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2438) : const Color(0xFFF6F7FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: radius, borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: radius, borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => base.labelMedium!.copyWith(
              fontSize: 12,
              fontWeight:
                  s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? AppColors.primary : null,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : (isDark ? AppColors.darkSubText : AppColors.lightSubText),
            )),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: base.bodyLarge!.copyWith(
            color: text, fontSize: 15, fontWeight: FontWeight.w600),
        subtitleTextStyle: base.bodySmall!.copyWith(
            color: isDark ? AppColors.darkSubText : AppColors.lightSubText),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
