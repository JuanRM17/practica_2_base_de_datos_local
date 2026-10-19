/// Registro de una compra vinculando producto y tienda.
class HistorialCompra {
  final int? id;
  final int productoId;
  final int tiendaId;
  final int? loteId;
  final double cantidad;
  final double? precio;
  final DateTime fechaCompra;
  final String? notas;
  final DateTime createdAt;

  /// Campos opcionales de join para mostrar en UI.
  final String? productoNombre;
  final String? tiendaNombre;

  const HistorialCompra({
    this.id,
    required this.productoId,
    required this.tiendaId,
    this.loteId,
    required this.cantidad,
    this.precio,
    required this.fechaCompra,
    this.notas,
    required this.createdAt,
    this.productoNombre,
    this.tiendaNombre,
  });

  factory HistorialCompra.fromMap(Map<String, dynamic> map) {
    return HistorialCompra(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int,
      tiendaId: map['tienda_id'] as int,
      loteId: map['lote_id'] as int?,
      cantidad: (map['cantidad'] as num).toDouble(),
      precio: map['precio'] != null ? (map['precio'] as num).toDouble() : null,
      fechaCompra: DateTime.parse(map['fecha_compra'] as String),
      notas: map['notas'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      productoNombre: map['producto_nombre'] as String?,
      tiendaNombre: map['tienda_nombre'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'producto_id': productoId,
      'tienda_id': tiendaId,
      'lote_id': loteId,
      'cantidad': cantidad,
      'precio': precio,
      'fecha_compra': fechaCompra.toIso8601String().substring(0, 10),
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
