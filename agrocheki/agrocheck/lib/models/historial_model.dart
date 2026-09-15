/// Representa un registro de análisis de IA guardado en SQLite.
/// Cada vez que el agricultor toma una foto (o elige una de galería) y el
/// modelo TFLite la clasifica, se guarda una fila de esta tabla.
class HistorialItem {
  final int? id;
  final String fecha; // formato ISO8601
  final String tipoCultivo; // CACAO, PLATANO, LIMON
  final String enfermedadDetectada; // ej. "Monilia", "Sigatoka negra", "Sano"
  final double confianza; // 0.0 - 1.0
  final String fotoPath; // ruta local de la imagen analizada
  final String tratamientoRecomendado;

  HistorialItem({
    this.id,
    required this.fecha,
    required this.tipoCultivo,
    required this.enfermedadDetectada,
    required this.confianza,
    required this.fotoPath,
    required this.tratamientoRecomendado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'tipo_cultivo': tipoCultivo,
      'enfermedad_detectada': enfermedadDetectada,
      'confianza': confianza,
      'foto_path': fotoPath,
      'tratamiento_recomendado': tratamientoRecomendado,
    };
  }

  factory HistorialItem.fromMap(Map<String, dynamic> map) {
    return HistorialItem(
      id: map['id'] as int?,
      fecha: map['fecha'] as String,
      tipoCultivo: map['tipo_cultivo'] as String,
      enfermedadDetectada: map['enfermedad_detectada'] as String,
      confianza: (map['confianza'] as num).toDouble(),
      fotoPath: map['foto_path'] as String,
      tratamientoRecomendado: map['tratamiento_recomendado'] as String,
    );
  }
}
