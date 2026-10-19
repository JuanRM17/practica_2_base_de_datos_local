import 'dart:io';
import 'package:flutter/material.dart';
import '../models/producto.dart';
import 'producto_status.dart';

/// Card reutilizable que muestra un producto en las listas de alertas.
/// Incluye identificación visual rápida del estatus (color, icono y etiqueta).
class AlertaCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool enLista;

  const AlertaCard({
    super.key,
    required this.producto,
    this.onTap,
    this.onAddToCart,
    this.enLista = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = ProductoStatusHelper.colorPrimario(producto);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(color: statusColor, width: 5),
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(18),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                height: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: ProductoStatusIconBadge(
                        producto: producto,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      _CategoryChip(
                        label: producto.categoria,
                        color: _categoryColor,
                      ),
                      const SizedBox(height: 8),
                      ProductoStatusBadges(
                        producto: producto,
                        compact: true,
                      ),
                      const SizedBox(height: 6),
                      _QuantityRow(producto: producto),
                    ],
                  ),
                ),
              ),
              if (onAddToCart != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Material(
                    color: enLista
                        ? const Color(0xFF2D6A4F).withOpacity(0.12)
                        : const Color(0xFF2D6A4F),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onAddToCart,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          enLista
                              ? Icons.add_shopping_cart
                              : Icons.shopping_cart_outlined,
                          color: enLista
                              ? const Color(0xFF2D6A4F)
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (producto.imagenPath != null) {
      return Image.file(
        File(producto.imagenPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      color: _categoryColor.withOpacity(0.12),
      child: Center(
        child: Icon(_categoryIcon, color: _categoryColor, size: 36),
      ),
    );
  }

  Color get _categoryColor {
    switch (producto.categoria.toLowerCase()) {
      case 'lácteos':
        return const Color(0xFF3A86FF);
      case 'panadería':
        return const Color(0xFFE07A5F);
      case 'frutas':
        return const Color(0xFF2DC653);
      case 'verduras':
        return const Color(0xFF43AA8B);
      case 'carnes':
        return const Color(0xFFE63946);
      case 'bebidas':
        return const Color(0xFF6C5CE7);
      case 'aceites':
        return const Color(0xFFE9C46A);
      case 'limpieza':
        return const Color(0xFF00B4D8);
      case 'cereales':
        return const Color(0xFFD4A373);
      case 'huevos':
        return const Color(0xFFF4A261);
      case 'congelados':
        return const Color(0xFF90E0EF);
      default:
        return const Color(0xFF8D99AE);
    }
  }

  IconData get _categoryIcon {
    switch (producto.categoria.toLowerCase()) {
      case 'lácteos':
        return Icons.water_drop_outlined;
      case 'panadería':
        return Icons.bakery_dining;
      case 'frutas':
        return Icons.apple;
      case 'verduras':
        return Icons.eco;
      case 'carnes':
        return Icons.set_meal;
      case 'bebidas':
        return Icons.local_drink_outlined;
      case 'aceites':
        return Icons.opacity;
      case 'limpieza':
        return Icons.cleaning_services_outlined;
      case 'cereales':
        return Icons.breakfast_dining;
      case 'huevos':
        return Icons.egg_outlined;
      case 'congelados':
        return Icons.ac_unit;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _QuantityRow extends StatelessWidget {
  final Producto producto;
  const _QuantityRow({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.inventory_2_outlined,
            size: 12, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${producto.cantidad} ${producto.unidad}  ·  Mín: ${producto.cantidadMinima} ${producto.unidad}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
