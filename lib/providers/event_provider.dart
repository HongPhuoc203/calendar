// import 'package:flutter/material.dart';
// import '../models/event_model.dart';
// import '../services/firestore_services.dart';
// import '../services/notification_services.dart';

// class EventProvider with ChangeNotifier {
//   final FirestoreService _firestoreService = FirestoreService();
//   final NotificationService _notificationService = NotificationService();

//   List<Event> _events = [];
//   DateTime _selectedDate = DateTime.now();
//   bool _isLoading = false;
//   String? _errorMessage;

//   List<Event> get events => _events;
//   DateTime get selectedDate => _selectedDate;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   List<Event> get eventsForSelectedDate => _events.where((event) =>
//     event.dateTime.year == _selectedDate.year &&
//     event.dateTime.month == _selectedDate.month &&
//     event.dateTime.day == _selectedDate.day).toList();

//   EventProvider() {
//     _loadEvents();
//   }

//   void setSelectedDate(DateTime date) {
//     _selectedDate = date;
//     notifyListeners();
//   }

//   void _loadEvents() {
//     _firestoreService.getEvents().listen(
//       (events) {
//         _events = events;
//         notifyListeners();
//       },
//       onError: (error) {
//         _errorMessage = error.toString();
//         notifyListeners();
//       },
//     );
//   }

//   Future<bool> createEvent(Event event) async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       String eventId = await _firestoreService.createEvent(event);
//       Event createdEvent = event.copyWith(id: eventId);

//       if (createdEvent.notificationOption > 0) {
//         DateTime notifyTime = NotificationService.getNotificationTime(
//           createdEvent.dateTime,
//           createdEvent.notificationOption,
//         );
//         await _notificationService.scheduleEventNotification(
//           id: createdEvent.id.hashCode,
//           title: createdEvent.title,
//           body: 'Event starting soon',
//           scheduledTime: notifyTime,
//         );
//       }

//       _isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _isLoading = false;
//       _errorMessage = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   Future<bool> updateEvent(Event event) async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       await _firestoreService.updateEvent(event);

//       await _notificationService.cancelEventNotification(event.id);

//       if (event.notificationOption > 0) {
//         DateTime notifyTime = NotificationService.getNotificationTime(
//           event.dateTime,
//           event.notificationOption,
//         );
//         await _notificationService.scheduleEventNotification(
//           id: event.id.hashCode,
//           title: event.title,
//           body: 'Event starting soon',
//           scheduledTime: notifyTime,
//         );
//       }

//       _isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _isLoading = false;
//       _errorMessage = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   Future<bool> deleteEvent(String eventId) async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       await _firestoreService.deleteEvent(eventId);
//       await _notificationService.cancelEventNotification(eventId);
//       _isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _isLoading = false;
//       _errorMessage = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   Future<Event?> getEvent(String eventId) async {
//     return await _firestoreService.getEvent(eventId);
//   }

//   void clearError() {
//     _errorMessage = null;
//     notifyListeners();
//   }
// }