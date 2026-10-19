import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import 'producto_status.dart';

/// Modal de pantalla completa que se muestra al tocar un día en el calendario.
/// Lista todos los artículos que vencen ese día con sus datos más relevantes.
class DiaDetalleModal extends StatelessWidget {
  final DateTime dia;
  final List<Producto> productos;

  const DiaDetalleModal({
    super.key,
    required this.dia,
    required this.productos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(dia: dia, totalProductos: productos.length),
          Expanded(
            child: productos.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: productos.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12, top: 4),
                          child: ProductoStatusLeyenda(),
                        );
                      }
                      return _ProductoDetalleCard(
                          producto: productos[i - 1]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DateTime dia;
  final int totalProductos;

  const _Header({required this.dia, required this.totalProductos});

  @override
  Widget build(BuildContext context) {
    final bool esHoy = _isSameDay(dia, DateTime.now());
    final String fechaLarga =
        DateFormat("EEEE, d 'de' MMMM", 'es_MX').format(dia);
    final String anio = DateFormat('y').format(dia);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (esHoy)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Hoy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      _capitalize(fechaLarga),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      anio,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            '$totalProductos ${totalProductos == 1 ? 'artículo' : 'artículos'} por vencer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Card de producto detallado ────────────────────────────────────────────────

class _ProductoDetalleCard extends StatelessWidget {
  final Producto producto;

  const _ProductoDetalleCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    final statusColor = ProductoStatusHelper.colorPrimario(producto);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                ),
                child: SizedBox(
                  width: 90,
                  height: 90,
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(_categoryIcon,
                              size: 13, color: _categoryColor),
                          const SizedBox(width: 4),
                          Text(
                            producto.categoria,
                            style: TextStyle(
                              fontSize: 12,
                              color: _categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ProductoStatusBadges(
                        producto: producto,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF2F4F7)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                if (producto.fechaVencimiento != null)
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    iconColor: _expiryColor,
                    label: 'Fecha de vencimiento',
                    value: DateFormat("d 'de' MMMM 'de' y", 'es_MX')
                        .format(producto.fechaVencimiento!),
                  ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF3A86FF),
                  label: 'Existencias actuales',
                  value:
                      '${producto.cantidad} ${producto.unidad}  (mín. ${producto.cantidadMinima} ${producto.unidad})',
                ),
                const SizedBox(height: 10),
                _StockBar(producto: producto),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (producto.imagenPath != null) {
      return Image.file(
        File(producto.imagenPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: _categoryColor.withOpacity(0.12),
      child: Center(
        child: Icon(_categoryIcon, color: _categoryColor, size: 38),
      ),
    );
  }

  Color get _expiryColor {
    if (producto.estaVencido) return const Color(0xFFD62828);
    if (producto.proximoAVencer(diasUmbral: 3)) return const Color(0xFFE76F51);
    return const Color(0xFFF4A261);
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
      default:
        return Icons.inventory_2_outlined;
    }
  }
}

// ── Fila de detalle (ícono + label + valor) ───────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Barra de nivel de stock ───────────────────────────────────────────────────

class _StockBar extends StatelessWidget {
  final Producto producto;
  const _StockBar({required this.producto});

  @override
  Widget build(BuildContext context) {
    final double ratio = producto.cantidadMinima > 0
        ? (producto.cantidad / producto.cantidadMinima).clamp(0.0, 1.0)
        : 0.0;

    Color barColor;
    String estadoLabel;
    if (producto.estaAgotado) {
      barColor = const Color(0xFFD62828);
      estadoLabel = 'Agotado';
    } else if (producto.stockBajo) {
      barColor = const Color(0xFFFFB703);
      estadoLabel = 'Stock bajo';
    } else {
      barColor = const Color(0xFF2DC653);
      estadoLabel = 'Suficiente';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nivel de stock',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              estadoLabel,
              style: TextStyle(
                fontSize: 11,
                color: barColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: barColor.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(ratio * 100).toStringAsFixed(0)}% del mínimo requerido',
          style: const TextStyle(fontSize: 10, color: Color(0xFFBCC0C8)),
        ),
      ],
    );
  }
}

// ── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available,
              size: 60,
              color: const Color(0xFF2D6A4F).withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin vencimientos este día',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No hay artículos programados para vencer',
            style: TextStyle(fontSize: 13, color: Color(0xFFBCC0C8)),
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
