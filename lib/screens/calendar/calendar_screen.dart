import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
//import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/auth_services.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _eventService.getUserEvents(userId).listen((events) {
        setState(() {
          _events = {};
          for (var event in events) {
            final date = DateTime(
              event.startTime.year,
              event.startTime.month,
              event.startTime.day,
            );
            if (_events[date] == null) _events[date] = [];
            _events[date]!.add(event);
          }
        });
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
              
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                final event = _getEventsForDay(_selectedDay!)[index];
                return ListTile(
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}\nCost: \$${event.cost.toStringAsFixed(2)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await _eventService.deleteEvent(event.id);
                    },
                  ),
                  onTap: () {
                    // Navigate to event details
                    Navigator.pushNamed(
                      context,
                      '/event-details',
                      arguments: event,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create event screen
          Navigator.pushNamed(context, '/event-form', arguments: null);

        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 