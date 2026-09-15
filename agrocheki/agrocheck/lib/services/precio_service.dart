import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../database/database_helper.dart';
import '../models/precio_model.dart';

/// Resultado devuelto al pedir el precio actual: incluye el valor y si
/// proviene de internet (en vivo) o del cache local (offline).
class PrecioResultado {
  final double precioUsdKg;
  final String mercado;
  final String fuente;
  final DateTime fecha;
  final bool esOffline;

  PrecioResultado({
    required this.precioUsdKg,
    required this.mercado,
    required this.fuente,
    required this.fecha,
    required this.esOffline,
  });
}

/// Servicio encargado de obtener el precio del cacao en el mercado
/// ecuatoriano (Arenillas / Guayaquil).
///
/// IMPORTANTE: Reemplaza [_endpoint] por el endpoint real de tu proveedor
/// de datos (ej. API del MAG, bolsa de productos, o tu propio backend que
/// recopile precios de mercado). Este servicio ya maneja:
///   1. Verificación de conectividad real (no solo si hay wifi/datos, sino
///      si efectivamente hay salida a internet).
///   2. Descarga y parseo del precio si hay conexión.
///   3. Guardado automático en SQLite (precios_cache) para uso offline.
///   4. Fallback automático al último precio guardado si no hay internet
///      o si la petición falla.
class PrecioService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  
  static const String _endpoint =
      'https://query1.finance.yahoo.com/v8/finance/chart/CC=F';

  /// Verifica si el dispositivo tiene una conexión de red utilizable.
  /// connectivity_plus solo confirma que hay una interfaz activa (wifi/datos),
  /// por eso además se intenta un lookup real más abajo al hacer la petición.
  Future<bool> _hayConexion() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Obtiene el precio actual del cacao.
  /// - Si hay internet: consulta la API, guarda el resultado en cache y lo
  ///   retorna marcado como "en vivo".
  /// - Si no hay internet o la API falla: retorna el último precio guardado
  ///   en SQLite, marcado como "offline".
  Future<PrecioResultado> obtenerPrecioActual() async {
    final tieneRed = await _hayConexion();

    if (tieneRed) {
      try {
        final response = await http
            .get(Uri.parse(_endpoint))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;

          // Se espera un JSON del estilo:
          // { "precio_kg": 3.15, "mercado": "Arenillas / Guayaquil", "fuente": "API-MAG" }
          final precio = (data['precio_kg'] as num).toDouble();
          final mercado = data['mercado'] as String? ?? 'Arenillas / Guayaquil';
          final fuente = data['fuente'] as String? ?? 'API oficial';

          final ahora = DateTime.now();

          // Guardar en cache local para disponibilidad offline futura.
          await _db.guardarPrecioCache(PrecioCache(
            fecha: ahora.toIso8601String(),
            precioCacao: precio,
            mercado: mercado,
            fuente: fuente,
          ));

          return PrecioResultado(
            precioUsdKg: precio,
            mercado: mercado,
            fuente: fuente,
            fecha: ahora,
            esOffline: false,
          );
        }
      } catch (_) {
        // Si falla la petición (timeout, servidor caído, etc.) se cae al
        // bloque de abajo y se usa el último precio guardado.
      }
    }

    // ----- Modo offline / fallback -----
    final ultimo = await _db.obtenerUltimoPrecio();

    if (ultimo != null) {
      return PrecioResultado(
        precioUsdKg: ultimo.precioCacao,
        mercado: ultimo.mercado,
        fuente: ultimo.fuente,
        fecha: DateTime.parse(ultimo.fecha),
        esOffline: true,
      );
    }

    // Si nunca hubo ni conexión ni cache previo, se retorna un valor
    // semilla razonable para que la app no falle en el primer uso.
    final ahora = DateTime.now();
    final semilla = PrecioCache(
      fecha: ahora.toIso8601String(),
      precioCacao: 3.15,
      mercado: 'Arenillas / Guayaquil',
      fuente: 'Valor de referencia inicial',
    );
    await _db.guardarPrecioCache(semilla);

    return PrecioResultado(
      precioUsdKg: semilla.precioCacao,
      mercado: semilla.mercado,
      fuente: semilla.fuente,
      fecha: ahora,
      esOffline: true,
    );
  }

  /// Devuelve la serie de los últimos 7 precios guardados para graficar
  /// la tendencia semanal (Lun-Dom) en la pantalla de inicio.
  Future<List<PuntoTendencia>> obtenerTendenciaSemanal() async {
    final historial = await _db.obtenerHistorialPrecios(dias: 7);

    const diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    if (historial.isEmpty) {
      // Serie de ejemplo si todavía no hay suficiente histórico local.
      return  [
        PuntoTendencia('Lun', 3.05),
        PuntoTendencia('Mar', 3.08),
        PuntoTendencia('Mié', 3.10),
        PuntoTendencia('Jue', 3.09),
        PuntoTendencia('Vie', 3.12),
        PuntoTendencia('Sáb', 3.13),
        PuntoTendencia('Dom', 3.15),
      ];
    }

    return List.generate(historial.length, (i) {
      final etiqueta = i < diasSemana.length ? diasSemana[i] : '';
      return PuntoTendencia(etiqueta, historial[i].precioCacao);
    });
  }

  /// Calcula la variación porcentual entre el primer y último punto de la
  /// tendencia semanal, usada para el indicador "▲ 1.2%".
  double calcularVariacionPorcentual(List<PuntoTendencia> serie) {
    if (serie.length < 2) return 0.0;
    final inicio = serie.first.precio;
    final fin = serie.last.precio;
    if (inicio == 0) return 0.0;
    return ((fin - inicio) / inicio) * 100;
  }
}
