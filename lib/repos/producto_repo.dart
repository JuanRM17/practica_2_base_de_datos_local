import '../database/articulos_db.dart';
import '../models/lote.dart';
import '../models/producto.dart';

/// Repositorio de productos. El stock y la caducidad se derivan de [lotes].
class ProductoRepo {
  final ArticulosDB _db = ArticulosDB();

  /// SELECT base con stock total, lotes activos, próxima caducidad y última tienda.
  static const String _selectConStock = '''
    SELECT
      p.id,
      p.nombre,
      p.categoria,
      p.unidad,
      p.cantidad_minima,
      p.imagen_path,
      p.ultima_tienda_id,
      p.created_at,
      p.updated_at,
      t.nombre AS ultima_tienda_nombre,
      COALESCE((
        SELECT SUM(l.cantidad) FROM lotes l
        WHERE l.producto_id = p.id AND l.cantidad > 0
      ), 0) AS stock_total,
      COALESCE((
        SELECT COUNT(*) FROM lotes l
        WHERE l.producto_id = p.id AND l.cantidad > 0
      ), 0) AS lotes_activos,
      (
        SELECT MIN(l.fecha_vencimiento) FROM lotes l
        WHERE l.producto_id = p.id
          AND l.cantidad > 0
          AND l.fecha_vencimiento IS NOT NULL
      ) AS proxima_caducidad
    FROM productos p
    LEFT JOIN tiendas t ON t.id = p.ultima_tienda_id
  ''';

  Future<List<Producto>> getAllProductos() async {
    final db = await _db.database;
    final maps = await db.rawQuery('$_selectConStock ORDER BY p.nombre ASC');
    return maps.map(Producto.fromMap).toList();
  }

  Future<Producto?> getProductoById(int id) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_selectConStock WHERE p.id = ? LIMIT 1',
      [id],
    );
    if (maps.isEmpty) return null;
    return Producto.fromMap(maps.first);
  }

  /// Productos con lote activo cuya caducidad cae en los próximos [dias] días
  /// (incluye vencidos recientes).
  Future<List<Producto>> getProductosProximosAVencer({int dias = 7}) async {
    final db = await _db.database;
    final now = DateTime.now();
    final desde =
        now.subtract(const Duration(days: 365)).toIso8601String().substring(0, 10);
    final hasta = now.add(Duration(days: dias)).toIso8601String().substring(0, 10);

    final maps = await db.rawQuery('''
      $_selectConStock
      WHERE EXISTS (
        SELECT 1 FROM lotes l
        WHERE l.producto_id = p.id
          AND l.cantidad > 0
          AND l.fecha_vencimiento IS NOT NULL
          AND l.fecha_vencimiento >= ?
          AND l.fecha_vencimiento <= ?
      )
      ORDER BY proxima_caducidad ASC
    ''', [desde, hasta]);
    return maps.map(Producto.fromMap).toList();
  }

  /// Productos con al menos un lote activo con fecha de vencimiento.
  Future<List<Producto>> getProductosConFechaVencimiento() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      $_selectConStock
      WHERE EXISTS (
        SELECT 1 FROM lotes l
        WHERE l.producto_id = p.id
          AND l.cantidad > 0
          AND l.fecha_vencimiento IS NOT NULL
      )
      ORDER BY proxima_caducidad ASC
    ''');
    return maps.map(Producto.fromMap).toList();
  }

  /// Stock bajo o agotado (stock total <= mínimo, o sin lotes activos).
  Future<List<Producto>> getProductosStockBajo() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      $_selectConStock
      WHERE COALESCE((
        SELECT SUM(l.cantidad) FROM lotes l
        WHERE l.producto_id = p.id AND l.cantidad > 0
      ), 0) <= p.cantidad_minima
      ORDER BY stock_total ASC, p.nombre ASC
    ''');
    return maps.map(Producto.fromMap).toList();
  }

  /// Eventos de calendario a nivel de lote: cada lote activo genera un punto.
  Future<Map<DateTime, List<Producto>>> getEventosCalendarioPorLote() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT
        p.id, p.nombre, p.categoria, p.unidad, p.cantidad_minima,
        p.imagen_path, p.ultima_tienda_id, p.created_at, p.updated_at,
        t.nombre AS ultima_tienda_nombre,
        l.cantidad AS stock_total,
        1 AS lotes_activos,
        l.fecha_vencimiento AS proxima_caducidad
      FROM lotes l
      INNER JOIN productos p ON p.id = l.producto_id
      LEFT JOIN tiendas t ON t.id = p.ultima_tienda_id
      WHERE l.cantidad > 0 AND l.fecha_vencimiento IS NOT NULL
      ORDER BY l.fecha_vencimiento ASC
    ''');

    final Map<DateTime, List<Producto>> mapa = {};
    for (final row in rows) {
      final p = Producto.fromMap(row);
      if (p.fechaVencimiento == null) continue;
      final clave = DateTime(
        p.fechaVencimiento!.year,
        p.fechaVencimiento!.month,
        p.fechaVencimiento!.day,
      );
      mapa[clave] ??= [];
      mapa[clave]!.add(p);
    }
    return mapa;
  }

  /// Inserta producto y, si hay cantidad/caducidad, crea el lote inicial.
  Future<int> insertProducto(Producto producto, {Lote? loteInicial}) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final id = await txn.insert('productos', producto.toMap());
      final cantidadLote = loteInicial?.cantidad ?? producto.cantidad;
      final fechaLote =
          loteInicial?.fechaVencimiento ?? producto.fechaVencimiento;

      if (cantidadLote > 0) {
        final now = DateTime.now().toIso8601String();
        await txn.insert('lotes', {
          'producto_id': id,
          'cantidad': cantidadLote,
          'fecha_vencimiento':
              fechaLote?.toIso8601String().substring(0, 10),
          'created_at': now,
          'updated_at': now,
        });
      }
      return id;
    });
  }

  Future<int> updateProducto(Producto producto) async {
    final db = await _db.database;
    return db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> deleteProducto(int id) async {
    final db = await _db.database;
    return db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }
}
