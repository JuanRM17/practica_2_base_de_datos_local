import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/lista_compra_provider.dart';
import '../providers/producto_provider.dart';
import '../widgets/alerta_card.dart';
import '../widgets/producto_status.dart';
import 'lista_compra_screen.dart';

/// Pantalla principal: muestra un resumen de alertas del inventario.
/// Sección 1 → artículos próximos a caducar (≤ 7 días).
/// Sección 2 → artículos con stock bajo o agotado.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _agregarAlCarrito(Producto producto) async {
    final cart = context.read<ListaCompraProvider>();
    final ok = await cart.agregarProducto(producto);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '"${producto.nombre}" agregado a la lista de compra'
              : (cart.mensaje ?? 'No se pudo agregar'),
        ),
        backgroundColor:
            ok ? const Color(0xFF2D6A4F) : const Color(0xFFD62828),
        action: ok
            ? SnackBarAction(
                label: 'Ver lista',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ListaCompraScreen(),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Consumer2<ProductoProvider, ListaCompraProvider>(
        builder: (context, provider, carrito, _) {
          // ── Estado de carga ────────────────────────────────────────────────
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
            );
          }

          // ── Estado de error ────────────────────────────────────────────────
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Color(0xFFD62828)),
                  const SizedBox(height: 12),
                  Text(provider.error!,
                      style: const TextStyle(color: Color(0xFF6B7280))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.cargarAlertas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // ── App Bar expandible ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                floating: false,
                backgroundColor: const Color(0xFF1B4332),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.kitchen,
                                    color: Colors.white60, size: 18),
                                const SizedBox(width: 6),
                                const Text(
                                  'Mi Alacena',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 13),
                                ),
                                const Spacer(),
                                // Campana con badge de alertas
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.notifications_outlined,
                                        color: Colors.white, size: 26),
                                    if (provider.totalAlertas > 0)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE63946),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${provider.totalAlertas}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Alertas de inventario',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Chips de resumen ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      _SummaryChip(
                        icon: Icons.timer_outlined,
                        label: 'Por vencer',
                        count: provider.proximosAVencer.length,
                        color: const Color(0xFFE76F51),
                      ),
                      const SizedBox(width: 12),
                      _SummaryChip(
                        icon: Icons.production_quantity_limits,
                        label: 'Stock bajo',
                        count: provider.stockBajo.length,
                        color: const Color(0xFFFFB703),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Leyenda de estatus ──────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: ProductoStatusLeyenda(),
                ),
              ),

              // ── Sección: Próximos a caducar ─────────────────────────────
              if (provider.proximosAVencer.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Icons.timer_outlined,
                    title: 'Próximos a caducar',
                    subtitle: 'Vencen en los próximos 7 días',
                    color: const Color(0xFFE76F51),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = provider.proximosAVencer[i];
                      return AlertaCard(
                        producto: p,
                        enLista: carrito.estaEnLista(p.id),
                        onAddToCart: () => _agregarAlCarrito(p),
                      );
                    },
                    childCount: provider.proximosAVencer.length,
                  ),
                ),
              ],

              // ── Sección: Stock bajo / agotado ───────────────────────────
              if (provider.stockBajo.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Icons.production_quantity_limits,
                    title: 'Stock bajo o agotado',
                    subtitle: 'Artículos que necesitas reponer',
                    color: const Color(0xFFFFB703),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = provider.stockBajo[i];
                      return AlertaCard(
                        producto: p,
                        enLista: carrito.estaEnLista(p.id),
                        onAddToCart: () => _agregarAlCarrito(p),
                      );
                    },
                    childCount: provider.stockBajo.length,
                  ),
                ),
              ],

              // ── Estado vacío (sin alertas) ──────────────────────────────
              if (provider.proximosAVencer.isEmpty && provider.stockBajo.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6A4F).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: const Color(0xFF2D6A4F).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '¡Todo en orden!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No hay alertas activas por el momento',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
      // Botón para refrescar manualmente
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        tooltip: 'Actualizar alertas',
        onPressed: () => context.read<ProductoProvider>().cargarAlertas(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// ── Sub-widgets privados ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
