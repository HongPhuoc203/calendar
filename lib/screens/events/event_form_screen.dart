import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/auth_services.dart';
import '../../services/notification_services.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _eventService = EventService();
  final _authService = AuthService();
  final _notificationService = NotificationService();
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  List<String> _selectedNotifications = [];

  final List<String> _notificationOptions = [
    '15 minutes before',
    '1 hour before',
    '1 day before',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _costController.text = widget.event!.cost.toString();
      _startTime = widget.event!.startTime;
      _endTime = widget.event!.endTime;
      _selectedNotifications = List.from(widget.event!.notificationOptions);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final event = Event(
        id: widget.event?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        startTime: _startTime,
        endTime: _endTime,
        cost: double.parse(_costController.text),
        userId: userId,
        notificationOptions: _selectedNotifications,
      );

      if (widget.event == null) {
        await _eventService.createEvent(event);
      } else {
        await _eventService.updateEvent(event);
      }

      // Schedule notifications
      for (var notification in _selectedNotifications) {
        DateTime notificationTime;
        switch (notification) {
          case '15 minutes before':
            notificationTime = _startTime.subtract(const Duration(minutes: 15));
            break;
          case '1 hour before':
            notificationTime = _startTime.subtract(const Duration(hours: 1));
            break;
          case '1 day before':
            notificationTime = _startTime.subtract(const Duration(days: 1));
            break;
          default:
            continue;
        }

        await _notificationService.scheduleNotification(
          id: event.id.hashCode,
          title: event.title,
          body: 'Event starting ${notification}',
          scheduledTime: notificationTime,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStartTime ? _startTime : _endTime,
        ),
      );

      if (time != null) {
        setState(() {
          if (isStartTime) {
            _startTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          } else {
            _endTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a cost';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(
                '${_startTime.year}-${_startTime.month}-${_startTime.day} ${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(true),
            ),
            ListTile(
              title: const Text('End Time'),
              subtitle: Text(
                '${_endTime.year}-${_endTime.month}-${_endTime.day} ${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(false),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ..._notificationOptions.map((option) {
              return CheckboxListTile(
                title: Text(option),
                value: _selectedNotifications.contains(option),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedNotifications.add(option);
                    } else {
                      _selectedNotifications.remove(option);
                    }
                  });
                },
              );
            }).toList(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveEvent,
              child: Text(widget.event == null ? 'Create Event' : 'Update Event'),
            ),
          ],
        ),
      ),
    );
  }
} 