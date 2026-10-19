import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton que gestiona la conexión SQLite de la app.
class ArticulosDB {
  static const String _nameDB = "alacena.db";
  static const int _versionDB = 3;

  static Database? _database;

  static final ArticulosDB _instance = ArticulosDB._internal();
  factory ArticulosDB() => _instance;
  ArticulosDB._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDataBase();
    return _database!;
  }

  Future<Database> _initDataBase() async {
    Directory folder = await getApplicationDocumentsDirectory();
    String pathDB = join(folder.path, _nameDB);
    return openDatabase(
      pathDB,
      version: _versionDB,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tiendas(
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre     TEXT    NOT NULL,
        direccion  TEXT,
        created_at TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE productos(
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre            TEXT    NOT NULL,
        categoria         TEXT    NOT NULL DEFAULT 'General',
        unidad            TEXT    NOT NULL DEFAULT 'piezas',
        cantidad_minima   REAL    NOT NULL DEFAULT 1,
        imagen_path       TEXT,
        ultima_tienda_id  INTEGER,
        created_at        TEXT    NOT NULL,
        updated_at        TEXT    NOT NULL,
        FOREIGN KEY (ultima_tienda_id) REFERENCES tiendas(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lotes(
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id        INTEGER NOT NULL,
        cantidad           REAL    NOT NULL DEFAULT 0,
        fecha_vencimiento  TEXT,
        created_at         TEXT    NOT NULL,
        updated_at         TEXT    NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE historial_compras(
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id   INTEGER NOT NULL,
        tienda_id     INTEGER NOT NULL,
        lote_id       INTEGER,
        cantidad      REAL    NOT NULL,
        precio        REAL,
        fecha_compra  TEXT    NOT NULL,
        notas         TEXT,
        created_at    TEXT    NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos(id),
        FOREIGN KEY (tienda_id) REFERENCES tiendas(id),
        FOREIGN KEY (lote_id) REFERENCES lotes(id)
      )
    ''');

    await _createListaCompra(db);
    await _insertarDatosPrueba(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createListaCompra(db);
    }
    if (oldVersion < 3) {
      await _migrarAVersion3(db);
    }
  }

  Future<void> _createListaCompra(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lista_compra(
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id  INTEGER,
        nombre       TEXT    NOT NULL,
        categoria    TEXT    NOT NULL DEFAULT 'General',
        cantidad     REAL    NOT NULL DEFAULT 1,
        unidad       TEXT    NOT NULL DEFAULT 'piezas',
        comprado     INTEGER NOT NULL DEFAULT 0,
        created_at   TEXT    NOT NULL
      )
    ''');
  }

  /// Migra el esquema plano (cantidad/fecha en productos) a lotes + tiendas.
  Future<void> _migrarAVersion3(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tiendas(
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre     TEXT    NOT NULL,
        direccion  TEXT,
        created_at TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lotes(
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id        INTEGER NOT NULL,
        cantidad           REAL    NOT NULL DEFAULT 0,
        fecha_vencimiento  TEXT,
        created_at         TEXT    NOT NULL,
        updated_at         TEXT    NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS historial_compras(
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id   INTEGER NOT NULL,
        tienda_id     INTEGER NOT NULL,
        lote_id       INTEGER,
        cantidad      REAL    NOT NULL,
        precio        REAL,
        fecha_compra  TEXT    NOT NULL,
        notas         TEXT,
        created_at    TEXT    NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos(id),
        FOREIGN KEY (tienda_id) REFERENCES tiendas(id),
        FOREIGN KEY (lote_id) REFERENCES lotes(id)
      )
    ''');

    // Añadir ultima_tienda_id si no existe
    final cols = await db.rawQuery('PRAGMA table_info(productos)');
    final nombres = cols.map((c) => c['name'] as String).toSet();
    if (!nombres.contains('ultima_tienda_id')) {
      await db.execute(
          'ALTER TABLE productos ADD COLUMN ultima_tienda_id INTEGER');
    }

    // Migrar stock existente a un lote por producto
    final productos = await db.query('productos');
    final now = DateTime.now().toIso8601String();
    for (final p in productos) {
      final id = p['id'] as int;
      final cantidad = (p['cantidad'] as num?)?.toDouble() ?? 0;
      final fv = p['fecha_vencimiento'] as String?;
      final existentes = await db.query(
        'lotes',
        where: 'producto_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existentes.isEmpty) {
        await db.insert('lotes', {
          'producto_id': id,
          'cantidad': cantidad,
          'fecha_vencimiento': fv,
          'created_at': now,
          'updated_at': now,
        });
      }
    }

    // Tiendas semilla si la tabla está vacía
    final tiendas = await db.query('tiendas', limit: 1);
    if (tiendas.isEmpty) {
      await _insertarTiendasPrueba(db);
    }
  }

  Future<void> _insertarTiendasPrueba(Database db) async {
    final now = DateTime.now().toIso8601String();
    final tiendas = [
      {'nombre': 'Walmart', 'direccion': 'Av. Principal 100', 'created_at': now},
      {'nombre': 'Soriana', 'direccion': 'Blvd. Norte 45', 'created_at': now},
      {'nombre': 'Chedraui', 'direccion': 'Calle Centro 12', 'created_at': now},
      {
        'nombre': 'Mercado Local',
        'direccion': 'Plaza del pueblo',
        'created_at': now
      },
    ];
    for (final t in tiendas) {
      await db.insert('tiendas', t);
    }
  }

  Future<void> _insertarDatosPrueba(Database db) async {
    await _insertarTiendasPrueba(db);

    final now = DateTime.now();
    final String nowStr = now.toIso8601String();
    String fv(int dias) =>
        now.add(Duration(days: dias)).toIso8601String().substring(0, 10);

    final productos = [
      {
        'nombre': 'Leche Entera',
        'categoria': 'Lácteos',
        'unidad': 'L',
        'cantidad_minima': 1.0,
        'imagen_path': null,
        'ultima_tienda_id': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
        'lotes': [
          {'cantidad': 0.5, 'fecha_vencimiento': fv(2)},
          {'cantidad': 1.0, 'fecha_vencimiento': fv(10)},
        ],
        'compra': {'tienda_id': 1, 'cantidad': 1.5},
      },
      {
        'nombre': 'Yogur Natural',
        'categoria': 'Lácteos',
        'unidad': 'piezas',
        'cantidad_minima': 2.0,
        'imagen_path': null,
        'ultima_tienda_id': 2,
        'created_at': nowStr,
        'updated_at': nowStr,
        'lotes': [
          {'cantidad': 1.0, 'fecha_vencimiento': fv(5)},
        ],
        'compra': {'tienda_id': 2, 'cantidad': 1.0},
      },
      {
        'nombre': 'Pan Integral',
        'categoria': 'Panadería',
        'unidad': 'piezas',
        'cantidad_minima': 1.0,
        'imagen_path': null,
        'ultima_tienda_id': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
        'lotes': [
          {'cantidad': 0.0, 'fecha_vencimiento': fv(3)},
        ],
        'compra': {'tienda_id': 1, 'cantidad': 2.0},
      },
      {
        'nombre': 'Manzanas',
        'categoria': 'Frutas',
        'unidad': 'kg',
        'cantidad_minima': 1.0,
        'imagen_path': null,
        'ultima_tienda_id': 4,
        'created_at': nowStr,
        'updated_at': nowStr,
        'lotes': [
          {'cantidad': 1.0, 'fecha_vencimiento': fv(4)},
          {'cantidad': 1.0, 'fecha_vencimiento': fv(12)},
        ],
        'compra': {'tienda_id': 4, 'cantidad': 2.0},
      },
      {
        'nombre': 'Aceite de Oliva',
        'categoria': 'Aceites',
        'unidad': 'L',
        'cantidad_minima': 0.5,
        'imagen_path': null,
        'ultima_tienda_id': 3,
        'created_at': nowStr,
        'updated_at': nowStr,
        'lotes': [
          {'cantidad': 0.3, 'fecha_vencimiento': fv(180)},
        ],
        'compra': {'tienda_id': 3, 'cantidad': 0.3},
      },
      {
        'nombre': 'Huevos',
        'categoria': 'Huevos',
        'unidad': 'piezas',
        'cantidad_minima': 6.0,
        'imagen_path': null,
        'ultima_tienda_id': 2,
        'created_at': nowStr,
        'updated_at': nowStr,
        'lotes': [
          {'cantidad': 3.0, 'fecha_vencimiento': fv(14)},
        ],
        'compra': {'tienda_id': 2, 'cantidad': 12.0},
      },
      {
        'nombre': 'Detergente',
        'categoria': 'Limpieza',
        'unidad': 'L',
        'cantidad_minima': 1.0,
        'imagen_path': null,
        'ultima_tienda_id': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
        'lotes': [
          {'cantidad': 0.2, 'fecha_vencimiento': null},
        ],
        'compra': {'tienda_id': 1, 'cantidad': 1.0},
      },
      {
        'nombre': 'Arroz',
        'categoria': 'Cereales',
        'unidad': 'kg',
        'cantidad_minima': 1.0,
        'imagen_path': null,
        'ultima_tienda_id': 3,
        'created_at': nowStr,
        'updated_at': nowStr,
        'lotes': <Map<String, dynamic>>[], // sin lotes → agotado
        'compra': {'tienda_id': 3, 'cantidad': 1.0},
      },
    ];

    for (final p in productos) {
      final lotes = List<Map<String, dynamic>>.from(p['lotes'] as List);
      final compra = Map<String, dynamic>.from(p['compra'] as Map);
      final productoRow = Map<String, dynamic>.from(p)
        ..remove('lotes')
        ..remove('compra');

      final productoId = await db.insert('productos', productoRow);

      int? primerLoteId;
      for (final lote in lotes) {
        final loteId = await db.insert('lotes', {
          'producto_id': productoId,
          'cantidad': lote['cantidad'],
          'fecha_vencimiento': lote['fecha_vencimiento'],
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        primerLoteId ??= loteId;
      }

      await db.insert('historial_compras', {
        'producto_id': productoId,
        'tienda_id': compra['tienda_id'],
        'lote_id': primerLoteId,
        'cantidad': compra['cantidad'],
        'precio': null,
        'fecha_compra': nowStr.substring(0, 10),
        'notas': 'Dato de prueba',
        'created_at': nowStr,
      });
    }
  }
}
