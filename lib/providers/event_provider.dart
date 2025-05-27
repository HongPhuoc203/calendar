import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/firestore_services.dart';
import '../services/notification_services.dart';
class EventProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EventProvider() {
    _loadEvents();
  }

  void _loadEvents() {
    _firestoreService.getEvents().listen(
      (events) {
        _events = events;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  List<Event> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.dateTime.year == day.year &&
             event.dateTime.month == day.month &&
             event.dateTime.day == day.day;
    }).toList();
  }

  Future<bool> addEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required double cost,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Event newEvent = Event(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        dateTime: dateTime,
        location: location,
        cost: cost,
        ownerId: '', // Will be set by FirestoreService
        createdAt: DateTime.now(),
      );

      String eventId = await _firestoreService.createEvent(newEvent);
      
      // Schedule notification
      Event eventWithId = newEvent.copyWith(id: eventId);
      await _notificationService.scheduleEventNotification(eventWithId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEvent(Event event) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateEvent(event);
      
      // Cancel old notification and schedule new one
      await _notificationService.cancelEventNotification(event.id);
      await _notificationService.scheduleEventNotification(event);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteEvent(eventId);
      
      // Cancel notification
      await _notificationService.cancelEventNotification(eventId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Event?> getEvent(String eventId) async {
    return await _firestoreService.getEvent(eventId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}