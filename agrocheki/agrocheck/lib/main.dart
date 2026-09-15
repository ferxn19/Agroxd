import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/precios_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/splash_screen.dart';
import 'services/tflite_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga el modelo TensorFlow Lite una sola vez al iniciar la app.
  // Si el archivo .tflite todavía no existe en assets/model/, el servicio
  // cae automáticamente a un modo de demostración (ver tflite_service.dart).
  await TFLiteService.instance.cargarModelo();

  runApp(const AgroCheckApp());
}

class AgroCheckApp extends StatelessWidget {
  const AgroCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGROCHECK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cardDark,
          background: AppColors.background,
          primary: AppColors.cardDark,
          secondary: AppColors.accentGreen,
        ),
        textTheme: GoogleFonts.nunitoTextTheme().apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// Contenedor principal que gestiona las 4 pestañas de navegación inferior:
/// Inicio, Historial, Precios y Perfil.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = const [
    HomeScreen(),
    HistorialScreen(),
    PreciosScreen(),
    PerfilScreen(),
  ];

  void _cambiarPestana(int index) {
    setState(() => _indiceActual = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _indiceActual,
          children: _pantallas,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _indiceActual,
            onTap: _cambiarPestana,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.accentGreen,
            unselectedItemColor: const Color(0xFFB9C2BB),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            iconSize: 26,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time_filled_rounded),
                label: 'Historial',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Precios',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
