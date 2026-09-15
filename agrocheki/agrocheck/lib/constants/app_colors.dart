import 'package:flutter/material.dart';

/// Paleta de colores oficial de AGROCHECK.
/// Fondo claro/beige para reducir fatiga visual bajo el sol del campo,
/// y tarjetas verde oscuro que evocan el follaje del cultivo.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFE8E0D5); // Beige claro
  static const Color cardDark = Color(0xFF1A3A2F); // Verde oscuro (tarjetas)
  static const Color cardDarkLight = Color(0xFF244B3C); // Variante hover/pressed
  static const Color accentGreen = Color(0xFF4CAF6D); // Verde brillante (acentos, activo)
  static const Color textOnDark = Color(0xFFF5F1E8); // Texto sobre tarjetas oscuras
  static const Color textPrimary = Color(0xFF2B2A26); // Texto principal sobre fondo claro
  static const Color textSecondary = Color(0xFF6B6558); // Texto secundario/gris cálido
  static const Color warning = Color(0xFFE0A526); // Alertas / offline
  static const Color danger = Color(0xFFC0392B); // Enfermedad detectada / riesgo alto
  static const Color cardBorder = Color(0xFF0F251D); // Borde sutil de tarjetas
}

/// Radios y espaciados estándar reutilizados en toda la app.
class AppMetrics {
  AppMetrics._();

  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
}

/// TextStyles pensados para ser grandes y legibles (público objetivo: campesinos,
/// muchos usando el celular al aire libre con luz solar directa).
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle titleOnDark = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleOnDark = TextStyle(
    color: Color(0xFFC9D8CE),
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bigPrice = TextStyle(
    color: AppColors.textOnDark,
    fontSize: 30,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
}
