/// Modelo que representa un artículo del inventario doméstico.
///
/// [cantidad] y [fechaVencimiento] se calculan a partir de los lotes activos
/// (FEFO): stock total = suma de cantidades > 0; caducidad = la más próxima.
class Producto {
  final int? id;
  final String nombre;
  final String categoria;
  final double cantidad;
  final String unidad;
  final double cantidadMinima;
  final DateTime? fechaVencimiento;
  final String? imagenPath;
  final int? ultimaTiendaId;
  final String? ultimaTiendaNombre;
  final int totalLotesActivos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Producto({
    this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.unidad,
    required this.cantidadMinima,
    this.fechaVencimiento,
    this.imagenPath,
    this.ultimaTiendaId,
    this.ultimaTiendaNombre,
    this.totalLotesActivos = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Getters de estado ──────────────────────────────────────────────────────

  /// Agotado: stock total 0 o sin lotes activos asociados.
  bool get estaAgotado => cantidad <= 0 || totalLotesActivos == 0;

  /// El producto tiene stock pero está por debajo del mínimo.
  bool get stockBajo => !estaAgotado && cantidad <= cantidadMinima;

  /// El producto ya venció (lote activo con caducidad más próxima vencida).
  bool get estaVencido =>
      fechaVencimiento != null &&
      fechaVencimiento!.isBefore(DateTime.now());

  /// El producto vence en los próximos [diasUmbral] días.
  bool proximoAVencer({int diasUmbral = 7}) {
    if (fechaVencimiento == null || estaVencido) return false;
    return diasParaVencer <= diasUmbral;
  }

  /// Días que faltan para que venza (-1 si no tiene fecha).
  int get diasParaVencer {
    if (fechaVencimiento == null) return -1;
    return fechaVencimiento!.difference(DateTime.now()).inDays;
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  factory Producto.fromMap(Map<String, dynamic> map) {
    final stock = map['stock_total'] ?? map['cantidad'];
    final lotesActivos = map['lotes_activos'];
    final stockVal = stock == null ? 0.0 : (stock as num).toDouble();

    return Producto(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      categoria: map['categoria'] as String,
      cantidad: stockVal,
      unidad: map['unidad'] as String,
      cantidadMinima: (map['cantidad_minima'] as num).toDouble(),
      fechaVencimiento: map['fecha_vencimiento'] != null
          ? DateTime.parse(map['fecha_vencimiento'] as String)
          : (map['proxima_caducidad'] != null
              ? DateTime.parse(map['proxima_caducidad'] as String)
              : null),
      imagenPath: map['imagen_path'] as String?,
      ultimaTiendaId: map['ultima_tienda_id'] as int?,
      ultimaTiendaNombre: map['ultima_tienda_nombre'] as String?,
      totalLotesActivos: lotesActivos != null
          ? (lotesActivos as num).toInt()
          : (stockVal > 0 ? 1 : 0),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Mapa para insert/update de la fila producto (sin campos derivados de lotes).
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'unidad': unidad,
      'cantidad_minima': cantidadMinima,
      'imagen_path': imagenPath,
      'ultima_tienda_id': ultimaTiendaId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Producto copyWith({
    int? id,
    String? nombre,
    String? categoria,
    double? cantidad,
    String? unidad,
    double? cantidadMinima,
    DateTime? fechaVencimiento,
    String? imagenPath,
    int? ultimaTiendaId,
    String? ultimaTiendaNombre,
    int? totalLotesActivos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
      cantidadMinima: cantidadMinima ?? this.cantidadMinima,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      imagenPath: imagenPath ?? this.imagenPath,
      ultimaTiendaId: ultimaTiendaId ?? this.ultimaTiendaId,
      ultimaTiendaNombre: ultimaTiendaNombre ?? this.ultimaTiendaNombre,
      totalLotesActivos: totalLotesActivos ?? this.totalLotesActivos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
