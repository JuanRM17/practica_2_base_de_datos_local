import '../database/articulos_db.dart';
import '../models/item_lista_compra.dart';
import '../models/producto.dart';

/// Repositorio de la lista / carrito de compra.
class ListaCompraRepo {
  final ArticulosDB _db = ArticulosDB();

  Future<List<ItemListaCompra>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'lista_compra',
      orderBy: 'comprado ASC, created_at DESC',
    );
    return maps.map(ItemListaCompra.fromMap).toList();
  }

  /// Agrega un producto al carrito. Si ya existe (mismo producto_id y no
  /// comprado), incrementa la cantidad sugerida a reponer.
  Future<int> agregarProducto(Producto producto, {double? cantidad}) async {
    final db = await _db.database;
    final sugerida = cantidad ??
        (producto.cantidadMinima > producto.cantidad
            ? producto.cantidadMinima - producto.cantidad
            : 1.0);

    if (producto.id != null) {
      final existentes = await db.query(
        'lista_compra',
        where: 'producto_id = ? AND comprado = 0',
        whereArgs: [producto.id],
        limit: 1,
      );
      if (existentes.isNotEmpty) {
        final item = ItemListaCompra.fromMap(existentes.first);
        return db.update(
          'lista_compra',
          {'cantidad': item.cantidad + sugerida},
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    }

    final item = ItemListaCompra(
      productoId: producto.id,
      nombre: producto.nombre,
      categoria: producto.categoria,
      cantidad: sugerida <= 0 ? 1.0 : sugerida,
      unidad: producto.unidad,
      createdAt: DateTime.now(),
    );
    return db.insert('lista_compra', item.toMap());
  }

  Future<int> toggleComprado(ItemListaCompra item) async {
    final db = await _db.database;
    return db.update(
      'lista_compra',
      {'comprado': item.comprado ? 0 : 1},
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> eliminar(int id) async {
    final db = await _db.database;
    return db.delete('lista_compra', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> limpiarComprados() async {
    final db = await _db.database;
    return db.delete('lista_compra', where: 'comprado = 1');
  }

  Future<bool> estaEnLista(int productoId) async {
    final db = await _db.database;
    final maps = await db.query(
      'lista_compra',
      where: 'producto_id = ? AND comprado = 0',
      whereArgs: [productoId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
