import 'package:flutter/material.dart';
import '../models/historial_compra.dart';
import '../models/lote.dart';
import '../models/producto.dart';
import '../models/tienda.dart';
import '../repos/historial_compra_repo.dart';
import '../repos/lote_repo.dart';
import '../repos/producto_repo.dart';
import '../repos/tienda_repo.dart';

/// Provider del inventario: lotes FEFO, alertas, calendario y compras.
class ProductoProvider extends ChangeNotifier {
  final _repo = ProductoRepo();
  final _loteRepo = LoteRepo();
  final _tiendaRepo = TiendaRepo();
  final _historialRepo = HistorialCompraRepo();

  List<Producto> _productos = [];
  List<Producto> _proximosAVencer = [];
  List<Producto> _stockBajo = [];
  List<Tienda> _tiendas = [];
  Map<DateTime, List<Producto>> _eventosCalendario = {};

  bool _isLoading = false;
  bool _isLoadingInventario = false;
  bool _isLoadingCalendario = false;
  bool _isSaving = false;
  String? _error;

  List<Producto> get productos => _productos;
  List<Producto> get proximosAVencer => _proximosAVencer;
  List<Producto> get stockBajo => _stockBajo;
  List<Tienda> get tiendas => _tiendas;
  Map<DateTime, List<Producto>> get eventosCalendario => _eventosCalendario;
  bool get isLoading => _isLoading;
  bool get isLoadingInventario => _isLoadingInventario;
  bool get isLoadingCalendario => _isLoadingCalendario;
  bool get isSaving => _isSaving;
  String? get error => _error;
  int get totalAlertas => _proximosAVencer.length + _stockBajo.length;
  int get totalProductos => _productos.length;

  Future<void> cargarInventario() async {
    _isLoadingInventario = true;
    _error = null;
    notifyListeners();

    try {
      _productos = await _repo.getAllProductos();
      _tiendas = await _tiendaRepo.getAll();
    } catch (e) {
      _error = 'Error al cargar inventario: $e';
    } finally {
      _isLoadingInventario = false;
      notifyListeners();
    }
  }

  Future<void> cargarAlertas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _proximosAVencer = await _repo.getProductosProximosAVencer(dias: 7);
      _stockBajo = await _repo.getProductosStockBajo();
    } catch (e) {
      _error = 'Error al cargar alertas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarEventosCalendario() async {
    _isLoadingCalendario = true;
    notifyListeners();

    try {
      // Eventos a nivel de lote (un producto puede aparecer varios días)
      _eventosCalendario = await _repo.getEventosCalendarioPorLote();
    } catch (_) {
      // Silenciado: las alertas siguen funcionando
    } finally {
      _isLoadingCalendario = false;
      notifyListeners();
    }
  }

  Future<void> refrescarTodo() async {
    await Future.wait([
      cargarInventario(),
      cargarAlertas(),
      cargarEventosCalendario(),
    ]);
  }

  Future<bool> registrarProducto(Producto producto) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _repo.insertProducto(producto);
      await refrescarTodo();
      return true;
    } catch (e) {
      _error = 'No se pudo guardar el artículo: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Consume stock aplicando FEFO.
  Future<double> consumirStock(int productoId, double cantidad) async {
    final descontado = await _loteRepo.descontarFefo(productoId, cantidad);
    await refrescarTodo();
    return descontado;
  }

  Future<Producto?> getProductoById(int id) => _repo.getProductoById(id);

  Future<List<Lote>> lotesDeProducto(int productoId) {
    return _loteRepo.getLotesDeProducto(productoId);
  }

  /// Registra compra: crea lote, historial y actualiza ultima_tienda_id.
  Future<bool> registrarCompra({
    required int productoId,
    required int tiendaId,
    required double cantidad,
    DateTime? fechaVencimiento,
    double? precio,
    String? notas,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _historialRepo.registrarCompra(
        productoId: productoId,
        tiendaId: tiendaId,
        cantidad: cantidad,
        fechaVencimiento: fechaVencimiento,
        precio: precio,
        notas: notas,
      );
      await refrescarTodo();
      return true;
    } catch (e) {
      _error = 'No se pudo registrar la compra: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<List<Tienda>> tiendasDeProducto(int productoId) {
    return _tiendaRepo.getTiendasDeProducto(productoId);
  }

  Future<List<HistorialCompra>> historialDeProducto(int productoId) {
    return _historialRepo.getByProducto(productoId);
  }

  Future<int> crearTienda(String nombre, {String? direccion}) async {
    final id = await _tiendaRepo.insert(Tienda(
      nombre: nombre.trim(),
      direccion: direccion?.trim(),
      createdAt: DateTime.now(),
    ));
    _tiendas = await _tiendaRepo.getAll();
    notifyListeners();
    return id;
  }

  List<Producto> eventosDelDia(DateTime dia) {
    final clave = DateTime(dia.year, dia.month, dia.day);
    return _eventosCalendario[clave] ?? [];
  }
}
