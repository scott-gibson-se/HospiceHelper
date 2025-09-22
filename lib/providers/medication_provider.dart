import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class MedicationProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  List<Medication> _medications = [];
  List<DoseLog> _doseLogs = [];
  bool _isLoading = false;

  List<Medication> get medications => _medications;
  List<DoseLog> get doseLogs => _doseLogs;
  bool get isLoading => _isLoading;

  Future<void> loadMedications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _medications = await _databaseHelper.getAllMedications();
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoseLogs() async {
    try {
      _doseLogs = await _databaseHelper.getAllDoseLogs();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dose logs: $e');
    }
  }

  Future<void> addMedication(Medication medication) async {
    try {
      final id = await _databaseHelper.insertMedication(medication);
      final newMedication = medication.copyWith(id: id);
      _medications.add(newMedication);
      notifyListeners();

      // Schedule notification if enabled
      if (medication.notificationsEnabled) {
        await _notificationService.scheduleMedicationNotification(newMedication);
      }
    } catch (e) {
      debugPrint('Error adding medication: $e');
      rethrow;
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      await _databaseHelper.updateMedication(medication);
      final index = _medications.indexWhere((m) => m.id == medication.id);
      if (index != -1) {
        _medications[index] = medication;
        notifyListeners();
      }

      // Update notification
      if (medication.notificationsEnabled) {
        await _notificationService.scheduleMedicationNotification(medication);
      } else {
        await _notificationService.cancelMedicationNotifications(medication.id!);
      }
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  Future<void> deleteMedication(int medicationId) async {
    try {
      await _databaseHelper.deleteMedication(medicationId);
      _medications.removeWhere((m) => m.id == medicationId);
      _doseLogs.removeWhere((d) => d.medicationId == medicationId);
      notifyListeners();

      // Cancel notification
      await _notificationService.cancelMedicationNotifications(medicationId);
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      rethrow;
    }
  }

  Future<void> logDose(DoseLog doseLog) async {
    try {
      final id = await _databaseHelper.insertDoseLog(doseLog);
      final newDoseLog = doseLog.copyWith(id: id);
      _doseLogs.insert(0, newDoseLog);
      notifyListeners();

      // Reschedule notification for next dose
      final medication = _medications.firstWhere((m) => m.id == doseLog.medicationId);
      if (medication.notificationsEnabled) {
        await _notificationService.scheduleMedicationNotification(medication);
      }
    } catch (e) {
      debugPrint('Error logging dose: $e');
      rethrow;
    }
  }

  Future<List<DoseLog>> getDoseLogsForMedication(int medicationId) async {
    try {
      return await _databaseHelper.getDoseLogsForMedication(medicationId);
    } catch (e) {
      debugPrint('Error getting dose logs for medication: $e');
      return [];
    }
  }

  Future<DoseLog?> getLastDoseForMedication(int medicationId) async {
    try {
      return await _databaseHelper.getLastDoseForMedication(medicationId);
    } catch (e) {
      debugPrint('Error getting last dose for medication: $e');
      return null;
    }
  }

  Future<Medication?> getMedication(int id) async {
    try {
      return await _databaseHelper.getMedication(id);
    } catch (e) {
      debugPrint('Error getting medication: $e');
      return null;
    }
  }

  Future<void> deleteDoseLog(int doseLogId) async {
    try {
      await _databaseHelper.deleteDoseLog(doseLogId);
      _doseLogs.removeWhere((d) => d.id == doseLogId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting dose log: $e');
      rethrow;
    }
  }

  // Get medications with their last dose information
  Future<List<Map<String, dynamic>>> getMedicationsWithLastDose() async {
    try {
      return await _databaseHelper.getMedicationsWithLastDose();
    } catch (e) {
      debugPrint('Error getting medications with last dose: $e');
      return [];
    }
  }

  // Check if medication is due for next dose
  bool isMedicationDue(Medication medication) {
    final lastDose = _doseLogs
        .where((d) => d.medicationId == medication.id)
        .isNotEmpty
        ? _doseLogs
            .where((d) => d.medicationId == medication.id)
            .reduce((a, b) => a.dateTime.isAfter(b.dateTime) ? a : b)
        : null;

    if (lastDose == null) return true;

    final timeSinceLastDose = DateTime.now().difference(lastDose.dateTime);
    return timeSinceLastDose.inMinutes >= medication.minTimeBetweenDoses;
  }

  // Get time until next dose is due
  Duration? getTimeUntilNextDose(Medication medication) {
    final lastDose = _doseLogs
        .where((d) => d.medicationId == medication.id)
        .isNotEmpty
        ? _doseLogs
            .where((d) => d.medicationId == medication.id)
            .reduce((a, b) => a.dateTime.isAfter(b.dateTime) ? a : b)
        : null;

    if (lastDose == null) return null;

    final nextDoseTime = lastDose.dateTime.add(Duration(minutes: medication.minTimeBetweenDoses));
    final now = DateTime.now();
    
    if (nextDoseTime.isBefore(now)) return null;
    
    return nextDoseTime.difference(now);
  }
}
