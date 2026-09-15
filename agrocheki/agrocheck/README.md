# 🌿 AGROCHECK

App móvil (Android e iOS) para agricultores de Ecuador — diagnóstico de
enfermedades en cacao, plátano/banano y limón usando IA **100% offline**,
más precios de mercado del cacao y una calculadora de venta.

## Estructura del proyecto

```
agrocheck/
├── pubspec.yaml
├── assets/
│   ├── images/logo.png
│   └── model/
│       ├── modelo_agrocheck.tflite   ← REEMPLAZAR por tu modelo entrenado
│       ├── labels.txt
│       └── README_MODELO.txt         ← instrucciones sobre el modelo
├── android/                           # Configuración nativa Android (JVM 17 ya fijado)
│   ├── build.gradle.kts               # Fix global de JVM 17 para todos los módulos
│   ├── settings.gradle.kts
│   ├── gradle.properties
│   ├── gradle/wrapper/gradle-wrapper.properties
│   └── app/
│       ├── build.gradle.kts           # Fix de JVM 17 a nivel de app
│       └── src/
│           ├── main/
│           │   ├── AndroidManifest.xml    # Permisos cámara/internet/galería
│           │   ├── kotlin/.../MainActivity.kt
│           │   └── res/                   # Íconos, colores, temas del splash nativo
│           ├── debug/AndroidManifest.xml
│           └── profile/AndroidManifest.xml
└── lib/
    ├── main.dart                     # Punto de entrada + navegación inferior
    ├── constants/
    │   └── app_colors.dart           # Paleta de colores y estilos globales
    ├── database/
    │   └── database_helper.dart      # SQLite: tablas historial y precios_cache
    ├── models/
    │   ├── historial_model.dart
    │   └── precio_model.dart
    ├── services/
    │   ├── precio_service.dart       # API de precios + fallback offline
    │   └── tflite_service.dart       # Clasificación de enfermedades offline
    ├── screens/
    │   ├── splash_screen.dart        # Animación de bienvenida (2.5s)
    │   ├── home_screen.dart          # Pantalla de Inicio
    │   ├── historial_screen.dart     # Pantalla de Historial
    │   ├── precios_screen.dart       # Pantalla de Precios + calculadora
    │   ├── perfil_screen.dart        # Pantalla de Perfil
    │   └── resultado_analisis_screen.dart
    └── widgets/
        └── dark_card.dart            # DarkCard y LightCard reutilizables
```

## 🚀 Guía de despliegue por USB (Android, paso a paso en VS Code)

### ⚠️ Nota importante antes de empezar

Esta entrega incluye **todos los archivos de configuración de Gradle ya
corregidos** para JVM 17 (`android/build.gradle.kts`,
`android/app/build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`,
`gradle-wrapper.properties`, `AndroidManifest.xml`, `MainActivity.kt`, íconos
y temas).

Lo único que **no puedo generar yo** es el archivo binario
`android/gradle/wrapper/gradle-wrapper.jar` (el "motor" que descarga Gradle
la primera vez). Ese archivo se genera siempre desde tu propio SDK de
Flutter instalado, así que el Paso 1 de abajo lo crea automáticamente sin
que tengas que hacer nada manual — solo asegúrate de seguir el orden exacto.

### Paso 1 — Generar el wrapper de Gradle desde tu Flutter SDK

Descomprime el proyecto que te entregué, ábrelo en VS Code y en la terminal
integrada ejecuta, **desde la raíz del proyecto** (donde está `pubspec.yaml`):

```bash
flutter create --platforms=android .
```

Esto **no toca** tu `lib/`, `pubspec.yaml` ni `assets/` (ya existen y Flutter
los respeta); solo completa dentro de `android/` los archivos binarios que
faltan: `gradlew`, `gradlew.bat` y `gradle-wrapper.jar`. Los archivos
`build.gradle.kts`, `settings.gradle.kts`, `gradle.properties` y
`AndroidManifest.xml` que yo ya te dejé con el fix de JVM 17 **no se
sobreescriben** porque ese comando no reemplaza archivos que ya existen a
menos que estén vacíos.

### Paso 2 — Colocar tu modelo de IA

Copia tu archivo `.tflite` real dentro de:
```
assets/model/modelo_agrocheck.tflite
```
reemplazando el placeholder vacío (mismo nombre exacto, para que
`tflite_service.dart` lo encuentre sin tocar código).

### Paso 3 — Confirmar el JDK 17

En la terminal de VS Code:
```bash
java -version
```
Si no marca 17, edita `android/gradle.properties` y descomenta la línea
`org.gradle.java.home=...` con la ruta de tu instalación de JDK 17 (Windows,
macOS o Linux — las tres rutas de ejemplo ya están comentadas ahí mismo).

### Paso 4 — Limpiar cualquier build anterior

```bash
flutter clean
```

### Paso 5 — Descargar dependencias

```bash
flutter pub get
```

### Paso 6 — Conectar el celular y verificar que Flutter lo detecta

Activa "Depuración USB" en tu Android (Ajustes → Opciones de desarrollador)
y conecta el cable. Verifica:
```bash
flutter devices
```
Debe aparecer tu teléfono en la lista.

