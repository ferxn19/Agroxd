import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/historial_model.dart';
import '../models/precio_model.dart';

/// Maneja toda la persistencia local de AGROCHECK usando SQLite (sqflite).
/// Funciona 100% sin conexión a internet, lo cual es clave para agricultores
/// en zonas rurales de El Oro con conectividad intermitente.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'agrocheck.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de historial de análisis de IA
    await db.execute('''
      CREATE TABLE historial (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        tipo_cultivo TEXT NOT NULL,
        enfermedad_detectada TEXT NOT NULL,
        confianza REAL NOT NULL,
        foto_path TEXT NOT NULL,
        tratamiento_recomendado TEXT NOT NULL
      )
    ''');

    // Tabla de cache de precios de mercado
    await db.execute('''
      CREATE TABLE precios_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        precio_cacao REAL NOT NULL,
        mercado TEXT NOT NULL,
        fuente TEXT NOT NULL
      )
    ''');
  }

  // ---------------------------------------------------------------------
  // CRUD: historial
  // ---------------------------------------------------------------------

  Future<int> insertarHistorial(HistorialItem item) async {
    final db = await database;
    return await db.insert('historial', item.toMap());
  }

  Future<List<HistorialItem>> obtenerHistorial({int? limite}) async {
    final db = await database;
    final maps = await db.query(
      'historial',
      orderBy: 'fecha DESC',
      limit: limite,
    );
    return maps.map((m) => HistorialItem.fromMap(m)).toList();
  }

  Future<int> eliminarHistorial(int id) async {
    final db = await database;
    return await db.delete('historial', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> contarAnalisis() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM historial');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------------------------------------------------------------------
  // CRUD: precios_cache
  // ---------------------------------------------------------------------

  Future<int> guardarPrecioCache(PrecioCache precio) async {
    final db = await database;
    return await db.insert('precios_cache', precio.toMap());
  }

  /// Devuelve el último precio guardado (el más reciente por fecha).
  Future<PrecioCache?> obtenerUltimoPrecio() async {
    final db = await database;
    final maps = await db.query(
      'precios_cache',
      orderBy: 'fecha DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PrecioCache.fromMap(maps.first);
  }

  /// Devuelve los últimos [dias] precios guardados, en orden cronológico
  /// ascendente, para construir el gráfico de tendencia semanal.
  Future<List<PrecioCache>> obtenerHistorialPrecios({int dias = 7}) async {
    final db = await database;
    final maps = await db.query(
      'precios_cache',
      orderBy: 'fecha DESC',
      limit: dias,
    );
    final lista = maps.map((m) => PrecioCache.fromMap(m)).toList();
    return lista.reversed.toList();
  }
}
