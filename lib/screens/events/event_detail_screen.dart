import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;
  final EventService _eventService = EventService();

  EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit event screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Event'),
                  content: const Text('Are you sure you want to delete this event?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _eventService.deleteEvent(event.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(event.description),
            const SizedBox(height: 16),
            Text(
              'Time:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${event.startTime.year}-${event.startTime.month}-${event.startTime.day} ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 16),
            Text(
              'Cost:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('\$${event.cost.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Text(
              'Notifications:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...event.notificationOptions.map((option) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text('• $option'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 