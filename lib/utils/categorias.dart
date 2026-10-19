
import 'package:flutter/material.dart';

/// Catálogo fijo de categorías disponibles al registrar un artículo.
class CategoriaInfo {
  final String nombre;
  final IconData icon;
  final Color color;

  const CategoriaInfo({
    required this.nombre,
    required this.icon,
    required this.color,
  });
}

const List<CategoriaInfo> kCategorias = [
  CategoriaInfo(
    nombre: 'Lácteos',
    icon: Icons.water_drop_outlined,
    color: Color(0xFF3A86FF),
  ),
  CategoriaInfo(
    nombre: 'Panadería',
    icon: Icons.bakery_dining,
    color: Color(0xFFE07A5F),
  ),
  CategoriaInfo(
    nombre: 'Frutas',
    icon: Icons.apple,
    color: Color(0xFF2DC653),
  ),
  CategoriaInfo(
    nombre: 'Verduras',
    icon: Icons.eco,
    color: Color(0xFF43AA8B),
  ),
  CategoriaInfo(
    nombre: 'Carnes',
    icon: Icons.set_meal,
    color: Color(0xFFE63946),
  ),
  CategoriaInfo(
    nombre: 'Bebidas',
    icon: Icons.local_drink_outlined,
    color: Color(0xFF6C5CE7),
  ),
  CategoriaInfo(
    nombre: 'Aceites',
    icon: Icons.opacity,
    color: Color(0xFFE9C46A),
  ),
  CategoriaInfo(
    nombre: 'Limpieza',
    icon: Icons.cleaning_services_outlined,
    color: Color(0xFF00B4D8),
  ),
  CategoriaInfo(
    nombre: 'Cereales',
    icon: Icons.breakfast_dining,
    color: Color(0xFFD4A373),
  ),
  CategoriaInfo(
    nombre: 'Huevos',
    icon: Icons.egg_outlined,
    color: Color(0xFFF4A261),
  ),
  CategoriaInfo(
    nombre: 'Congelados',
    icon: Icons.ac_unit,
    color: Color(0xFF90E0EF),
  ),
  CategoriaInfo(
    nombre: 'General',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFF8D99AE),
  ),
];

const List<String> kUnidades = [
  'piezas',
  'kg',
  'g',
  'L',
  'ml',
  'paquetes',
  'cajas',
];

CategoriaInfo categoriaPorNombre(String nombre) {
  return kCategorias.firstWhere(
    (c) => c.nombre.toLowerCase() == nombre.toLowerCase(),
    orElse: () => kCategorias.last,
  );
}
