import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../database/database_helper.dart';
import '../models/historial_model.dart';
import '../widgets/dark_card.dart';

/// Pantalla que lista todos los análisis de IA guardados localmente en
/// SQLite, ordenados del más reciente al más antiguo. Funciona sin
/// necesidad de conexión a internet, ya que los datos viven en el
/// dispositivo.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<HistorialItem> _items = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _cargando = true);
    final items = await _db.obtenerHistorial();
    if (!mounted) return;
    setState(() {
      _items = items;
      _cargando = false;
    });
  }

  Future<void> _eliminar(HistorialItem item) async {
    if (item.id == null) return;
    await _db.eliminarHistorial(item.id!);
    _cargarHistorial();
  }

  bool _esSano(String enfermedad) => enfermedad.toLowerCase().contains('sano');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Historial de análisis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarHistorial,
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.cardDark))
            : _items.isEmpty
                ? _buildVacio()
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppMetrics.paddingM),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildItem(_items[index]),
                  ),
      ),
    );
  }

  Widget _buildVacio() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'Todavía no tienes análisis guardados',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ve a Inicio y toma una foto de tu cultivo para empezar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(HistorialItem item) {
    final sano = _esSano(item.enfermedadDetectada);
    final fecha = DateTime.tryParse(item.fecha);
    final fechaTexto = fecha != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
        : item.fecha;

    return Dismissible(
      key: ValueKey(item.id ?? item.fecha),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _eliminar(item),
      child: DarkCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: File(item.fotoPath).existsSync()
                  ? Image.file(File(item.fotoPath), width: 60, height: 60, fit: BoxFit.cover)
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.white24,
                      child: const Icon(Icons.eco_rounded, color: Colors.white70),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.tipoCultivo,
                          style: AppTextStyles.titleOnDark.copyWith(fontSize: 15),
                        ),
                      ),
                      Icon(
                        sano ? Icons.check_circle_rounded : Icons.warning_rounded,
                        size: 16,
                        color: sano ? AppColors.accentGreen : AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.enfermedadDetectada,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Confianza: ${(item.confianza * 100).toStringAsFixed(0)}%   •   $fechaTexto',
                    style: AppTextStyles.subtitleOnDark.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
