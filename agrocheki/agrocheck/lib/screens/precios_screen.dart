import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../services/precio_service.dart';
import '../widgets/dark_card.dart';

enum UnidadVenta { quintales, libras }

/// Pantalla de "Precios": muestra el precio actual del cacao (con API real
/// cuando hay internet, o el último precio guardado si no la hay) y ofrece
/// una calculadora de venta para estimar cuánto recibiría el agricultor.
///
/// Conversión usada: 1 quintal = 100 libras = 45.36 kg (quintal métrico
/// estándar usado en el agro ecuatoriano).
class PreciosScreen extends StatefulWidget {
  const PreciosScreen({super.key});

  @override
  State<PreciosScreen> createState() => _PreciosScreenState();
}

class _PreciosScreenState extends State<PreciosScreen> {
  final PrecioService _precioService = PrecioService();

  bool _cargando = true;
  PrecioResultado? _precio;

  final TextEditingController _cantidadController = TextEditingController();
  UnidadVenta _unidad = UnidadVenta.quintales;
  double? _totalCalculado;
  double? _kgCalculados;

  static const double _kgPorQuintal = 45.36;
  static const double _kgPorLibra = 0.4536;

  @override
  void initState() {
    super.initState();
    _cargarPrecio();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarPrecio() async {
    setState(() => _cargando = true);
    final precio = await _precioService.obtenerPrecioActual();
    if (!mounted) return;
    setState(() {
      _precio = precio;
      _cargando = false;
    });
  }

  void _calcular() {
    final texto = _cantidadController.text.trim().replaceAll(',', '.');
    final cantidad = double.tryParse(texto);

    if (cantidad == null || cantidad <= 0 || _precio == null) {
      setState(() {
        _totalCalculado = null;
        _kgCalculados = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida mayor a 0')),
      );
      return;
    }

    final kg = _unidad == UnidadVenta.quintales
        ? cantidad * _kgPorQuintal
        : cantidad * _kgPorLibra;

    final total = kg * _precio!.precioUsdKg;

    setState(() {
      _kgCalculados = kg;
      _totalCalculado = total;
    });

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Precios y Mercado', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarPrecio,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppMetrics.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTarjetaPrecioActual(),
              const SizedBox(height: AppMetrics.paddingL),
              const Text('Calculadora de venta', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 4),
              const Text(
                'Calcula cuánto recibirías por tu cosecha al precio de hoy.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildCalculadora(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaPrecioActual() {
    if (_cargando) {
      return const DarkCard(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
        ),
      );
    }

    final precio = _precio!;

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PRECIO ACTUAL - CACAO', style: AppTextStyles.subtitleOnDark),
              Icon(
                precio.esOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                size: 18,
                color: precio.esOffline ? AppColors.warning : AppColors.accentGreen,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${precio.precioUsdKg.toStringAsFixed(2).replaceAll('.', ',')} USD/kg',
            style: AppTextStyles.bigPrice,
          ),
          const SizedBox(height: 6),
          Text(
            precio.esOffline
                ? 'Precio offline - última actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(precio.fecha)}'
                : 'Actualizado: ${DateFormat('dd/MM/yyyy HH:mm').format(precio.fecha)}',
            style: TextStyle(
              fontSize: 12,
              color: precio.esOffline ? AppColors.warning : const Color(0xFFC9D8CE),
              fontWeight: precio.esOffline ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Divider(color: Colors.white24, height: 22),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFC9D8CE)),
              const SizedBox(width: 4),
              Text('Mercado: ${precio.mercado}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFC9D8CE))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.source_rounded, size: 14, color: Color(0xFFC9D8CE)),
              const SizedBox(width: 4),
              Text('Fuente: ${precio.fuente}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFC9D8CE))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculadora() {
    return LightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cantidad a vender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _cantidadController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Ej: 5',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppMetrics.buttonRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Unidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSelectorUnidad(
                  label: 'QUINTALES',
                  seleccionado: _unidad == UnidadVenta.quintales,
                  onTap: () => setState(() => _unidad = UnidadVenta.quintales),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSelectorUnidad(
                  label: 'LIBRAS',
                  seleccionado: _unidad == UnidadVenta.libras,
                  onTap: () => setState(() => _unidad = UnidadVenta.libras),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cargando ? null : _calcular,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardDark,
                foregroundColor: AppColors.textOnDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppMetrics.buttonRadius),
                ),
              ),
              child: const Text(
                'CALCULAR',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
          if (_totalCalculado != null) ...[
            const SizedBox(height: 20),
            _buildResultado(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectorUnidad({
    required String label,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppMetrics.buttonRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.cardDark : AppColors.background,
          borderRadius: BorderRadius.circular(AppMetrics.buttonRadius),
          border: Border.all(
            color: seleccionado ? AppColors.cardDark : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: seleccionado ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildResultado() {
    final formatoUsd = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return DarkCard(
      color: AppColors.accentGreen.withOpacity(0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total a recibir',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            formatoUsd.format(_totalCalculado),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Equivalente a ${_kgCalculados!.toStringAsFixed(1)} kg × '
            '${_precio!.precioUsdKg.toStringAsFixed(2)} USD/kg',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
