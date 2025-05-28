import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Create event
  Future<void> createEvent(Event event) async {
    try {
      await _firestore.collection(_collection).doc(event.id).set(event.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update event
  Future<void> updateEvent(Event event) async {
    try {
      await _firestore.collection(_collection).doc(event.id).update(event.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(eventId).get();
      if (doc.exists) {
        return Event.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get events for a specific user
  Stream<List<Event>> getUserEvents(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
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