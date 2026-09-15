IMPORTANTE - MODELO DE INTELIGENCIA ARTIFICIAL
================================================

Este proyecto espera encontrar aquí el archivo:

    modelo_agrocheck.tflite

Ese archivo NO está incluido porque debe ser entrenado con un dataset real
de fotos de cacao, plátano/banano y limón (sanas y enfermas), por ejemplo
usando Teachable Machine, TensorFlow/Keras + conversión a TFLite, o un
proyecto en Google Colab con MobileNetV2 como base (transfer learning).

Requisitos del modelo para que funcione con tflite_service.dart tal cual:
 - Entrada: imagen RGB de 224x224, normalizada en el rango [0, 1].
 - Salida: vector de probabilidades (softmax) de tamaño = número de clases
   en labels.txt (11 clases en este proyecto de ejemplo).
 - El orden de las clases en labels.txt DEBE coincidir exactamente con el
   orden usado al entrenar el modelo.

Mientras el archivo .tflite no exista en esta carpeta, la app funciona en
"modo demostración": simula resultados de clasificación aleatorios para que
puedas probar todo el flujo de la app (cámara, galería, historial, etc.)
sin bloquear el desarrollo del resto de funcionalidades.
