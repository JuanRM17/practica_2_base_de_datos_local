import 'package:flutter/material.dart';

/// Barra de búsqueda sticky para usar dentro de [CustomScrollView].
/// Widget propio: [SliverPersistentHeader] reutilizable.
class SliverBusquedaBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SliverBusquedaBar({
    super.key,
    required this.controller,
    this.hintText = 'Buscar…',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _BusquedaHeaderDelegate(
        controller: controller,
        hintText: hintText,
        onChanged: onChanged,
        onClear: onClear,
      ),
    );
  }
}

class _BusquedaHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  _BusquedaHeaderDelegate({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
  });

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF2F4F7),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      alignment: Alignment.center,
      child: Material(
        elevation: overlapsContent ? 2 : 0,
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon:
                const Icon(Icons.search, color: Color(0xFF2D6A4F), size: 22),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                      onChanged?.call('');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _BusquedaHeaderDelegate oldDelegate) =>
      oldDelegate.controller.text != controller.text ||
      oldDelegate.hintText != hintText;
}
