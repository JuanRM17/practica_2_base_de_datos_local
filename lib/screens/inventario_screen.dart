import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/producto.dart';
import '../providers/lista_compra_provider.dart';
import '../providers/producto_provider.dart';
import '../utils/categorias.dart';
import '../widgets/sliver_busqueda_bar.dart';
import '../widgets/producto_status.dart';
import 'lista_compra_screen.dart';
import 'producto_detalle_screen.dart';
import 'producto_form_screen.dart';

enum _FiltroInventario { todos, porCaducar, stockBajo, agotados, vencidos }

enum _VistaInventario { lista, cuadricula }

/// Listado principal del inventario con acceso a registro y carrito.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _busquedaController = TextEditingController();
  String _consulta = '';
  String? _categoriaSeleccionada;
  _FiltroInventario _filtro = _FiltroInventario.todos;
  _VistaInventario _vista = _VistaInventario.lista;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _abrirFormulario(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProductoFormScreen()));
  }

  Future<void> _abrirListaCompra(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ListaCompraScreen()));
  }

  Future<void> _agregarAlCarrito(
    BuildContext context,
    Producto producto,
  ) async {
    final cart = context.read<ListaCompraProvider>();
    final ok = await cart.agregarProducto(producto);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '"${producto.nombre}" agregado a la lista de compra'
              : (cart.mensaje ?? 'No se pudo agregar'),
        ),
        backgroundColor: ok ? const Color(0xFF2D6A4F) : const Color(0xFFD62828),
        action: ok
            ? SnackBarAction(
                label: 'Ver lista',
                textColor: Colors.white,
                onPressed: () => _abrirListaCompra(context),
              )
            : null,
      ),
    );
  }

  List<Producto> _filtrarProductos(List<Producto> productos) {
    final consulta = _consulta.trim().toLowerCase();
    return productos.where((producto) {
      final coincideConsulta =
          consulta.isEmpty ||
          producto.nombre.toLowerCase().contains(consulta) ||
          producto.categoria.toLowerCase().contains(consulta) ||
          (producto.ultimaTiendaNombre?.toLowerCase().contains(consulta) ??
              false);
      final coincideCategoria =
          _categoriaSeleccionada == null ||
          producto.categoria.toLowerCase() ==
              _categoriaSeleccionada!.toLowerCase();
      final coincideFiltro = switch (_filtro) {
        _FiltroInventario.todos => true,
        _FiltroInventario.porCaducar => producto.proximoAVencer(),
        _FiltroInventario.stockBajo => producto.stockBajo,
        _FiltroInventario.agotados => producto.estaAgotado,
        _FiltroInventario.vencidos => producto.estaVencido,
      };
      return coincideConsulta && coincideCategoria && coincideFiltro;
    }).toList();
  }

  void _abrirDetalle(BuildContext context, Producto producto) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductoDetalleScreen(producto: producto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Consumer2<ProductoProvider, ListaCompraProvider>(
        builder: (context, productos, carrito, _) {
          final articulos = _filtrarProductos(productos.productos);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: const Color(0xFF1B4332),
                actions: [
                  IconButton(
                    tooltip: 'Lista de compra',
                    onPressed: () => _abrirListaCompra(context),
                    icon: badges.Badge(
                      position: badges.BadgePosition.topEnd(top: -6, end: -4),
                      showBadge: carrito.totalPendientes > 0,
                      badgeContent: Text(
                        '${carrito.totalPendientes}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Color(0xFFE63946),
                        padding: EdgeInsets.all(5),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
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
                            const Row(
                              children: [
                                Icon(
                                  Icons.kitchen,
                                  color: Colors.white60,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Mi Alacena',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Inventario',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${productos.totalProductos} artículos registrados',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: ProductoStatusLeyenda(),
                ),
              ),
              if (!productos.isLoadingInventario &&
                  productos.productos.isNotEmpty) ...[
                SliverBusquedaBar(
                  controller: _busquedaController,
                  hintText: 'Buscar artículo, categoría o tienda',
                  onChanged: (valor) => setState(() => _consulta = valor),
                  onClear: () => setState(() => _consulta = ''),
                ),
                SliverToBoxAdapter(
                  child: _FiltrosInventario(
                    categoriaSeleccionada: _categoriaSeleccionada,
                    filtro: _filtro,
                    vista: _vista,
                    totalVisible: articulos.length,
                    totalProductos: productos.totalProductos,
                    onCategoriaChanged: (categoria) {
                      setState(() => _categoriaSeleccionada = categoria);
                    },
                    onFiltroChanged: (filtro) {
                      setState(() => _filtro = filtro);
                    },
                    onVistaChanged: (vista) {
                      setState(() => _vista = vista);
                    },
                  ),
                ),
              ],
              if (productos.isLoadingInventario)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
                  ),
                )
              else if (productos.productos.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: const Color(0xFF2D6A4F).withOpacity(0.35),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sin artículos aún',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Toca + para registrar el primero',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (articulos.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 52,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay artículos que coincidan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _consulta = '';
                                _busquedaController.clear();
                                _categoriaSeleccionada = null;
                                _filtro = _FiltroInventario.todos;
                              });
                            },
                            child: const Text('Limpiar filtros'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_vista == _VistaInventario.cuadricula)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final producto = articulos[i];
                      return _InventarioGridCard(
                        producto: producto,
                        enLista: carrito.estaEnLista(producto.id),
                        onAddToCart: () => _agregarAlCarrito(context, producto),
                        onTap: () => _abrirDetalle(context, producto),
                      );
                    }, childCount: articulos.length),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisExtent: 236,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final p = articulos[i];
                    return _InventarioCard(
                      producto: p,
                      enLista: carrito.estaEnLista(p.id),
                      onAddToCart: () => _agregarAlCarrito(context, p),
                      onTap: () => _abrirDetalle(context, p),
                    );
                  }, childCount: articulos.length),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo artículo'),
      ),
    );
  }
}

