import '../models/dose_log.dart';
import '../models/medication.dart';

class MedicationDoseUtils {
  /// Total dose amount active at [atTime] within the medication's
  /// [Medication.minTimeBetweenDoses] look-back window.
  static double getActiveDoseAtTime(
    Medication medication,
    List<DoseLog> doseLogs,
    DateTime atTime,
  ) {
    final intervalStart = atTime.subtract(
      Duration(minutes: medication.minTimeBetweenDoses),
    );

    return doseLogs
        .where((log) => log.medicationId == medication.id)
        .where((log) => log.dateTime.isAfter(intervalStart))
        .where((log) => !log.dateTime.isAfter(atTime))
        .fold(0.0, (sum, log) => sum + log.doseGiven);
  }

  /// Active dose immediately before [atTime], excluding any dose given at [atTime].
  static double getActiveDoseBeforeTime(
    Medication medication,
    List<DoseLog> doseLogs,
    DateTime atTime,
  ) {
    final intervalStart = atTime.subtract(
      Duration(minutes: medication.minTimeBetweenDoses),
    );

    return doseLogs
        .where((log) => log.medicationId == medication.id)
        .where((log) => log.dateTime.isAfter(intervalStart))
        .where((log) => log.dateTime.isBefore(atTime))
        .fold(0.0, (sum, log) => sum + log.doseGiven);
  }
}
