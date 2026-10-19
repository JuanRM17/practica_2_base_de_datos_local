import 'package:flutter/material.dart';
import '../utils/categorias.dart';

/// Tarjeta de categoría para [SliverGrid]: muestra conteo y estado.
/// Widget propio adicional a los solicitados en la práctica.
class CategoriaStatTile extends StatelessWidget {
  final CategoriaInfo categoria;
  final int total;
  final int conAlerta;
  final VoidCallback? onTap;
  final bool selected;

  const CategoriaStatTile({
    super.key,
    required this.categoria,
    required this.total,
    this.conAlerta = 0,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? categoria.color
                  : categoria.color.withOpacity(0.15),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: categoria.color.withOpacity(selected ? 0.2 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: categoria.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(categoria.icon,
                          color: categoria.color, size: 20),
                    ),
                    const Spacer(),
                    if (conAlerta > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD62828).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$conAlerta',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD62828),
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  '$total',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: categoria.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  categoria.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
