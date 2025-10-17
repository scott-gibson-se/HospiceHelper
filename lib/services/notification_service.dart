import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Set the local timezone explicitly
    try {
      final String timeZoneName = await _getTimeZoneName();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('Error setting timezone: $e');
      // Fallback to UTC
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  Future<String> _getTimeZoneName() async {
    try {
      // Get the system timezone
      final now = DateTime.now();
      return now.timeZoneName;
    } catch (e) {
      debugPrint('Error getting timezone name: $e');
      return 'UTC';
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
      // Create the main medication reminders channel with default sound
      const AndroidNotificationChannel medicationChannel = AndroidNotificationChannel(
        'medication_reminders',
        'Medication Reminders',
        description: 'Reminders for medication doses',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        // Use default system sound for the channel
      );

      // Create the channel
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(medicationChannel);

      debugPrint('Notification channel ensured: medication_reminders');
    } catch (e) {
      debugPrint('Error creating notification channels: $e');
    }
  }

  Future<bool> requestNotificationPermissions() async {
    try {
      // Request notification permission for Android 13+
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        debugPrint('Android notification permission requested: $granted');
        return granted ?? false;
      }
      
      // For iOS, permissions are requested during initialization
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<bool> checkNotificationPermissions() async {
    try {
      // Check notification permission for Android 13+
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        debugPrint('Android notifications enabled: $granted');
        return granted ?? false;
      }
      
      // For iOS, assume granted if we got this far
      return true;
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
      return false;
    }
  }

  Future<bool> checkExactAlarmPermissions() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final canScheduleExactAlarms = await androidImplementation.canScheduleExactNotifications();
        debugPrint('Can schedule exact alarms: $canScheduleExactAlarms');
        return canScheduleExactAlarms ?? false;
      }
      
      return true; // Assume true for non-Android platforms
    } catch (e) {
      debugPrint('Error checking exact alarm permissions: $e');
      return false;
    }
  }

  Future<bool> requestExactAlarmPermissions() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestExactAlarmsPermission();
        debugPrint('Exact alarm permission requested: $granted');
        return granted ?? false;
      }
      
      return true; // Assume true for non-Android platforms
    } catch (e) {
      debugPrint('Error requesting exact alarm permissions: $e');
      return false;
    }
  }

  Future<void> openAppSettings() async {}

  void _onNotificationTapped(NotificationResponse response) {}

  Future<void> scheduleMedicationNotification(Medication medication) async {
    debugPrint('=== SCHEDULING NOTIFICATION ===');
    debugPrint('Medication: ${medication.name}');
    debugPrint('Notifications enabled: ${medication.notificationsEnabled}');
    debugPrint('Medication ID: ${medication.id}');
    debugPrint('Min time between doses: ${medication.minTimeBetweenDoses} minutes');
    
    if (!medication.notificationsEnabled) {
      debugPrint('Notifications disabled for ${medication.name}');
      return;
    }

    // Must have an ID to uniquely schedule/cancel
    if (medication.id == null) {
      debugPrint('Cannot schedule: medication has no ID');
      return;
    }

    // Check/request notification permission (Android 13+)
    bool granted = await checkNotificationPermissions();
    debugPrint('Initial permission check: $granted');
    if (!granted) {
      granted = await requestNotificationPermissions();
      debugPrint('Permission after request: $granted');
      if (!granted) {
        debugPrint('Permission denied - cannot schedule notification');
        return;
      }
    }

    // Check exact alarm permissions for scheduled notifications
    bool exactAlarmGranted = await checkExactAlarmPermissions();
    if (!exactAlarmGranted) {
      exactAlarmGranted = await requestExactAlarmPermissions();
      if (!exactAlarmGranted) {
        debugPrint('❌ Exact alarm permission denied - scheduled notifications may not work reliably');
        // Continue anyway, but use inexact scheduling
      }
    }

    // Ensure base channel exists
    await _createNotificationChannels();
    debugPrint('Notification channels ensured');

    // Cancel existing notification for this medication
    await cancelMedicationNotifications(medication.id!);
    debugPrint('Cancelled existing notifications for medication ${medication.id}');

    // Schedule for minTimeBetweenDoses from now
    final now = DateTime.now();
    final scheduledTime = tz.TZDateTime.now(tz.local).add(
      Duration(minutes: medication.minTimeBetweenDoses),
    );
    
    debugPrint('Current time: $now');
    debugPrint('Scheduled time: ${scheduledTime.toLocal()}');
    debugPrint('Time difference: ${scheduledTime.difference(now).inMinutes} minutes');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders for medication doses',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use exact scheduling if we have permission, otherwise use inexact
    final scheduleMode = exactAlarmGranted 
        ? AndroidScheduleMode.exactAllowWhileIdle 
        : AndroidScheduleMode.inexactAllowWhileIdle;
    
    debugPrint('Using schedule mode: $scheduleMode');

    try {
      await _notifications.zonedSchedule(
        medication.id!,
        'Medication Reminder',
        'Time for ${medication.name} (${medication.form})',
        scheduledTime,
        details,
        androidScheduleMode: scheduleMode,
        payload: 'medication_${medication.id}',
      );
      debugPrint('✅ Notification scheduled successfully for ${medication.name}');
      
      // Log pending notifications for debugging
      await logPendingNotifications();
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
      rethrow;
    }
  }

  Future<void> cancelMedicationNotifications(int medicationId) async {
    await _notifications.cancel(medicationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> logPendingNotifications() async {
    try {
      final pending = await getPendingNotifications();
      debugPrint('=== PENDING NOTIFICATIONS ===');
      debugPrint('Total pending: ${pending.length}');
      for (final notification in pending) {
        debugPrint('ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
        debugPrint('Payload: ${notification.payload}');
      }
      debugPrint('=== END PENDING NOTIFICATIONS ===');
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
    }
  }

  // Test method to show immediate notification
  Future<void> showTestNotification() async {
    try {
      debugPrint('Testing immediate notification...');
      
      // Check and request permissions first
      bool granted = await checkNotificationPermissions();
      if (!granted) {
        granted = await requestNotificationPermissions();
        if (!granted) {
          debugPrint('❌ Notification permission denied');
          throw Exception('Notification permission denied');
        }
      }
      
      // Ensure notification channel exists
      await _createNotificationChannels();
      debugPrint('Notification channel ensured');
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Reminders for medication doses',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        999,
        'Test Notification',
        'This is a test notification to verify the system works',
        details,
        payload: 'test_notification',
      );
      
      debugPrint('✅ Test notification shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing test notification: $e');
      rethrow;
    }
  }

  // Test method to schedule a notification in 10 seconds
  Future<void> showTestScheduledNotification() async {
    try {
      debugPrint('Testing scheduled notification in 10 seconds...');
      
      // Check and request notification permissions first
      bool granted = await checkNotificationPermissions();
      if (!granted) {
        granted = await requestNotificationPermissions();
        if (!granted) {
          debugPrint('❌ Notification permission denied');
          throw Exception('Notification permission denied');
        }
      }
      
      // Check exact alarm permissions for scheduled notifications
      bool exactAlarmGranted = await checkExactAlarmPermissions();
      if (!exactAlarmGranted) {
        exactAlarmGranted = await requestExactAlarmPermissions();
        if (!exactAlarmGranted) {
          debugPrint('❌ Exact alarm permission denied - scheduled notifications may not work reliably');
          // Continue anyway, but use inexact scheduling
        }
      }
      
      // Ensure notification channel exists
      await _createNotificationChannels();
      debugPrint('Notification channel ensured');
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Reminders for medication doses',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule for 10 seconds from now
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
      debugPrint('Scheduling test notification for: ${scheduledTime.toLocal()}');
      debugPrint('Current time: ${DateTime.now()}');
      debugPrint('Time difference: ${scheduledTime.difference(DateTime.now()).inSeconds} seconds');

      // Use exact scheduling if we have permission, otherwise use inexact
      final scheduleMode = exactAlarmGranted 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle;
      
      debugPrint('Using schedule mode: $scheduleMode');

      await _notifications.zonedSchedule(
        998,
        'Test Scheduled Notification',
        'This is a test scheduled notification - should appear in 10 seconds',
        scheduledTime,
        details,
        androidScheduleMode: scheduleMode,
        payload: 'test_scheduled_notification',
      );
      
      debugPrint('✅ Test scheduled notification scheduled successfully');
      
      // Log pending notifications
      await logPendingNotifications();
    } catch (e) {
      debugPrint('❌ Error scheduling test notification: $e');
      rethrow;
    }
  }

}
