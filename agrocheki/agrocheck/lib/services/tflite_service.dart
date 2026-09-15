import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Resultado de una clasificación de imagen.
class ClasificacionResultado {
  final String cultivo; // CACAO, PLATANO, LIMON
  final String enfermedad; // ej. "Monilia", "Sano"
  final double confianza; // 0.0 - 1.0
  final String tratamientoRecomendado;

  ClasificacionResultado({
    required this.cultivo,
    required this.enfermedad,
    required this.confianza,
    required this.tratamientoRecomendado,
  });
}

/// Servicio que carga el modelo TensorFlow Lite (.tflite) empaquetado en los
/// assets de la app y clasifica fotos de hojas/frutos de cacao, plátano y
/// limón para detectar enfermedades comunes. Todo el procesamiento ocurre
/// en el dispositivo: no requiere conexión a internet.
///
/// Enfermedades cubiertas por el modelo (deben coincidir 1:1 con el orden
/// del archivo assets/model/labels.txt con el que se entrenó el modelo):
///   CACAO:    Monilia, Escoba de bruja, Mal de machete, Sano
///   PLATANO:  Sigatoka negra, Sigatoka amarilla, Mal de Panamá, Sano
///   LIMON:    Cancro cítrico, Antracnosis, Sano
class TFLiteService {
  static final TFLiteService instance = TFLiteService._internal();
  TFLiteService._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];

  static const String _modelPath = 'assets/model/modelo_agrocheck.tflite';
  static const String _labelsPath = 'assets/model/labels.txt';

  // Tamaño de entrada esperado por el modelo (ajustar según el modelo real
  // entrenado, comúnmente 224x224 para arquitecturas tipo MobileNet).
  static const int inputSize = 224;

  bool get modeloListo => _interpreter != null;

  /// Carga el modelo .tflite y las etiquetas desde los assets.
  /// Debe llamarse una vez al iniciar la app (ver main.dart).
  Future<void> cargarModelo() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      final labelsData = await _cargarEtiquetas();
      _labels = labelsData;
    } catch (e) {
      // Si el modelo aún no ha sido colocado en assets/model/, la app sigue
      // funcionando en un modo de demostración (ver _clasificarSimulado).
      _interpreter = null;
    }
  }

  Future<List<String>> _cargarEtiquetas() async {
    try {
      final raw = await rootBundle.loadString(_labelsPath);
      return raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    } catch (_) {
      return _etiquetasPorDefecto;
    }
  }

  // Etiquetas de referencia (usadas si no se encuentra labels.txt).
  static const List<String> _etiquetasPorDefecto = [
    'CACAO_Monilia',
    'CACAO_EscobaDeBruja',
    'CACAO_MalDeMachete',
    'CACAO_Sano',
    'PLATANO_SigatokaNegra',
    'PLATANO_SigatokaAmarilla',
    'PLATANO_MalDePanama',
    'PLATANO_Sano',
    'LIMON_CancroCitrico',
    'LIMON_Antracnosis',
    'LIMON_Sano',
  ];

  /// Clasifica una imagen ubicada en [rutaImagen] y retorna el cultivo,
  /// la enfermedad detectada, el nivel de confianza y una recomendación
  /// de tratamiento asociada.
  Future<ClasificacionResultado> clasificarImagen(String rutaImagen) async {
    if (_interpreter == null) {
      // Modo demostración: permite probar el flujo completo de la app
      // aunque todavía no se haya integrado el modelo .tflite entrenado.
      return _clasificarSimulado();
    }

    final bytes = await File(rutaImagen).readAsBytes();
    final imagenDecodificada = img.decodeImage(bytes);
    if (imagenDecodificada == null) {
      return _clasificarSimulado();
    }

    // Preprocesamiento: redimensionar y normalizar a [0, 1].
    final imagenRedimensionada = img.copyResize(
      imagenDecodificada,
      width: inputSize,
      height: inputSize,
    );

    final input = _imagenATensor(imagenRedimensionada);
    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(input, output);

    final scores = List<double>.from(output[0]);
    final maxIndex = _indiceMaximo(scores);
    final confianza = scores[maxIndex];
    final etiqueta = _labels.isNotEmpty ? _labels[maxIndex] : _etiquetasPorDefecto[maxIndex];

    return _construirResultadoDesdeEtiqueta(etiqueta, confianza);
  }

  /// Convierte la imagen decodificada en el tensor de entrada 4D
  /// [1, inputSize, inputSize, 3] normalizado en el rango [0, 1].
  List<List<List<List<double>>>> _imagenATensor(img.Image imagen) {
    return List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = imagen.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
  }

  int _indiceMaximo(List<double> valores) {
    var maxIdx = 0;
    for (var i = 1; i < valores.length; i++) {
      if (valores[i] > valores[maxIdx]) maxIdx = i;
    }
    return maxIdx;
  }

  /// Traduce una etiqueta cruda del modelo (ej. "CACAO_Monilia") en un
  /// resultado legible con el cultivo, el nombre de la enfermedad y el
  /// tratamiento recomendado correspondiente.
  ClasificacionResultado _construirResultadoDesdeEtiqueta(
    String etiqueta,
    double confianza,
  ) {
    final partes = etiqueta.split('_');
    final cultivoCodigo = partes.isNotEmpty ? partes[0] : 'DESCONOCIDO';
    final enfermedadCodigo = partes.length > 1 ? partes[1] : 'Desconocido';

    final cultivo = _nombreCultivo(cultivoCodigo);
    final enfermedad = _nombreEnfermedad(enfermedadCodigo);
    final tratamiento = _tratamientoPara(cultivoCodigo, enfermedadCodigo);

    return ClasificacionResultado(
      cultivo: cultivo,
      enfermedad: enfermedad,
      confianza: confianza,
      tratamientoRecomendado: tratamiento,
    );
  }

  String _nombreCultivo(String codigo) {
    switch (codigo) {
      case 'CACAO':
        return 'Cacao';
      case 'PLATANO':
        return 'Plátano/Banano';
      case 'LIMON':
        return 'Limón';
      default:
        return codigo;
    }
  }

  String _nombreEnfermedad(String codigo) {
    const mapa = {
      'Monilia': 'Monilia (Moniliophthora roreri)',
      'EscobaDeBruja': 'Escoba de bruja',
      'MalDeMachete': 'Mal de machete',
      'SigatokaNegra': 'Sigatoka negra',
      'SigatokaAmarilla': 'Sigatoka amarilla',
      'MalDePanama': 'Mal de Panamá',
      'CancroCitrico': 'Cancro cítrico',
      'Antracnosis': 'Antracnosis',
      'Sano': 'Cultivo sano',
    };
    return mapa[codigo] ?? codigo;
  }

  /// Recomendaciones básicas de manejo agronómico por enfermedad.
  /// Estas deben ser revisadas y ampliadas junto a un agrónomo/INIAP
  /// antes de un despliegue en producción.
  String _tratamientoPara(String cultivo, String enfermedad) {
    const tratamientos = {
      'CACAO_Monilia':
          'Retirar y eliminar frutos enfermos (no dejarlos en el suelo). '
          'Podar para mejorar ventilación y aplicar fungicida a base de cobre '
          'según indicación técnica. Cosechar frecuentemente.',
      'CACAO_EscobaDeBruja':
          'Podar y quemar las ramas afectadas ("escobas"). Mejorar drenaje '
          'y ventilación de la plantación. Usar material genético resistente '
          'en nuevas siembras.',
      'CACAO_MalDeMachete':
          'Eliminar y quemar árboles muy afectados. Desinfectar herramientas '
          'de poda entre plantas. Evitar heridas en el tronco.',
      'CACAO_Sano': 'No se detectaron signos de enfermedad. Continuar con manejo preventivo habitual.',
      'PLATANO_SigatokaNegra':
          'Eliminar hojas muy afectadas (deshoje sanitario). Mejorar drenaje '
          'del terreno y aplicar programa de fungicidas foliares recomendado '
          'por el técnico agrícola local.',
      'PLATANO_SigatokaAmarilla':
          'Deshoje sanitario, mejorar drenaje y ventilación del cultivo. '
          'Fertilización balanceada para fortalecer la planta.',
      'PLATANO_MalDePanama':
          'Aislar y eliminar plantas afectadas. Desinfectar herramientas. '
          'No replantar plátano/banano en el mismo sitio sin variedad resistente.',
      'PLATANO_Sano': 'No se detectaron signos de enfermedad. Continuar con manejo preventivo habitual.',
      'LIMON_CancroCitrico':
          'Podar y quemar partes afectadas. Desinfectar herramientas con '
          'hipoclorito entre cortes. Evitar riego por aspersión que salpique hojas.',
      'LIMON_Antracnosis':
          'Retirar frutos y ramas afectadas. Mejorar ventilación de la copa. '
          'Aplicar fungicida a base de cobre en época lluviosa.',
      'LIMON_Sano': 'No se detectaron signos de enfermedad. Continuar con manejo preventivo habitual.',
    };
    return tratamientos['${cultivo}_$enfermedad'] ??
        'Consultar con un técnico agrícola de confianza para confirmar el diagnóstico.';
  }

  /// Genera un resultado simulado plausible, usado únicamente cuando el
  /// modelo .tflite todavía no ha sido colocado en assets/model/. Esto
  /// permite demostrar y probar toda la interfaz de la app sin bloquear
  /// el desarrollo mientras se entrena el modelo real.
  ClasificacionResultado _clasificarSimulado() {
    final random = Random();
    final etiqueta = _etiquetasPorDefecto[random.nextInt(_etiquetasPorDefecto.length)];
    final confianza = 0.75 + random.nextDouble() * 0.24; // entre 75% y 99%
    return _construirResultadoDesdeEtiqueta(etiqueta, confianza);
  }

  void liberar() {
    _interpreter?.close();
  }
}

