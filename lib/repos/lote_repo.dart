import '../database/articulos_db.dart';
import '../models/lote.dart';

/// Repositorio de lotes con descuento FEFO (First Expired, First Out).
class LoteRepo {
  final ArticulosDB _db = ArticulosDB();

  Future<List<Lote>> getLotesDeProducto(int productoId,
      {bool soloActivos = false}) async {
    final db = await _db.database;
    final maps = await db.query(
      'lotes',
      where: soloActivos
          ? 'producto_id = ? AND cantidad > 0'
          : 'producto_id = ?',
      whereArgs: [productoId],
      orderBy:
          'CASE WHEN fecha_vencimiento IS NULL THEN 1 ELSE 0 END, fecha_vencimiento ASC',
    );
    return maps.map(Lote.fromMap).toList();
  }

  Future<int> insertLote(Lote lote) async {
    final db = await _db.database;
    return db.insert('lotes', lote.toMap());
  }

  Future<double> stockTotal(int productoId) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(cantidad), 0) AS total
      FROM lotes
      WHERE producto_id = ? AND cantidad > 0
    ''', [productoId]);
    return (result.first['total'] as num).toDouble();
  }

  /// Descuenta [cantidad] del producto aplicando FEFO:
  /// primero los lotes con caducidad más próxima; los sin fecha al final.
  ///
  /// Retorna la cantidad efectivamente descontada.
  Future<double> descontarFefo(int productoId, double cantidad) async {
    if (cantidad <= 0) return 0;

    final db = await _db.database;
    return db.transaction((txn) async {
      final lotes = await txn.rawQuery('''
        SELECT * FROM lotes
        WHERE producto_id = ? AND cantidad > 0
        ORDER BY
          CASE WHEN fecha_vencimiento IS NULL THEN 1 ELSE 0 END,
          fecha_vencimiento ASC,
          id ASC
      ''', [productoId]);

      double restante = cantidad;
      double descontado = 0;
      final now = DateTime.now().toIso8601String();

      for (final row in lotes) {
        if (restante <= 0) break;

        final id = row['id'] as int;
        final disponible = (row['cantidad'] as num).toDouble();
        final tomar = restante < disponible ? restante : disponible;
        final nuevaCantidad = disponible - tomar;

        await txn.update(
          'lotes',
          {'cantidad': nuevaCantidad, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [id],
        );

        restante -= tomar;
        descontado += tomar;
      }

      return descontado;
    });
  }
}