### Paso 7 — Ejecutar en el dispositivo físico

```bash
flutter run
```

Si tienes más de un dispositivo/emulador conectado, especifica el tuyo:
```bash
flutter run -d <id_del_dispositivo>
```
(el `id_del_dispositivo` sale en la lista del Paso 6).

### Si vuelve a fallar Gradle

1. Revisa que el mensaje de error mencione **1.8 vs 25** exactamente igual —
   si el número cambió (ej. ahora dice 21), significa que tu `java.home`
   del Paso 3 no se aplicó; verifica la ruta escrita.
2. Borra cachés de Gradle específicas del proyecto y reintenta:
   ```bash
   rm -rf android/.gradle android/app/build build
   flutter pub get
   flutter run
   ```
3. Si el error cambia a algo distinto (ej. sobre `namespace` o versión de
   AGP), pégame el mensaje nuevo tal cual — normalmente es un segundo
   problema encadenado y fácil de resolver.

### Sobre iOS

Este ZIP no incluye la carpeta `ios/` (el proyecto de Xcode no se puede
generar a mano de forma confiable, requiere las herramientas de Flutter).
Cuando quieras compilar para iPhone, desde una Mac con Flutter y Xcode
instalados, corre una sola vez:
```bash
flutter create --platforms=ios .
```
y luego agrega en `ios/Runner/Info.plist` los permisos de cámara/galería
que ya están documentados más abajo en este README.

**Permisos iOS de referencia** (agregar dentro de `<dict>` en `Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>AGROCHECK necesita la cámara para analizar tus cultivos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>AGROCHECK necesita acceso a tus fotos para analizar imágenes guardadas.</string>
```


## ⚠️ Sobre el modelo de IA (muy importante)

El archivo `assets/model/modelo_agrocheck.tflite` incluido es un **placeholder
vacío**. Debes entrenar y colocar aquí tu propio modelo TensorFlow Lite con
un dataset real de fotos de cacao, plátano/banano y limón (sanas y con las
enfermedades listadas). Opciones recomendadas:

- **Teachable Machine** (Google) → exportar como TensorFlow Lite. Rápido
  para un primer prototipo funcional.
- **Transfer learning con MobileNetV2** en Google Colab/TensorFlow, y luego
  convertir a `.tflite` con el conversor de TensorFlow.

Mientras no reemplaces ese archivo, `tflite_service.dart` detecta que el
modelo no es válido y usa un **modo de demostración** (genera resultados de
ejemplo aleatorios), así puedes probar y presentar el resto de la app
(cámara, historial, precios, etc.) sin bloquearte.

Requisitos del modelo para integrarlo sin tocar el código:
- Entrada: imagen RGB `224x224`, normalizada en `[0, 1]`.
- Salida: vector softmax con tantas posiciones como líneas tenga
  `labels.txt` (11 en este ejemplo).
- El orden de clases en `labels.txt` debe coincidir con el orden de
  entrenamiento.

## ⚠️ Sobre la API de precios

`lib/services/precio_service.dart` apunta a un endpoint de ejemplo
(`_endpoint`). Debes reemplazarlo por una fuente real de precios del cacao
en Ecuador (por ejemplo, un backend propio que recopile datos de Arenillas/
Guayaquil, o una API pública/gremial si está disponible). El servicio ya
maneja automáticamente:

- Verificación real de conectividad (`connectivity_plus`).
- Descarga y guardado en cache SQLite cuando hay internet.
- Uso automático del último precio guardado cuando **no** hay internet,
  mostrando el aviso *"Precio offline - última actualización: [fecha]"*.

## Base de datos SQLite

**Tabla `historial`**
| Campo | Tipo |
|---|---|
| id | INTEGER PK |
| fecha | TEXT (ISO8601) |
| tipo_cultivo | TEXT |
| enfermedad_detectada | TEXT |
| confianza | REAL |
| foto_path | TEXT |
| tratamiento_recomendado | TEXT |

**Tabla `precios_cache`**
| Campo | Tipo |
|---|---|
| id | INTEGER PK |
| fecha | TEXT (ISO8601) |
| precio_cacao | REAL |
| mercado | TEXT |
| fuente | TEXT |

## Calculadora de venta

Conversión usada (quintal métrico estándar en el agro ecuatoriano):
- 1 quintal = 45.36 kg
- 1 libra = 0.4536 kg

Ejemplo: cacao a 3.15 USD/kg, vendiendo 5 quintales (226.8 kg) ≈ **$714.42**.
(El ejemplo de $1,575 mencionado en el brief corresponde a 500 kg exactos;
la app calcula siempre con la conversión real de quintales/libras a kg.)

## Notas de diseño

- Fondo beige `#E8E0D5`, tarjetas verde oscuro `#1A3A2F` con bordes
  redondeados (`AppMetrics.cardRadius = 20`).
- Tipografía `Nunito` (Google Fonts) por su alta legibilidad en pantallas
  pequeñas y bajo luz solar directa.
- Layout de dos columnas en pantallas anchas; se apila verticalmente en
  celulares muy angostos (`< 340px` de ancho) para no romper el diseño.
