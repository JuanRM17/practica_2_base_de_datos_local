/// Tienda donde se adquieren productos.
class Tienda {
  final int? id;
  final String nombre;
  final String? direccion;
  final DateTime createdAt;

  const Tienda({
    this.id,
    required this.nombre,
    this.direccion,
    required this.createdAt,
  });

  factory Tienda.fromMap(Map<String, dynamic> map) {
    return Tienda(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      direccion: map['direccion'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
