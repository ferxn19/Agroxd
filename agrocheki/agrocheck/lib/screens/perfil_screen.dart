import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../database/database_helper.dart';
import '../widgets/dark_card.dart';

/// Pantalla de Perfil / Configuración. Permite al agricultor ver un resumen
/// de su actividad (cantidad de análisis realizados), configurar el nombre
/// de su finca y ajustar preferencias básicas de la app.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  int _totalAnalisis = 0;
  String _nombreFinca = 'Mi finca';
  bool _notificacionesPrecios = true;
  bool _guardarFotosOriginales = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final total = await _db.contarAnalisis();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _totalAnalisis = total;
      _nombreFinca = prefs.getString('nombre_finca') ?? 'Mi finca';
      _notificacionesPrecios = prefs.getBool('notif_precios') ?? true;
      _guardarFotosOriginales = prefs.getBool('guardar_fotos') ?? true;
    });
  }

  Future<void> _editarNombreFinca() async {
    final controller = TextEditingController(text: _nombreFinca);
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre de tu finca'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Ej: Finca San José'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado != null && resultado.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nombre_finca', resultado);
      setState(() => _nombreFinca = resultado);
    }
  }

  Future<void> _toggleNotificaciones(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_precios', valor);
    setState(() => _notificacionesPrecios = valor);
  }

  Future<void> _toggleGuardarFotos(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guardar_fotos', valor);
    setState(() => _guardarFotosOriginales = valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppMetrics.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTarjetaUsuario(),
            const SizedBox(height: AppMetrics.paddingL),
            const Text('Preferencias', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            _buildOpcion(
              icono: Icons.notifications_active_rounded,
              titulo: 'Notificaciones de precios',
              subtitulo: 'Avisos cuando el precio del cacao suba o baje',
              trailing: Switch(
                value: _notificacionesPrecios,
                activeColor: AppColors.accentGreen,
                onChanged: _toggleNotificaciones,
              ),
            ),
            const SizedBox(height: 10),
            _buildOpcion(
              icono: Icons.photo_library_rounded,
              titulo: 'Guardar fotos originales',
              subtitulo: 'Conserva las imágenes analizadas en el dispositivo',
              trailing: Switch(
                value: _guardarFotosOriginales,
                activeColor: AppColors.accentGreen,
                onChanged: _toggleGuardarFotos,
              ),
            ),
            const SizedBox(height: 10),
            _buildOpcion(
              icono: Icons.agriculture_rounded,
              titulo: 'Nombre de la finca',
              subtitulo: _nombreFinca,
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: _editarNombreFinca,
            ),
            const SizedBox(height: AppMetrics.paddingL),
            const Text('Acerca de', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            _buildOpcion(
              icono: Icons.info_outline_rounded,
              titulo: 'Versión de AGROCHECK',
              subtitulo: '1.0.0',
            ),
            const SizedBox(height: 10),
            _buildOpcion(
              icono: Icons.memory_rounded,
              titulo: 'Modelo de IA',
              subtitulo: 'Clasificación offline: cacao, plátano/banano, limón',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaUsuario() {
    return DarkCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.accentGreen, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nombreFinca, style: AppTextStyles.titleOnDark),
                const SizedBox(height: 4),
                Text(
                  '$_totalAnalisis análisis realizados',
                  style: AppTextStyles.subtitleOnDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return LightCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Icon(icono, color: AppColors.cardDark, size: 26),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        trailing: trailing,
      ),
    );
  }
}
