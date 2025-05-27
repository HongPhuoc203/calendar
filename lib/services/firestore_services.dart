import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Create Event
  Future<String> createEvent(Event event) async {
    try {
      Event eventWithUserId = event.copyWith(
        ownerId: _userId,
        createdAt: DateTime.now(),
      );
      
      DocumentReference docRef = await _firestore
          .collection('events')
          .add(eventWithUserId.toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      throw e;
    }
  }

  // Read Events
  Stream<List<Event>> getEvents() {
    return _firestore
        .collection('events')
        .where('ownerId', isEqualTo: _userId)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  // Get Events for specific date
  Stream<List<Event>> getEventsForDate(DateTime date) {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('events')
        .where('ownerId', isEqualTo: _userId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  // Update Event
  Future<void> updateEvent(Event event) async {
    try {
      Event updatedEvent = event.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection('events')
          .doc(event.id)
          .update(updatedEvent.toFirestore());
    } catch (e) {
      print('Error updating event: $e');
      throw e;
    }
  }

  // Delete Event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      print('Error deleting event: $e');
      throw e;
    }
  }

  // Get single event
  Future<Event?> getEvent(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();
      
      if (doc.exists) {
        return Event.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }
}