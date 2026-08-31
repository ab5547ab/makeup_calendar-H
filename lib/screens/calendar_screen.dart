import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../services/appointments_controller.dart';
import '../utils/hebrew_date_helper.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/hebrew_month_grid.dart';
import 'add_edit_appointment_screen.dart';
import 'settings_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_today.year, _today.month, _today.day);
    _focusedDay = _selectedDay;
    Future.microtask(() => context.read<AppointmentsController>().load());
  }

  void _goToPreviousMonth(HebrewMonthInfo info) {
    setState(() {
      _focusedDay = HebrewDateHelper.previousMonthAnchor(info);
    });
  }

  void _goToNextMonth(HebrewMonthInfo info) {
    setState(() {
      _focusedDay = HebrewDateHelper.nextMonthAnchor(info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppointmentsController>();

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final monthInfo = HebrewDateHelper.monthInfoFor(_focusedDay);
    final dayAppointments = controller.forDay(_selectedDay);

    // סטטיסטיקות מחושבות לפי כל ימי החודש העברי המוצג
    final monthDays = monthInfo.daysAsGregorian;
    final monthAppointments =
        monthDays.expand((d) => controller.forDay(d)).toList();
    final monthTotal = monthAppointments
        .where((a) => a.status != AppointmentStatus.cancelled)
        .fold(0.0, (sum, a) => sum + a.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('סטודיו לאיפור'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'הגדרות וסנכרון',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthSummaryBar(total: monthTotal, count: monthAppointments.length),
          Card(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: HebrewMonthGrid(
              monthInfo: monthInfo,
              selectedDay: _selectedDay,
              today: _today,
              daysWithAppointments: controller.daysWithAppointments,
              onDaySelected: (day) => setState(() => _selectedDay = day),
              onPreviousMonth: () => _goToPreviousMonth(monthInfo),
              onNextMonth: () => _goToNextMonth(monthInfo),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    HebrewDateHelper.fullHebrewDate(_selectedDay),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${dayAppointments.length} תורים',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: dayAppointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('אין תורים ביום זה',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 90),
                    itemCount: dayAppointments.length,
                    itemBuilder: (context, index) {
                      final appt = dayAppointments[index];
                      return AppointmentTile(
                        appointment: appt,
                        onTap: () => _openEditor(appointment: appt),
                        onDelete: () => controller.delete(appt.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('תור חדש'),
      ),
    );
  }

  void _openEditor({Appointment? appointment}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAppointmentScreen(
          initialDate: _selectedDay,
          existing: appointment,
        ),
      ),
    );
  }
}

class _MonthSummaryBar extends StatelessWidget {
  final double total;
  final int count;

  const _MonthSummaryBar({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(icon: Icons.event_note, label: 'תורים החודש', value: '$count'),
          Container(width: 1, height: 28, color: Colors.white24),
          _StatItem(
              icon: Icons.payments_outlined,
              label: 'הכנסה חודשית',
              value: '₪${total.toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
