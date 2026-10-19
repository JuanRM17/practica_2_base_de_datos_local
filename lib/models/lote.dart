/// Lote de un producto con su propia cantidad y fecha de caducidad.
class Lote {
  final int? id;
  final int productoId;
  final double cantidad;
  final DateTime? fechaVencimiento;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Lote({
    this.id,
    required this.productoId,
    required this.cantidad,
    this.fechaVencimiento,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get estaActivo => cantidad > 0;

  bool get estaVencido =>
      fechaVencimiento != null &&
      fechaVencimiento!.isBefore(DateTime.now());

  factory Lote.fromMap(Map<String, dynamic> map) {
    return Lote(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int,
      cantidad: (map['cantidad'] as num).toDouble(),
      fechaVencimiento: map['fecha_vencimiento'] != null
          ? DateTime.parse(map['fecha_vencimiento'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'producto_id': productoId,
      'cantidad': cantidad,
      'fecha_vencimiento':
          fechaVencimiento?.toIso8601String().substring(0, 10),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Lote copyWith({
    int? id,
    int? productoId,
    double? cantidad,
    DateTime? fechaVencimiento,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lote(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
