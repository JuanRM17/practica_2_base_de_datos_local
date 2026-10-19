import 'package:flutter/material.dart';
import '../models/item_lista_compra.dart';
import '../models/producto.dart';
import '../repos/lista_compra_repo.dart';

/// Provider de la lista / carrito de compra.
class ListaCompraProvider extends ChangeNotifier {
  final _repo = ListaCompraRepo();

  List<ItemListaCompra> _items = [];
  final Set<int> _productoIdsEnLista = {};
  bool _isLoading = false;
  String? _mensaje;

  List<ItemListaCompra> get items => _items;
  bool get isLoading => _isLoading;
  String? get mensaje => _mensaje;
  int get totalPendientes => _items.where((i) => !i.comprado).length;
  int get totalItems => _items.length;

  bool estaEnLista(int? productoId) {
    if (productoId == null) return false;
    return _productoIdsEnLista.contains(productoId);
  }

  Future<void> cargar() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repo.getAll();
      _productoIdsEnLista
        ..clear()
        ..addAll(
          _items
              .where((i) => !i.comprado && i.productoId != null)
              .map((i) => i.productoId!),
        );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> agregarProducto(Producto producto) async {
    try {
      await _repo.agregarProducto(producto);
      await cargar();
      _mensaje = '"${producto.nombre}" agregado a la lista';
      notifyListeners();
      return true;
    } catch (e) {
      _mensaje = 'No se pudo agregar: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleComprado(ItemListaCompra item) async {
    await _repo.toggleComprado(item);
    await cargar();
  }

  Future<void> eliminar(ItemListaCompra item) async {
    if (item.id == null) return;
    await _repo.eliminar(item.id!);
    await cargar();
  }

  Future<void> limpiarComprados() async {
    await _repo.limpiarComprados();
    await cargar();
  }

  void limpiarMensaje() {
    _mensaje = null;
  }
}
