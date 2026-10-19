import 'package:flutter/material.dart';
import '../models/producto.dart';

/// Estados visibles de un artículo para identificación rápida.
enum ProductoEstatus {
  caducado,
  sinExistencia,
  porCaducar,
  porAgotarse,
}

/// Estilo visual asociado a cada [ProductoEstatus].
class ProductoEstatusStyle {
  final ProductoEstatus estatus;
  final String label;
  final Color color;
  final IconData icon;

  const ProductoEstatusStyle({
    required this.estatus,
    required this.label,
    required this.color,
    required this.icon,
  });

  static const caducado = ProductoEstatusStyle(
    estatus: ProductoEstatus.caducado,
    label: 'Caducado',
    color: Color(0xFFD62828),
    icon: Icons.event_busy,
  );

  static const sinExistencia = ProductoEstatusStyle(
    estatus: ProductoEstatus.sinExistencia,
    label: 'Sin existencia',
    color: Color(0xFF6D2E8B),
    icon: Icons.remove_shopping_cart_outlined,
  );

  static const porCaducar = ProductoEstatusStyle(
    estatus: ProductoEstatus.porCaducar,
    label: 'Por caducar',
    color: Color(0xFFE76F51),
    icon: Icons.timer_outlined,
  );

  static const porAgotarse = ProductoEstatusStyle(
    estatus: ProductoEstatus.porAgotarse,
    label: 'Por agotarse',
    color: Color(0xFFE9A825),
    icon: Icons.trending_down,
  );

  static ProductoEstatusStyle of(ProductoEstatus e) {
    switch (e) {
      case ProductoEstatus.caducado:
        return caducado;
      case ProductoEstatus.sinExistencia:
        return sinExistencia;
      case ProductoEstatus.porCaducar:
        return porCaducar;
      case ProductoEstatus.porAgotarse:
        return porAgotarse;
    }
  }
}

/// Utilidades para resolver el/los estatus de un [Producto].
class ProductoStatusHelper {
  /// Todos los estatus activos (un artículo puede tener varios a la vez).
  static List<ProductoEstatus> estatusDe(Producto producto) {
    final list = <ProductoEstatus>[];

    if (producto.estaVencido) {
      list.add(ProductoEstatus.caducado);
    } else if (producto.proximoAVencer()) {
      list.add(ProductoEstatus.porCaducar);
    }

    if (producto.estaAgotado) {
      list.add(ProductoEstatus.sinExistencia);
    } else if (producto.stockBajo) {
      list.add(ProductoEstatus.porAgotarse);
    }

    return list;
  }

  /// El estatus más urgente para color de borde / acento.
  static ProductoEstatus? primario(Producto producto) {
    final todos = estatusDe(producto);
    if (todos.isEmpty) return null;
    // Orden de prioridad: caducado > sin existencia > por caducar > por agotarse
    const prioridad = [
      ProductoEstatus.caducado,
      ProductoEstatus.sinExistencia,
      ProductoEstatus.porCaducar,
      ProductoEstatus.porAgotarse,
    ];
    for (final e in prioridad) {
      if (todos.contains(e)) return e;
    }
    return todos.first;
  }

  static Color colorPrimario(Producto producto) {
    final e = primario(producto);
    return e == null
        ? const Color(0xFF2D6A4F)
        : ProductoEstatusStyle.of(e).color;
  }
}

/// Chip compacto: icono + etiqueta con color del estatus.
class ProductoStatusChip extends StatelessWidget {
  final ProductoEstatus estatus;
  final bool compact;

  const ProductoStatusChip({
    super.key,
    required this.estatus,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ProductoEstatusStyle.of(estatus);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.color.withOpacity(0.45), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 12 : 14, color: style.color),
          SizedBox(width: compact ? 4 : 5),
          Text(
            style.label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Muestra uno o varios chips según los estatus activos del producto.
class ProductoStatusBadges extends StatelessWidget {
  final Producto producto;
  final bool compact;
  final Axis direction;

  const ProductoStatusBadges({
    super.key,
    required this.producto,
    this.compact = false,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final estatus = ProductoStatusHelper.estatusDe(producto);
    if (estatus.isEmpty) {
      return const SizedBox.shrink();
    }

    final chips = estatus
        .map((e) => ProductoStatusChip(estatus: e, compact: compact))
        .toList();

    if (direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            chips[i],
          ],
        ],
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }
}

/// Círculo con icono del estatus primario (identificación muy rápida).
class ProductoStatusIconBadge extends StatelessWidget {
  final Producto producto;
  final double size;

  const ProductoStatusIconBadge({
    super.key,
    required this.producto,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final primario = ProductoStatusHelper.primario(producto);
    if (primario == null) return const SizedBox.shrink();

    final style = ProductoEstatusStyle.of(primario);
    return Tooltip(
      message: style.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: style.color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: style.color.withOpacity(0.5), width: 1.5),
        ),
        child: Icon(style.icon, size: size * 0.48, color: style.color),
      ),
    );
  }
}

/// Leyenda compacta de los 4 estatus (útil en pantallas de listado).
class ProductoStatusLeyenda extends StatelessWidget {
  const ProductoStatusLeyenda({super.key});

  static const _items = [
    ProductoEstatusStyle.caducado,
    ProductoEstatusStyle.sinExistencia,
    ProductoEstatusStyle.porCaducar,
    ProductoEstatusStyle.porAgotarse,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _items.map((s) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(s.icon, size: 14, color: s.color),
            const SizedBox(width: 4),
            Text(
              s.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: s.color,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
