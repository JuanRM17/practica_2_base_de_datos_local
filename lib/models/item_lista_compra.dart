/// Elemento de la lista / carrito de compra.
class ItemListaCompra {
  final int? id;
  final int? productoId;
  final String nombre;
  final String categoria;
  final double cantidad;
  final String unidad;
  final bool comprado;
  final DateTime createdAt;

  const ItemListaCompra({
    this.id,
    this.productoId,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.unidad,
    this.comprado = false,
    required this.createdAt,
  });

  factory ItemListaCompra.fromMap(Map<String, dynamic> map) {
    return ItemListaCompra(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int?,
      nombre: map['nombre'] as String,
      categoria: map['categoria'] as String? ?? 'General',
      cantidad: (map['cantidad'] as num).toDouble(),
      unidad: map['unidad'] as String? ?? 'piezas',
      comprado: (map['comprado'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'producto_id': productoId,
      'nombre': nombre,
      'categoria': categoria,
      'cantidad': cantidad,
      'unidad': unidad,
      'comprado': comprado ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ItemListaCompra copyWith({
    int? id,
    int? productoId,
    String? nombre,
    String? categoria,
    double? cantidad,
    String? unidad,
    bool? comprado,
    DateTime? createdAt,
  }) {
    return ItemListaCompra(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
      comprado: comprado ?? this.comprado,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
