import 'dart:io';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/tflite_service.dart';
import '../widgets/dark_card.dart';

/// Nivel de severidad visual del diagnóstico, usado para elegir color e
/// ícono de forma consistente en toda la pantalla.
enum _Severidad { sano, atencion, riesgo }

/// Pantalla mostrada inmediatamente después de tomar una foto o elegir una
/// imagen de la galería. Presenta el diagnóstico de IA (ya calculado 100%
/// offline) junto con el tratamiento recomendado, que también proviene de
/// una base de conocimiento local — es decir, se muestra siempre, haya o
/// no conexión a internet.
class ResultadoAnalisisScreen extends StatelessWidget {
  final String rutaImagen;
  final ClasificacionResultado resultado;

  const ResultadoAnalisisScreen({
    super.key,
    required this.rutaImagen,
    required this.resultado,
  });

  bool get _esSano => resultado.enfermedad.toLowerCase().contains('sano');

  _Severidad get _severidad {
    if (_esSano) return _Severidad.sano;
    // Enfermedades de manejo más urgente (pueden perder la cosecha rápido)
    const riesgoAlto = ['Mal de machete', 'Mal de Panamá', 'Cancro cítrico'];
    final esRiesgoAlto = riesgoAlto.any((e) => resultado.enfermedad.contains(e));
    return esRiesgoAlto ? _Severidad.riesgo : _Severidad.atencion;
  }

  Color get _colorSeveridad {
    switch (_severidad) {
      case _Severidad.sano:
        return AppColors.accentGreen;
      case _Severidad.atencion:
        return AppColors.warning;
      case _Severidad.riesgo:
        return AppColors.danger;
    }
  }

  IconData get _iconoSeveridad {
    switch (_severidad) {
      case _Severidad.sano:
        return Icons.check_circle_rounded;
      case _Severidad.atencion:
        return Icons.warning_rounded;
      case _Severidad.riesgo:
        return Icons.dangerous_rounded;
    }
  }

  String get _etiquetaSeveridad {
    switch (_severidad) {
      case _Severidad.sano:
        return 'CULTIVO SANO';
      case _Severidad.atencion:
        return 'REQUIERE ATENCIÓN';
      case _Severidad.riesgo:
        return 'RIESGO ALTO — ACTUAR PRONTO';
    }
  }

  IconData get _iconoCultivo {
    final c = resultado.cultivo.toLowerCase();
    if (c.contains('cacao')) return Icons.spa_rounded;
    if (c.contains('plátano') || c.contains('platano')) return Icons.grass_rounded;
    if (c.contains('limón') || c.contains('limon')) return Icons.eco_rounded;
    return Icons.eco_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final confianzaPct = (resultado.confianza * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resultado del análisis', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppMetrics.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFoto(),
            const SizedBox(height: AppMetrics.paddingM),
            _buildTarjetaDiagnostico(confianzaPct),
            const SizedBox(height: AppMetrics.paddingL),
            _buildEncabezadoTratamiento(),
            const SizedBox(height: 10),
            _buildTratamiento(),
            const SizedBox(height: AppMetrics.paddingL),
            _buildPieInfo(),
            const SizedBox(height: AppMetrics.paddingL),
            _buildBotonVolver(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Foto analizada, con etiqueta flotante de severidad sobre la esquina
  // ---------------------------------------------------------------------

  Widget _buildFoto() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.file(File(rutaImagen), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _colorSeveridad,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconoSeveridad, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  _etiquetaSeveridad,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Tarjeta principal de diagnóstico
  // ---------------------------------------------------------------------

  Widget _buildTarjetaDiagnostico(String confianzaPct) {
    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
                child: Icon(_iconoCultivo, color: AppColors.textOnDark, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resultado.cultivo, style: AppTextStyles.subtitleOnDark.copyWith(fontSize: 12.5)),
                    Text(
                      resultado.enfermedad,
                      style: AppTextStyles.titleOnDark.copyWith(fontSize: 19),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Confianza del análisis', style: AppTextStyles.subtitleOnDark),
              Text(
                '$confianzaPct%',
                style: TextStyle(color: _colorSeveridad, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: resultado.confianza.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(_colorSeveridad),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tratamiento recomendado (siempre disponible offline)
  // ---------------------------------------------------------------------

  Widget _buildEncabezadoTratamiento() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Tratamiento recomendado', style: AppTextStyles.sectionTitle),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.offline_bolt_rounded, size: 13, color: AppColors.cardDark),
              SizedBox(width: 4),
              Text(
                'Disponible sin internet',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.cardDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTratamiento() {
    return LightCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: _colorSeveridad,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              resultado.tratamientoRecomendado,
              style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieInfo() {
    return Row(
      children: [
        const Icon(Icons.verified_user_rounded, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Diagnóstico y tratamiento generados 100% en tu dispositivo, sin '
            'conexión a internet. Guardado automáticamente en tu historial.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonVolver(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back_rounded),
      label: const Text('VOLVER AL INICIO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cardDark,
        foregroundColor: AppColors.textOnDark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.buttonRadius),
        ),
      ),
    );
  }
}
