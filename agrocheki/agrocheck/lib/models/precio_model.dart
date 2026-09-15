/// Representa un precio de mercado (ej. cacao) guardado en cache SQLite,
/// para poder mostrarlo cuando el dispositivo no tiene conexión a internet.
class PrecioCache {
  final int? id;
  final String fecha; // ISO8601
  final double precioCacao; // USD/kg
  final String mercado; // Arenillas, Guayaquil, etc.
  final String fuente; // ej. "API-MAG", "Manual"

  PrecioCache({
    this.id,
    required this.fecha,
    required this.precioCacao,
    required this.mercado,
    required this.fuente,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'precio_cacao': precioCacao,
      'mercado': mercado,
      'fuente': fuente,
    };
  }

  factory PrecioCache.fromMap(Map<String, dynamic> map) {
    return PrecioCache(
      id: map['id'] as int?,
      fecha: map['fecha'] as String,
      precioCacao: (map['precio_cacao'] as num).toDouble(),
      mercado: map['mercado'] as String,
      fuente: map['fuente'] as String,
    );
  }
}

/// Punto de la serie histórica semanal usada en el gráfico de tendencias
/// de la pantalla de inicio (Lunes a Domingo).
class PuntoTendencia {
  final String diaAbrev; // "Lun", "Mar", ...
  final double precio;

  PuntoTendencia(this.diaAbrev, this.precio);
}
