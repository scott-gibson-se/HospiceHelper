import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _patientNameKey = 'patient_name';

  /// Gets the patient name from shared preferences
  static Future<String?> getPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientNameKey);
  }

  /// Sets the patient name in shared preferences
  static Future<bool> setPatientName(String patientName) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_patientNameKey, patientName.trim());
  }

  /// Checks if patient name is set
  static Future<bool> isPatientNameSet() async {
    final patientName = await getPatientName();
    return patientName != null && patientName.trim().isNotEmpty;
  }

  /// Clears the patient name
  static Future<bool> clearPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_patientNameKey);
  }
}
