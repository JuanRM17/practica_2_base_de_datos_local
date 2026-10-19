import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/producto_provider.dart';
import '../utils/categorias.dart';

/// Formulario para registrar un nuevo artículo en el inventario.
class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _minimaCtrl = TextEditingController(text: '1');

  String _categoria = kCategorias.first.nombre;
  String _unidad = kUnidades.first;
  DateTime? _fechaVencimiento;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    _minimaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final producto = Producto(
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoria,
      cantidad: double.parse(_cantidadCtrl.text.replaceAll(',', '.')),
      unidad: _unidad,
      cantidadMinima: double.parse(_minimaCtrl.text.replaceAll(',', '.')),
      fechaVencimiento: _fechaVencimiento,
      createdAt: now,
      updatedAt: now,
    );

    final ok =
        await context.read<ProductoProvider>().registrarProducto(producto);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${producto.nombre}" registrado'),
          backgroundColor: const Color(0xFF2D6A4F),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      final error = context.read<ProductoProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al guardar'),
          backgroundColor: const Color(0xFFD62828),
        ),
      );
    }
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? ahora.add(const Duration(days: 7)),
      firstDate: ahora.subtract(const Duration(days: 30)),
      lastDate: ahora.add(const Duration(days: 365 * 5)),
      locale: const Locale('es', 'MX'),
      helpText: 'Fecha de vencimiento',
    );
    if (seleccion != null) {
      setState(() => _fechaVencimiento = seleccion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<ProductoProvider>().isSaving;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        title: const Text('Nuevo artículo'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _sectionCard(
              title: 'Categoría',
              subtitle: 'Selecciona a qué grupo pertenece',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCategorias.map((c) {
                  final selected = _categoria == c.nombre;
                  return ChoiceChip(
                    avatar: Icon(
                      c.icon,
                      size: 16,
                      color: selected ? Colors.white : c.color,
                    ),
                    label: Text(c.nombre),
                    selected: selected,
                    selectedColor: c.color,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor: c.color.withOpacity(0.1),
                    onSelected: (_) => setState(() => _categoria = c.nombre),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Datos del artículo',
              subtitle:
                  'La cantidad y caducidad forman el lote inicial (FEFO)',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      hintText: 'Ej. Leche Entera',
                      prefixIcon: Icon(Icons.label_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cantidadCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Cantidad del lote *',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validarNumero,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _unidad,
                          decoration: const InputDecoration(
                            labelText: 'Unidad',
                            border: OutlineInputBorder(),
                          ),
                          items: kUnidades
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _unidad = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _minimaCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad mínima *',
                      helperText: 'Alerta cuando el stock baje de este valor',
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarNumero,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _elegirFecha,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de vencimiento (opcional)',
                        prefixIcon: const Icon(Icons.event_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: _fechaVencimiento != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => _fechaVencimiento = null),
                              )
                            : const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _fechaVencimiento == null
                            ? 'Sin fecha'
                            : DateFormat("d 'de' MMMM 'de' y", 'es_MX')
                                .format(_fechaVencimiento!),
                        style: TextStyle(
                          color: _fechaVencimiento == null
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: isSaving ? null : _guardar,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Guardando...' : 'Guardar artículo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validarNumero(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null || n < 0) return 'Número inválido';
    return null;
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
