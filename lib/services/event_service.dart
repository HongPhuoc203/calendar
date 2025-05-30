import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Create event
  Future<void> createEvent(Event event) async {
    try {
      print('Creating event: ${event.toMap()}'); // Debug print
      await _firestore.collection(_collection).doc(event.id).set(event.toMap());
      print('Event created successfully'); // Debug print
    } catch (e) {
      print('Error creating event: $e'); // Debug print
      rethrow;
    }
  }

  // Update event
  Future<void> updateEvent(Event event) async {
    try {
      print('Updating event: ${event.toMap()}'); // Debug print
      await _firestore.collection(_collection).doc(event.id).update(event.toMap());
      print('Event updated successfully'); // Debug print
    } catch (e) {
      print('Error updating event: $e'); // Debug print
      rethrow;
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      print('Deleting event: $eventId'); // Debug print
      await _firestore.collection(_collection).doc(eventId).delete();
      print('Event deleted successfully'); // Debug print
    } catch (e) {
      print('Error deleting event: $e'); // Debug print
      rethrow;
    }
  }

  // Get event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      print('Getting event by ID: $eventId'); // Debug print
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(eventId).get();
      if (doc.exists) {
        print('Event found: ${doc.data()}'); // Debug print
        return Event.fromMap(doc.data() as Map<String, dynamic>);
      }
      print('Event not found'); // Debug print
      return null;
    } catch (e) {
      print('Error getting event: $e'); // Debug print
      rethrow;
    }
  }

  // Get events for a specific user
  Stream<List<Event>> getUserEvents(String userId) {
    print('Getting events for user: $userId'); // Debug print
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      print('Received ${snapshot.docs.length} events from Firestore'); // Debug print
      final events = snapshot.docs
          .map((doc) {
            print('Processing document: ${doc.data()}'); // Debug print
            return Event.fromMap(doc.data());
          })
          .toList();
      print('Converted to ${events.length} Event objects'); // Debug print
      return events;
    });
  }

  // Get events for a specific date range
  Stream<List<Event>> getEventsByDateRange(
      String userId, DateTime start, DateTime end) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
    });
  }
} 