import 'dart:math';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../main.dart';

/// Pantalla de bienvenida (splash) que se muestra al abrir la app durante
/// aproximadamente 2.5 segundos, antes de pasar a la navegación principal.
///
/// Animación:
///  1. Fondo verde oscuro (#1A3A2F) de inmediato.
///  2. Varias hojas (íconos "eco") aparecen escalando y girando levemente,
///     de forma escalonada, como si brotaran alrededor del logo central.
///  3. El logo circular con la hoja principal aparece con un efecto de
///     "pop" (escala con rebote).
///  4. El texto "AGROCHECK" se desliza hacia arriba y aparece con fade
///     justo debajo del logo.
///  5. Tras completarse, navega automáticamente a [MainScaffold].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Fases de la animación, expresadas como intervalos de 0.0 a 1.0 dentro
  // de la duración total del controller (2.5 segundos).
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final List<Animation<double>> _hojaScales;
  late final List<Animation<double>> _hojaOpacities;

  // Posiciones relativas (offsets) de las hojas decorativas alrededor del
  // logo central, con distintos tamaños y rotaciones para que se vea
  // orgánico y no como una grilla perfecta.
  final List<_HojaSpec> _hojas = const [
    _HojaSpec(dx: -90, dy: -70, size: 26, rotacion: -0.4, delay: 0.05),
    _HojaSpec(dx: 85, dy: -85, size: 22, rotacion: 0.5, delay: 0.12),
    _HojaSpec(dx: -110, dy: 20, size: 20, rotacion: 0.2, delay: 0.18),
    _HojaSpec(dx: 100, dy: 10, size: 30, rotacion: -0.3, delay: 0.08),
    _HojaSpec(dx: -60, dy: 90, size: 18, rotacion: 0.6, delay: 0.22),
    _HojaSpec(dx: 65, dy: 95, size: 24, rotacion: -0.5, delay: 0.15),
    _HojaSpec(dx: 0, dy: -110, size: 20, rotacion: 0.1, delay: 0.25),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // El logo aparece primero, con un ligero efecto de rebote (0% - 45%).
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.12).chain(CurveTween(curve: Curves.easeOutBack)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.45)));

    _logoOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25));

    // El texto "AGROCHECK" aparece después, deslizándose hacia arriba (35% - 65%).
    _textOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.65, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic)),
    );

    // Cada hoja tiene su propio pequeño retraso para que el conjunto se
    // sienta orgánico ("brotando") en vez de aparecer todas a la vez.
    _hojaScales = _hojas.map((h) {
      final start = h.delay;
      final end = (h.delay + 0.35).clamp(0.0, 1.0);
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)), weight: 70),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      ]).animate(CurvedAnimation(parent: _controller, curve: Interval(start, end)));
    }).toList();

    _hojaOpacities = _hojas.map((h) {
      final start = h.delay;
      final end = (h.delay + 0.2).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _controller, curve: Interval(start, end));
    }).toList();

    _controller.forward();

    // Al terminar la animación (2.5s), navega a la pantalla principal.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const MainScaffold(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardDark,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Halo decorativo suave detrás del logo.
              Opacity(
                opacity: _logoOpacity.value * 0.5,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentGreen.withOpacity(0.15),
                  ),
                ),
              ),

              // Hojas decorativas alrededor del logo.
              for (var i = 0; i < _hojas.length; i++)
                Transform.translate(
                  offset: Offset(_hojas[i].dx, _hojas[i].dy),
                  child: Opacity(
                    opacity: _hojaOpacities[i].value,
                    child: Transform.scale(
                      scale: _hojaScales[i].value,
                      child: Transform.rotate(
                        angle: _hojas[i].rotacion,
                        child: Icon(
                          Icons.eco_rounded,
                          size: _hojas[i].size,
                          color: AppColors.accentGreen.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ),
                ),

              // Contenido central: logo + nombre de la app.
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.eco_rounded, size: 54, color: AppColors.cardDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: const [
                          Text(
                            'AGROCHECK',
                            style: TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Diagnóstico agrícola con IA — 100% offline',
                            style: TextStyle(
                              color: Color(0xFFC9D8CE),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Especificación de una hoja decorativa individual en la animación.
class _HojaSpec {
  final double dx;
  final double dy;
  final double size;
  final double rotacion;
  final double delay; // 0.0 - 1.0, punto de inicio dentro de la animación

  const _HojaSpec({
    required this.dx,
    required this.dy,
    required this.size,
    required this.rotacion,
    required this.delay,
  });
}
