import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tarjeta base verde oscuro con bordes redondeados, usada en toda la app
/// (pantalla de inicio, precios, historial) para mantener consistencia
/// visual. Envuelve el contenido en un InkWell para dar feedback táctil
/// cuando la tarjeta es interactiva (onTap != null). Incluye una sombra
/// suave y un leve gradiente para dar sensación de profundidad y un
/// acabado más profesional que un color plano.
class DarkCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const DarkCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppMetrics.paddingM),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.cardDark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: baseColor,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          splashColor: AppColors.accentGreen.withOpacity(0.2),
          highlightColor: AppColors.accentGreen.withOpacity(0.08),
          child: Ink(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(baseColor, Colors.white, 0.04)!,
                  baseColor,
                ],
              ),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta clara (blanca) con sombra suave, usada para contenido secundario
/// sobre el fondo beige (ej. la calculadora de precios, filas de
/// configuración). Mantiene el mismo lenguaje visual que [DarkCard] pero en
/// tono claro, para que toda la app se sienta como un único sistema de
/// diseño coherente.
class LightCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const LightCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppMetrics.paddingM),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardDark.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
              border: Border.all(color: AppColors.cardDark.withOpacity(0.08)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Botón de acción grande con icono, usado para "TOMAR FOTO" y "DE GALERÍA".
/// El ícono va dentro de un círculo con acento verde para que resalte
/// sobre el fondo oscuro, dando una jerarquía visual más clara.
class BigIconActionCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final double iconSize;

  const BigIconActionCard({
    super.key,
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.iconSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withOpacity(0.18),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.5), width: 1.5),
            ),
            child: Icon(icon, size: iconSize, color: AppColors.accentGreen),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleOnDark.copyWith(fontSize: 16, letterSpacing: 0.6),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitleOnDark,
          ),
        ],
      ),
    );
  }
}
