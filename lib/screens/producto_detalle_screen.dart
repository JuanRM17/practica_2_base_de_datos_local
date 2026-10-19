import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/historial_compra.dart';
import '../models/lote.dart';
import '../models/producto.dart';
import '../models/tienda.dart';
import '../providers/producto_provider.dart';
import '../utils/categorias.dart';
import '../widgets/producto_status.dart';

/// Detalle de producto: lotes, consumo FEFO, compras y tiendas.
class ProductoDetalleScreen extends StatefulWidget {
  final Producto producto;

  const ProductoDetalleScreen({super.key, required this.producto});

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  late Producto _producto;
  List<Lote> _lotes = [];
  List<Tienda> _tiendasHist = [];
  List<HistorialCompra> _historial = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _producto = widget.producto;
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final provider = context.read<ProductoProvider>();
    final id = _producto.id!;
    final actualizado = await provider.getProductoById(id);
    final lotes = await provider.lotesDeProducto(id);
    final tiendas = await provider.tiendasDeProducto(id);
    final historial = await provider.historialDeProducto(id);
    if (!mounted) return;
    setState(() {
      if (actualizado != null) _producto = actualizado;
      _lotes = lotes;
      _tiendasHist = tiendas;
      _historial = historial;
      _loading = false;
    });
  }

  Future<void> _consumir() async {
    final ctrl = TextEditingController(text: '1');
    final cantidad = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Consumir (FEFO)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se descontará primero del lote con caducidad más próxima.\n'
              'Stock disponible: ${_producto.cantidad} ${_producto.unidad}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad a consumir',
                suffixText: _producto.unidad,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final n = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (n != null && n > 0) Navigator.pop(ctx, n);
            },
            child: const Text('Descontar'),
          ),
        ],
      ),
    );
    if (cantidad == null || !mounted) return;

    final descontado = await context
        .read<ProductoProvider>()
        .consumirStock(_producto.id!, cantidad);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          descontado < cantidad
              ? 'Solo se pudieron descontar $descontado ${_producto.unidad} (FEFO)'
              : 'Descontados $descontado ${_producto.unidad} por FEFO',
        ),
        backgroundColor: const Color(0xFF2D6A4F),
      ),
    );
    await _cargar();
  }

  Future<void> _registrarCompra() async {
    final provider = context.read<ProductoProvider>();
    if (provider.tiendas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tiendas registradas')),
      );
      return;
    }

    int tiendaId = provider.tiendas.first.id!;
    final cantidadCtrl = TextEditingController(text: '1');
    DateTime? fechaVencimiento;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Registrar compra'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: tiendaId,
                    decoration: const InputDecoration(
                      labelText: 'Tienda *',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.tiendas
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.nombre),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => tiendaId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidadCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cantidad *',
                      suffixText: _producto.unidad,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      fechaVencimiento == null
                          ? 'Caducidad del lote (opcional)'
                          : DateFormat('d/MM/y').format(fechaVencimiento!),
                    ),
                    trailing: const Icon(Icons.event),
                    onTap: () async {
                      final sel = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 1)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 5)),
                        locale: const Locale('es', 'MX'),
                      );
                      if (sel != null) {
                        setLocal(() => fechaVencimiento = sel);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );

    if (ok != true || !mounted) return;
    final cantidad =
        double.tryParse(cantidadCtrl.text.replaceAll(',', '.')) ?? 0;
    if (cantidad <= 0) return;

    final success = await provider.registrarCompra(
      productoId: _producto.id!,
      tiendaId: tiendaId,
      cantidad: cantidad,
      fechaVencimiento: fechaVencimiento,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Compra registrada. Última tienda actualizada.'
            : (provider.error ?? 'Error')),
        backgroundColor:
            success ? const Color(0xFF2D6A4F) : const Color(0xFFD62828),
      ),
    );
    if (success) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final cat = categoriaPorNombre(_producto.categoria);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        title: Text(_producto.nombre),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _InfoHeader(
                    producto: _producto, color: cat.color, icon: cat.icon),
                const SizedBox(height: 12),
                ProductoStatusBadges(producto: _producto),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _producto.estaAgotado ? null : _consumir,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                        ),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Consumir FEFO'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _registrarCompra,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Compra'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('Lotes', Icons.layers_outlined),
                if (_lotes.isEmpty)
                  const _EmptyBox('Sin lotes asociados → producto agotado')
                else
                  ..._lotes.map(
                      (l) => _LoteTile(lote: l, unidad: _producto.unidad)),
                const SizedBox(height: 16),
                _sectionTitle('Última tienda', Icons.storefront_outlined),
                _CardText(
                  _producto.ultimaTiendaNombre ?? 'Sin compras registradas',
                ),
                const SizedBox(height: 16),
                _sectionTitle(
                    'Tiendas donde se ha comprado', Icons.history),
                if (_tiendasHist.isEmpty)
                  const _EmptyBox('Aún no hay historial de tiendas')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tiendasHist
                        .map((t) => Chip(
                              avatar: const Icon(Icons.store, size: 16),
                              label: Text(t.nombre),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 16),
                _sectionTitle('Historial de compras', Icons.receipt_long),
                if (_historial.isEmpty)
                  const _EmptyBox('Sin compras')
                else
                  ..._historial.map((h) => _HistorialTile(item: h)),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  final Producto producto;
  final Color color;
  final IconData icon;

  const _InfoHeader({
    required this.producto,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${producto.categoria} · Stock: ${producto.cantidad} ${producto.unidad}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                Text(
                  '${producto.totalLotesActivos} lote(s) activo(s)',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoteTile extends StatelessWidget {
  final Lote lote;
  final String unidad;

  const _LoteTile({required this.lote, required this.unidad});

  @override
  Widget build(BuildContext context) {
    final activo = lote.estaActivo;
    final fv = lote.fechaVencimiento == null
        ? 'Sin caducidad'
        : DateFormat("d 'de' MMM y", 'es_MX').format(lote.fechaVencimiento!);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            width: 4,
            color: !activo
                ? const Color(0xFF9CA3AF)
                : lote.estaVencido
                    ? const Color(0xFFD62828)
                    : const Color(0xFF2D6A4F),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lote #${lote.id}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(fv,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Text(
            '${lote.cantidad} $unidad',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: activo
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorialTile extends StatelessWidget {
  final HistorialCompra item;

  const _HistorialTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Color(0xFF2D6A4F), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.tiendaNombre ?? 'Tienda',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  DateFormat('d/MM/y').format(item.fechaCompra),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          Text(
            '${item.cantidad}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CardText extends StatelessWidget {
  final String text;
  const _CardText(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF9CA3AF))),
    );
  }
}
