import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lista_compra_provider.dart';
import '../providers/producto_provider.dart';
import 'calendario_screen.dart';
import 'home_screen.dart';
import 'inventario_screen.dart';

/// Pantalla raíz con barra de navegación inferior.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    InventarioScreen(),
    HomeScreen(),
    CalendarioScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productos = context.read<ProductoProvider>();
      final carrito = context.read<ListaCompraProvider>();
      productos.cargarInventario();
      productos.cargarAlertas();
      productos.cargarEventosCalendario();
      carrito.cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2D6A4F).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF2D6A4F)),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon:
                Icon(Icons.notifications, color: Color(0xFF2D6A4F)),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon:
                Icon(Icons.calendar_month, color: Color(0xFF2D6A4F)),
            label: 'Calendario',
          ),
        ],
      ),
    );
  }
}
