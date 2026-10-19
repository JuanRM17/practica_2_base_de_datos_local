import '../database/articulos_db.dart';
import '../models/tienda.dart';

class TiendaRepo {
  final ArticulosDB _db = ArticulosDB();

  Future<List<Tienda>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('tiendas', orderBy: 'nombre ASC');
    return maps.map(Tienda.fromMap).toList();
  }

  Future<Tienda?> getById(int id) async {
    final db = await _db.database;
    final maps =
        await db.query('tiendas', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Tienda.fromMap(maps.first);
  }

  Future<int> insert(Tienda tienda) async {
    final db = await _db.database;
    return db.insert('tiendas', tienda.toMap());
  }

  /// Todas las tiendas donde se ha comprado [productoId] (histórico global).
  Future<List<Tienda>> getTiendasDeProducto(int productoId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT t.*
      FROM tiendas t
      INNER JOIN historial_compras h ON h.tienda_id = t.id
      WHERE h.producto_id = ?
      ORDER BY t.nombre ASC
    ''', [productoId]);
    return maps.map(Tienda.fromMap).toList();
  }
}
