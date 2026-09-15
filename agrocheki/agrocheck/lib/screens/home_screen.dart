import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../database/database_helper.dart';
import '../models/historial_model.dart';
import '../models/precio_model.dart';
import '../services/precio_service.dart';
import '../services/tflite_service.dart';
import '../widgets/dark_card.dart';
import 'resultado_analisis_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final PrecioService _precioService = PrecioService();

  bool _cargandoPrecio = true;
  PrecioResultado? _precio;
  List<PuntoTendencia> _tendencia = [];
  double _variacionPct = 0.0;
  bool _analizando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosMercado();
  }

  Future<void> _cargarDatosMercado() async {
    setState(() => _cargandoPrecio = true);
    final precio = await _precioService.obtenerPrecioActual();
    final tendencia = await _precioService.obtenerTendenciaSemanal();
    final variacion = _precioService.calcularVariacionPorcentual(tendencia);

    if (!mounted) return;
    setState(() {
      _precio = precio;
      _tendencia = tendencia;
      _variacionPct = variacion;
      _cargandoPrecio = false;
    });
  }

  // ---------------------------------------------------------------------
  // Captura y análisis de imagen (cámara o galería)
  // ---------------------------------------------------------------------

  Future<void> _tomarFoto() => _procesarImagen(ImageSource.camera);
  Future<void> _elegirDeGaleria() => _procesarImagen(ImageSource.gallery);

  Future<void> _procesarImagen(ImageSource origen) async {
    try {
      final XFile? archivo = await _picker.pickImage(
        source: origen,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (archivo == null) return; // el usuario canceló

      setState(() => _analizando = true);

      // Clasificación 100% offline con TensorFlow Lite.
      final resultado = await TFLiteService.instance.clasificarImagen(archivo.path);

      // Guardar en el historial local (SQLite).
      await _db.insertarHistorial(HistorialItem(
        fecha: DateTime.now().toIso8601String(),
        tipoCultivo: resultado.cultivo,
        enfermedadDetectada: resultado.enfermedad,
        confianza: resultado.confianza,
        fotoPath: archivo.path,
        tratamientoRecomendado: resultado.tratamientoRecomendado,
      ));

      if (!mounted) return;
      setState(() => _analizando = false);

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultadoAnalisisScreen(
          rutaImagen: archivo.path,
          resultado: resultado,
        ),
      ));
    } catch (e) {
      setState(() => _analizando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo procesar la imagen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _cargarDatosMercado,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppMetrics.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppMetrics.paddingM),
                _buildBanner(),
                const SizedBox(height: AppMetrics.paddingL),
                _buildColumnasPrincipales(),
                const SizedBox(height: AppMetrics.paddingL),
              ],
            ),
          ),
        ),
        if (_analizando) _buildOverlayAnalizando(),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppColors.cardDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.accentGreen, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'AGROCHECK',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppColors.cardDark.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.accentGreen.withOpacity(0.7), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'IA Activa',
                style: TextStyle(color: AppColors.textOnDark, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------------

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: AppColors.accentGreen.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: const Text(
        '🌿 PLATAFORMA RECOMENDADA POR AGRICULTORES DE EL ORO',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: AppColors.cardDark,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Dos columnas: Evaluar cultivos | Mercado
  // ---------------------------------------------------------------------

  Widget _buildColumnasPrincipales() {
    return LayoutBuilder(builder: (context, constraints) {
      // En pantallas muy angostas apilamos verticalmente en vez de en
      // columnas, para mantener la legibilidad en celulares pequeños.
      final esAngosto = constraints.maxWidth < 340;

      final columnaIzquierda = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion('Evaluar cultivos', Icons.spa_rounded),
          const SizedBox(height: 10),
          BigIconActionCard(
            icon: Icons.camera_alt_rounded,
            titulo: 'TOMAR FOTO',
            subtitulo: 'Análisis IA offline: cacao, plátano, limón',
            onTap: _tomarFoto,
          ),
          const SizedBox(height: 12),
          BigIconActionCard(
            icon: Icons.image_rounded,
            titulo: 'DE GALERÍA',
            subtitulo: 'Procesar imágenes guardadas en el dispositivo',
            onTap: _elegirDeGaleria,
          ),
        ],
      );

      final columnaDerecha = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion('Análisis de mercado', Icons.trending_up_rounded),
          const SizedBox(height: 10),
          _buildTarjetaPrecio(),
        ],
      );

      if (esAngosto) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            columnaIzquierda,
            const SizedBox(height: AppMetrics.paddingL),
            columnaDerecha,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: columnaIzquierda),
          const SizedBox(width: AppMetrics.paddingM),
          Expanded(child: columnaDerecha),
        ],
      );
    });
  }

  Widget _tituloSeccion(String texto, IconData icono) {
    return Row(
      children: [
        Icon(icono, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          texto.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Tarjeta de precio + gráfico de tendencia semanal
  // ---------------------------------------------------------------------

  Widget _buildTarjetaPrecio() {
    if (_cargandoPrecio) {
      return const DarkCard(
        child: SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
        ),
      );
    }

    final precio = _precio!;
    final esSubida = _variacionPct >= 0;
    final minutosDesdeActualizacion = DateTime.now().difference(precio.fecha).inMinutes;

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRECIO HOY (CACAO)', style: AppTextStyles.subtitleOnDark),
          const SizedBox(height: 4),
          Text(
            '${precio.precioUsdKg.toStringAsFixed(2).replaceAll('.', ',')} USD/kg',
            style: AppTextStyles.bigPrice,
          ),
          const SizedBox(height: 2),
          Text(
            precio.esOffline
                ? 'Precio offline - última actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(precio.fecha)}'
                : 'Actualizado hace $minutosDesdeActualizacion min',
            style: TextStyle(
              fontSize: 11.5,
              color: precio.esOffline ? AppColors.warning : const Color(0xFFC9D8CE),
              fontWeight: precio.esOffline ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 90, child: _buildGraficoTendencia()),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: (esSubida ? AppColors.accentGreen : AppColors.danger).withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  esSubida ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 14,
                  color: esSubida ? AppColors.accentGreen : Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  'TENDENCIA SEMANAL ${esSubida ? '▲' : '▼'} ${_variacionPct.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: esSubida ? AppColors.accentGreen : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            children: const [
              Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFC9D8CE)),
              SizedBox(width: 4),
              Text('MERCADO: Arenillas / Guayaquil',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFC9D8CE))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.verified_rounded, size: 14, color: Color(0xFFC9D8CE)),
              SizedBox(width: 4),
              Text('CALIDAD: Grado A Premium',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFC9D8CE))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoTendencia() {
    if (_tendencia.isEmpty) return const SizedBox.shrink();

    final maxY = _tendencia.map((p) => p.precio).reduce((a, b) => a > b ? a : b) + 0.1;
    final minY = (_tendencia.map((p) => p.precio).reduce((a, b) => a < b ? a : b) - 0.1)
        .clamp(0, double.infinity);

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: minY.toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _tendencia.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _tendencia[i].diaAbrev,
                    style: const TextStyle(fontSize: 9, color: Color(0xFFC9D8CE)),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(_tendencia.length, (i) {
          final esUltimo = i == _tendencia.length - 1;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _tendencia[i].precio,
                width: 14,
                borderRadius: BorderRadius.circular(4),
                color: esUltimo ? AppColors.accentGreen : Colors.white38,
              ),
            ],
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Overlay mientras se ejecuta la clasificación de IA
  // ---------------------------------------------------------------------

  Widget _buildOverlayAnalizando() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(color: AppColors.accentGreen, strokeWidth: 3.5),
              ),
              SizedBox(height: 18),
              Text('Analizando cultivo con IA...', style: AppTextStyles.titleOnDark),
              SizedBox(height: 4),
              Text('Procesamiento 100% offline', style: AppTextStyles.subtitleOnDark),
            ],
          ),
        ),
      ),
    );
  }
}
