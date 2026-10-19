import '../database/articulos_db.dart';
import '../models/historial_compra.dart';
import '../models/lote.dart';

/// Repositorio de Historial_Compras con actualización de ultima_tienda_id.
class HistorialCompraRepo {
  final ArticulosDB _db = ArticulosDB();

  Future<List<HistorialCompra>> getAll() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT h.*,
             p.nombre AS producto_nombre,
             t.nombre AS tienda_nombre
      FROM historial_compras h
      INNER JOIN productos p ON p.id = h.producto_id
      INNER JOIN tiendas t ON t.id = h.tienda_id
      ORDER BY h.fecha_compra DESC, h.id DESC
    ''');
    return maps.map(HistorialCompra.fromMap).toList();
  }

  Future<List<HistorialCompra>> getByProducto(int productoId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT h.*,
             p.nombre AS producto_nombre,
             t.nombre AS tienda_nombre
      FROM historial_compras h
      INNER JOIN productos p ON p.id = h.producto_id
      INNER JOIN tiendas t ON t.id = h.tienda_id
      WHERE h.producto_id = ?
      ORDER BY h.fecha_compra DESC, h.id DESC
    ''', [productoId]);
    return maps.map(HistorialCompra.fromMap).toList();
  }

  /// Registra una compra:
  /// 1) Crea un lote con la cantidad y caducidad.
  /// 2) Inserta en Historial_Compras vinculando producto y tienda.
  /// 3) Actualiza productos.ultima_tienda_id.
  Future<int> registrarCompra({
    required int productoId,
    required int tiendaId,
    required double cantidad,
    DateTime? fechaVencimiento,
    double? precio,
    String? notas,
    DateTime? fechaCompra,
  }) async {
    if (cantidad <= 0) {
      throw ArgumentError('La cantidad de compra debe ser mayor a 0');
    }

    final db = await _db.database;
    final now = DateTime.now();
    final fecha = fechaCompra ?? now;

    return db.transaction((txn) async {
      final lote = Lote(
        productoId: productoId,
        cantidad: cantidad,
        fechaVencimiento: fechaVencimiento,
        createdAt: now,
        updatedAt: now,
      );
      final loteId = await txn.insert('lotes', lote.toMap());

      final historial = HistorialCompra(
        productoId: productoId,
        tiendaId: tiendaId,
        loteId: loteId,
        cantidad: cantidad,
        precio: precio,
        fechaCompra: fecha,
        notas: notas,
        createdAt: now,
      );
      final historialId = await txn.insert('historial_compras', historial.toMap());

      // Regla de negocio: actualizar última tienda del producto
      await txn.update(
        'productos',
        {
          'ultima_tienda_id': tiendaId,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productoId],
      );

      return historialId;
    });
  }
}
