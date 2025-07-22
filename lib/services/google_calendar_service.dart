import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../models/event.dart';
import 'package:uuid/uuid.dart';

class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  static final List<String> _scopes = [
    calendar.CalendarApi.calendarScope,
  ];

  GoogleSignIn? _googleSignIn;
  calendar.CalendarApi? _calendarApi;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
      serverClientId: '883106794802-hejalk1k5l7fiis9n3hjo6btnj5l5v35.apps.googleusercontent.com', // You'll need to add this
    );

    _isInitialized = true;
  }

  Future<bool> signIn() async {
    try {
      await initialize();
      final account = await _googleSignIn!.signIn();
      if (account != null) {
        final httpClient = await _googleSignIn!.authenticatedClient();
        _calendarApi = calendar.CalendarApi(httpClient!);
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in to Google: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    _calendarApi = null;
  }

  bool get isSignedIn => _googleSignIn?.currentUser != null;

  Future<List<Event>> fetchGoogleCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
    required String userId,
  }) async {
    if (_calendarApi == null) {
      throw Exception('Not signed in to Google Calendar');
    }

    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now().add(const Duration(days: 30));

      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: startDate.toUtc(),
        timeMax: endDate.toUtc(),
        maxResults: 250,
        singleEvents: true,
        orderBy: 'startTime',
      );

      List<Event> localEvents = [];
      
      for (var googleEvent in events.items ?? []) {
        if (googleEvent.start?.dateTime != null && googleEvent.end?.dateTime != null) {
          final localEvent = Event(
            id: googleEvent.id ?? const Uuid().v4(),
            title: googleEvent.summary ?? 'Không có tiêu đề',
            description: googleEvent.description ?? '',
            startTime: googleEvent.start!.dateTime!.toLocal(),
            endTime: googleEvent.end!.dateTime!.toLocal(),
            cost: 0.0, // Google Calendar doesn't have cost field
            userId: userId,
            notificationOptions: [], // Can be populated based on Google event reminders
          );
          localEvents.add(localEvent);
        }
      }

      return localEvents;
    } catch (e) {
      print('Error fetching Google Calendar events: $e');
      rethrow;
    }
  }

  Future<bool> createGoogleCalendarEvent(Event event) async {
    if (_calendarApi == null) {
      throw Exception('Not signed in to Google Calendar');
    }

    try {
      final googleEvent = calendar.Event(
        summary: event.title,
        description: '${event.description}\n\nChi phí: ${event.cost.toStringAsFixed(2)} VND',
        start: calendar.EventDateTime(
          dateTime: event.startTime.toUtc(),
          timeZone: 'UTC',
        ),
        end: calendar.EventDateTime(
          dateTime: event.endTime.toUtc(),
          timeZone: 'UTC',
        ),
        reminders: calendar.EventReminders(
          useDefault: false,
          overrides: [
            calendar.EventReminder(
              method: 'popup',
              minutes: 30,
            ),
          ],
        ),
      );

      await _calendarApi!.events.insert(googleEvent, 'primary');
      return true;
    } catch (e) {
      print('Error creating Google Calendar event: $e');
      return false;
    }
  }

  Future<bool> updateGoogleCalendarEvent(Event event) async {
    if (_calendarApi == null) {
      throw Exception('Not signed in to Google Calendar');
    }

    try {
      final googleEvent = calendar.Event(
        summary: event.title,
        description: '${event.description}\n\nChi phí: ${event.cost.toStringAsFixed(2)} VND',
        start: calendar.EventDateTime(
          dateTime: event.startTime.toUtc(),
          timeZone: 'UTC',
        ),
        end: calendar.EventDateTime(
          dateTime: event.endTime.toUtc(),
          timeZone: 'UTC',
        ),
        reminders: calendar.EventReminders(
          useDefault: false,
          overrides: [
            calendar.EventReminder(
              method: 'popup',
              minutes: 30,
            ),
          ],
        ),
      );

      await _calendarApi!.events.update(googleEvent, 'primary', event.id);
      return true;
    } catch (e) {
      print('Error updating Google Calendar event: $e');
      return false;
    }
  }

  Future<bool> deleteGoogleCalendarEvent(String eventId) async {
    if (_calendarApi == null) {
      throw Exception('Not signed in to Google Calendar');
    }

    try {
      await _calendarApi!.events.delete('primary', eventId);
      return true;
    } catch (e) {
      print('Error deleting Google Calendar event: $e');
      return false;
    }
  }

  Future<void> syncCalendars({
    required String userId,
    required Function(List<Event>) onEventsImported,
    required Function(String) onStatusUpdate,
  }) async {
    try {
      onStatusUpdate('Đang kết nối Google Calendar...');
      
      if (!isSignedIn) {
        final signedIn = await signIn();
        if (!signedIn) {
          throw Exception('Không thể đăng nhập Google Calendar');
        }
      }

      onStatusUpdate('Đang tải sự kiện từ Google Calendar...');
      
      final googleEvents = await fetchGoogleCalendarEvents(
        userId: userId,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 180)),
      );

      onStatusUpdate('Đã tải ${googleEvents.length} sự kiện từ Google Calendar');
      onEventsImported(googleEvents);
      
    } catch (e) {
      onStatusUpdate('Lỗi đồng bộ: $e');
      rethrow;
    }
  }
} 