class _FiltrosInventario extends StatelessWidget {
  final String? categoriaSeleccionada;
  final _FiltroInventario filtro;
  final _VistaInventario vista;
  final int totalVisible;
  final int totalProductos;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<_FiltroInventario> onFiltroChanged;
  final ValueChanged<_VistaInventario> onVistaChanged;

  const _FiltrosInventario({
    required this.categoriaSeleccionada,
    required this.filtro,
    required this.vista,
    required this.totalVisible,
    required this.totalProductos,
    required this.onCategoriaChanged,
    required this.onFiltroChanged,
    required this.onVistaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categorias = [
      'Todas',
      ...kCategorias.map((categoria) => categoria.nombre),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 0,
            children: categorias.map((categoria) {
              final seleccionada = categoria == 'Todas'
                  ? categoriaSeleccionada == null
                  : categoriaSeleccionada == categoria;
              return FilterChip(
                label: Text(categoria),
                selected: seleccionada,
                onSelected: (_) =>
                    onCategoriaChanged(categoria == 'Todas' ? null : categoria),
                selectedColor: const Color(0xFF2D6A4F).withOpacity(0.15),
                checkmarkColor: const Color(0xFF2D6A4F),
                labelStyle: TextStyle(
                  color: seleccionada
                      ? const Color(0xFF1B4332)
                      : const Color(0xFF4B5563),
                  fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 7,
            children: _FiltroInventario.values.map((opcion) {
              return FilterChip(
                label: Text(_etiquetaFiltro(opcion)),
                selected: filtro == opcion,
                onSelected: (_) => onFiltroChanged(opcion),
                selectedColor: const Color(0xFFE9A825).withOpacity(0.18),
                checkmarkColor: const Color(0xFF9A6700),
                labelStyle: TextStyle(
                  color: filtro == opcion
                      ? const Color(0xFF7A5200)
                      : const Color(0xFF4B5563),
                  fontWeight: filtro == opcion
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 12,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  totalVisible == totalProductos
                      ? '$totalVisible artículos'
                      : '$totalVisible de $totalProductos artículos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SegmentedButton<_VistaInventario>(
                segments: const [
                  ButtonSegment(
                    value: _VistaInventario.lista,
                    icon: Icon(Icons.view_agenda_outlined),
                    label: Text('Lista'),
                  ),
                  ButtonSegment(
                    value: _VistaInventario.cuadricula,
                    icon: Icon(Icons.grid_view_outlined),
                    label: Text('Cuadrícula'),
                  ),
                ],
                selected: {vista},
                onSelectionChanged: (seleccion) =>
                    onVistaChanged(seleccion.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _etiquetaFiltro(_FiltroInventario opcion) {
    return switch (opcion) {
      _FiltroInventario.todos => 'Todos',
      _FiltroInventario.porCaducar => 'Por caducar',
      _FiltroInventario.stockBajo => 'Stock bajo',
      _FiltroInventario.agotados => 'Agotados',
      _FiltroInventario.vencidos => 'Vencidos',
    };
  }
}

class _InventarioCard extends StatelessWidget {
  final Producto producto;
  final bool enLista;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _InventarioCard({
    required this.producto,
    required this.enLista,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = categoriaPorNombre(producto.categoria);
    final statusColor = ProductoStatusHelper.colorPrimario(producto);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: statusColor, width: 5)),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icon, color: cat.color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      '${producto.categoria} · ${producto.cantidad} ${producto.unidad}'
                      '${producto.totalLotesActivos > 0 ? ' · ${producto.totalLotesActivos} lote(s)' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    if (producto.ultimaTiendaNombre != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Última: ${producto.ultimaTiendaNombre}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2D6A4F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ProductoStatusBadges(producto: producto, compact: true),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: enLista
                    ? 'Ya está en la lista (sumar otra vez)'
                    : 'Agregar a la lista de compra',
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
                        color: enLista ? const Color(0xFF2D6A4F) : Colors.white,
                        size: 22,
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
}

class _InventarioGridCard extends StatelessWidget {
  final Producto producto;
  final bool enLista;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _InventarioGridCard({
    required this.producto,
    required this.enLista,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoria = categoriaPorNombre(producto.categoria);
    final statusColor = ProductoStatusHelper.colorPrimario(producto);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border(
              top: BorderSide(color: statusColor, width: 4),
              left: BorderSide(color: statusColor.withOpacity(0.12)),
              right: BorderSide(color: statusColor.withOpacity(0.12)),
              bottom: BorderSide(color: statusColor.withOpacity(0.12)),
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: categoria.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoria.icon,
                      color: categoria.color,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: enLista
                        ? 'Ya está en la lista (sumar otra vez)'
                        : 'Agregar a la lista de compra',
                    onPressed: onAddToCart,
                    icon: Icon(
                      enLista
                          ? Icons.add_shopping_cart
                          : Icons.shopping_cart_outlined,
                      color: const Color(0xFF2D6A4F),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${producto.cantidad} ${producto.unidad}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const Spacer(),
              ProductoStatusBadges(producto: producto, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
