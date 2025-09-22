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
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleMedicationNotification(Medication medication) async {
    if (!medication.notificationsEnabled) return;

    try {
      // Cancel existing notifications for this medication
      await cancelMedicationNotifications(medication.id!);

      // Get the last dose time
      // This would typically come from the database
      // For now, we'll schedule a notification for 1 hour from now as an example
      final now = DateTime.now();
      final scheduledTime = tz.TZDateTime.from(now.add(Duration(minutes: medication.minTimeBetweenDoses)), tz.local);

      // Create notification details based on sound preference
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Reminders for medication doses',
        importance: Importance.high,
        priority: Priority.high,
      );

      // Add sound based on preference
      if (medication.notificationSound != 'gentle') {
        androidDetails = AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders for medication doses',
          importance: Importance.high,
          priority: Priority.high,
          sound: _getNotificationSound(medication.notificationSound),
        );
      }

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        medication.id!,
        'Medication Reminder',
        'Time for ${medication.name} (${medication.form})',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'medication_${medication.id}',
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      rethrow; // Re-throw to let the caller handle the error
    }
  }

  AndroidNotificationSound? _getNotificationSound(String sound) {
    switch (sound) {
      case 'soft_chime':
        return const RawResourceAndroidNotificationSound('soft_chime');
      case 'bell':
        return const RawResourceAndroidNotificationSound('bell');
      case 'alarm':
        return const RawResourceAndroidNotificationSound('alarm');
      case 'urgent':
        return const RawResourceAndroidNotificationSound('urgent');
      case 'medical':
        return const RawResourceAndroidNotificationSound('medical');
      default:
        return null; // Use default system sound
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

  // Get available notification sounds
  static List<String> getAvailableSounds() {
    return [
      'gentle',
      'soft_chime',
      'bell',
      'alarm',
      'urgent',
      'medical',
    ];
  }

  // Get sound description
  static String getSoundDescription(String sound) {
    switch (sound) {
      case 'gentle':
        return 'Gentle chime (benign)';
      case 'soft_chime':
        return 'Soft chime (calm)';
      case 'bell':
        return 'Bell tone (moderate)';
      case 'alarm':
        return 'Alarm sound (attention-getting)';
      case 'urgent':
        return 'Urgent tone (very attention-getting)';
      case 'medical':
        return 'Medical alert (maximum attention)';
      default:
        return 'Unknown sound';
    }
  }
}
