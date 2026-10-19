import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/producto.dart';
import '../providers/producto_provider.dart';
import '../widgets/dia_detalle_modal.dart';

/// Pantalla de calendario: muestra puntos de color en los días con vencimientos.
/// Al tocar un día se abre un modal de pantalla completa con el detalle.
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Consumer<ProductoProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              // ── App Bar ─────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 100,
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
                          children: const [
                            Row(
                              children: [
                                Icon(Icons.calendar_month,
                                    color: Colors.white60, size: 18),
                                SizedBox(width: 6),
                                Text('Mi Alacena',
                                    style: TextStyle(
                                        color: Colors.white60, fontSize: 13)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Calendario de vencimientos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
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

              // ── Leyenda de colores ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: const [
                      _LegendDot(color: Color(0xFFD62828), label: 'Vencido'),
                      SizedBox(width: 16),
                      _LegendDot(color: Color(0xFFE76F51), label: '≤ 3 días'),
                      SizedBox(width: 16),
                      _LegendDot(color: Color(0xFFF4A261), label: '≤ 7 días'),
                    ],
                  ),
                ),
              ),

              // ── Calendario ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: provider.isLoadingCalendario
                        ? const SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF2D6A4F)),
                            ),
                          )
                        : TableCalendar<Producto>(
                            locale: 'es_MX',
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),

                            // ── Fuente de eventos ─────────────────────────
                            eventLoader: (day) {
                              final clave =
                                  DateTime(day.year, day.month, day.day);
                              return provider.eventosCalendario[clave] ?? [];
                            },

                            // ── Al tocar un día → abrir modal ─────────────
                            onDaySelected: (selected, focused) {
                              setState(() {
                                _selectedDay = selected;
                                _focusedDay = focused;
                              });
                              final productos =
                                  provider.eventosDelDia(selected);
                              _abrirModalDia(context, selected, productos);
                            },
                            onFormatChanged: (format) {
                              setState(() => _calendarFormat = format);
                            },
                            onPageChanged: (focused) {
                              _focusedDay = focused;
                            },

                            // ── Estilo del header ─────────────────────────
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: true,
                              titleCentered: true,
                              formatButtonShowsNext: false,
                              formatButtonDecoration: BoxDecoration(
                                color: Color(0xFFF2F4F7),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              titleTextStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),

                            // ── Estilo de los días ────────────────────────
                            calendarStyle: CalendarStyle(
                              outsideDaysVisible: false,
                              todayDecoration: BoxDecoration(
                                color:
                                    const Color(0xFF2D6A4F).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: const TextStyle(
                                color: Color(0xFF2D6A4F),
                                fontWeight: FontWeight.bold,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: Color(0xFF2D6A4F),
                                shape: BoxShape.circle,
                              ),
                              selectedTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              weekendTextStyle: const TextStyle(
                                  color: Color(0xFFE63946)),
                              markersMaxCount: 4,
                            ),

                            // ── Builder de marcadores (puntos de color) ───
                            calendarBuilders: CalendarBuilders<Producto>(
                              markerBuilder: (context, day, eventos) {
                                if (eventos.isEmpty) return null;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: eventos.take(4).map((p) {
                                      return Container(
                                        width: 5.5,
                                        height: 5.5,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: _colorPunto(p),
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),

              // ── Hint: toca un día para ver el detalle ────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_outlined,
                          size: 16,
                          color: const Color(0xFF9CA3AF).withOpacity(0.8)),
                      const SizedBox(width: 6),
                      const Text(
                        'Toca un día para ver los artículos que vencen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),
    );
  }

  /// Abre un modal que cubre toda la pantalla con los productos del día.
  void _abrirModalDia(
      BuildContext context, DateTime dia, List<Producto> productos) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) =>
            DiaDetalleModal(dia: dia, productos: productos),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  /// Asigna un color al punto según la urgencia del producto.
  Color _colorPunto(Producto p) {
    if (p.estaVencido) return const Color(0xFFD62828);
    if (p.proximoAVencer(diasUmbral: 3)) return const Color(0xFFE76F51);
    return const Color(0xFFF4A261);
  }
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }
}
