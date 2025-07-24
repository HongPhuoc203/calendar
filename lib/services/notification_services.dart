import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Set local timezone more accurately
      final String timeZoneName = await _getLocalTimeZone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      _isInitialized = true;
      print('[NotificationService] Initialized successfully with timezone: $timeZoneName');
    } catch (e) {
      print('[NotificationService] Initialization error: $e');
      rethrow;
    }
  }

  Future<String> _getLocalTimeZone() async {
    try {
      // Get system timezone more accurately
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      
      // For Vietnam timezone
      if (offset.inHours == 7) {
        return 'Asia/Ho_Chi_Minh';
      }
      
      // Fallback to common timezones based on offset
      switch (offset.inHours) {
        case 0: return 'UTC';
        case 1: return 'Europe/London';
        case 8: return 'Asia/Shanghai';
        case 9: return 'Asia/Tokyo';
        case -5: return 'America/New_York';
        case -8: return 'America/Los_Angeles';
        default: return 'Asia/Ho_Chi_Minh'; // Default for Vietnam
      }
    } catch (e) {
      return 'Asia/Ho_Chi_Minh';
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    print('[NotificationService] Notification clicked: ${response.payload}');
  }

  Future<bool> requestPermission() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          // Request notification permission
          final bool? granted = await androidImplementation.requestNotificationsPermission();
          
          // CRITICAL: Request exact alarm permission for precise scheduling
          final bool? exactAlarmPermission = await androidImplementation.requestExactAlarmsPermission();
          print('[NotificationService] Exact alarm permission: $exactAlarmPermission');
          
          // Also check if we can schedule exact alarms
          final bool? canScheduleExact = await androidImplementation.canScheduleExactNotifications();
          print('[NotificationService] Can schedule exact notifications: $canScheduleExact');
          
          print('[NotificationService] Permission granted: $granted');
          return (granted ?? false) && (exactAlarmPermission ?? false);
        }
      }

      // For iOS
      if (Platform.isIOS) {
        final bool? result = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return result ?? false;
      }

      return false;
    } catch (e) {
      print('[NotificationService] Permission request error: $e');
      return false;
    }
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'instant_notifications',
        'Instant Notifications',
        channelDescription: 'Instant notifications for testing',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        ticker: 'Instant notification',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('[NotificationService] Instant notification sent: $title');
    } catch (e) {
      print('[NotificationService] Error showing instant notification: $e');
      rethrow;
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool useExactTiming = true,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // FIX: Use consistent DateTime comparison - convert both to the same format
      final now = DateTime.now();
      
      // Add safety buffer of 30 seconds instead of 10
      if (scheduledTime.isBefore(now.add(Duration(seconds: 30)))) {
        print('[NotificationService] Scheduled time is too close or in the past');
        print('[NotificationService] Current time: $now');
        print('[NotificationService] Scheduled time: $scheduledTime');
        return;
      }

      // Convert to TZDateTime with proper timezone handling
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
      
      // Verify the conversion is correct
      print('[NotificationService] Original time: $scheduledTime');
      print('[NotificationService] TZ converted time: $scheduledDate');
      print('[NotificationService] Current time: $now');
      print('[NotificationService] Current TZ time: ${tz.TZDateTime.now(tz.local)}');
      
      // Additional validation: ensure TZ time is also in the future
      final currentTzTime = tz.TZDateTime.now(tz.local);
      if (scheduledDate.isBefore(currentTzTime.add(Duration(seconds: 30)))) {
        print('[NotificationService] TZ scheduled time is too close or in the past');
        return;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'scheduled_notifications',
        'Scheduled Notifications',
        channelDescription: 'Scheduled notifications with exact timing',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        autoCancel: true,
        ongoing: false,
        ticker: 'Scheduled notification',
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'scheduled_notification',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Cancel existing notification with same ID to avoid conflicts
      await _notifications.cancel(id);

      // FIX: Use more reliable scheduling strategy
      if (useExactTiming && Platform.isAndroid) {
        // For exact timing, use exactAllowWhileIdle mode
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          // FIX: Remove matchDateTimeComponents for one-time notifications
          // matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } else {
        // For less critical timing, use inexact mode (more battery friendly)
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          // FIX: Remove matchDateTimeComponents for one-time notifications
          // matchDateTimeComponents: DateTimeComponents.time,
          
          payload: payload,
        );
      }

      print('[NotificationService] Scheduled notification: $title');
      print('[NotificationService] Scheduled for: $scheduledDate');
      print('[NotificationService] Use exact timing: $useExactTiming');
      
      // Verify scheduling
      await Future.delayed(Duration(milliseconds: 500));
      await debugScheduledNotifications();
      
    } catch (e) {
      print('[NotificationService] Error scheduling notification: $e');
      rethrow;
    }
  }

  // Schedule multiple notifications with different strategies
  Future<void> scheduleRepeatingNotification({
    required int baseId,
    required String title,
    required String body,
    required DateTime firstNotification,
    required Duration interval,
    required int count,
  }) async {
    for (int i = 0; i < count; i++) {
      final scheduledTime = firstNotification.add(interval * i);
      await scheduleNotification(
        id: baseId + i,
        title: '$title ${i + 1}',
        body: body,
        scheduledTime: scheduledTime,
        useExactTiming: i < 3, // Use exact timing for first 3 notifications
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('[NotificationService] Cancelled notification: $id');
    } catch (e) {
      print('[NotificationService] Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('[NotificationService] Cancelled all notifications');
    } catch (e) {
      print('[NotificationService] Error cancelling all notifications: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('[NotificationService] Pending notifications count: ${pending.length}');
      return pending;
    } catch (e) {
      print('[NotificationService] Error getting pending notifications: $e');
      return [];
    }
  }

  // Enhanced debug method
  Future<void> debugScheduledNotifications() async {
    try {
      final pending = await getPendingNotifications();
      print('\n=== NOTIFICATION DEBUG INFO ===');
      print('Total pending notifications: ${pending.length}');
      print('Current time: ${DateTime.now()}');
      print('Current TZ time: ${tz.TZDateTime.now(tz.local)}');
      print('Timezone: ${tz.local.name}');
      print('Timezone offset: ${DateTime.now().timeZoneOffset}');
      
      for (var notification in pending) {
        print('--- Notification ID: ${notification.id} ---');
        print('Title: ${notification.title}');
        print('Body: ${notification.body}');
      }
      
      // Check Android permissions
      if (Platform.isAndroid) {
        final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final canScheduleExact = await androidImplementation.canScheduleExactNotifications();
          print('Can schedule exact notifications: $canScheduleExact');
        }
      }
      
      print('===============================\n');
    } catch (e) {
      print('[NotificationService] Debug error: $e');
    }
  }

  
}