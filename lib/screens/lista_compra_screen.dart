import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_lista_compra.dart';
import '../providers/lista_compra_provider.dart';
import '../utils/categorias.dart';

/// Pantalla de la lista / carrito de compra generada por el usuario.
class ListaCompraScreen extends StatelessWidget {
  const ListaCompraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        title: const Text('Lista de compra'),
        actions: [
          Consumer<ListaCompraProvider>(
            builder: (_, cart, __) {
              if (cart.items.every((i) => !i.comprado)) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Quitar comprados',
                onPressed: () => cart.limpiarComprados(),
                icon: const Icon(Icons.cleaning_services_outlined),
              );
            },
          ),
        ],
      ),
      body: Consumer<ListaCompraProvider>(
        builder: (context, cart, _) {
          if (cart.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
            );
          }

          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 72,
                      color: const Color(0xFF2D6A4F).withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu lista está vacía',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Desde el inventario, toca el ícono del carrito en cada artículo para armar tu lista.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: cart.items.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${cart.totalPendientes} pendientes · ${cart.totalItems} en total',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              final item = cart.items[i - 1];
              return _ListaItemTile(
                item: item,
                onToggle: () => cart.toggleComprado(item),
                onDelete: () => cart.eliminar(item),
              );
            },
          );
        },
      ),
    );
  }
}

class _ListaItemTile extends StatelessWidget {
  final ItemListaCompra item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ListaItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = categoriaPorNombre(item.categoria);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(
          value: item.comprado,
          activeColor: const Color(0xFF2D6A4F),
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          item.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: item.comprado ? TextDecoration.lineThrough : null,
            color: item.comprado
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF1A1A2E),
          ),
        ),
        subtitle: Text(
          '${item.categoria} · ${item.cantidad} ${item.unidad}',
          style: TextStyle(
            fontSize: 12,
            color: cat.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Quitar de la lista',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Color(0xFFD62828)),
        ),
      ),
    );
  }
}
