import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'pdf_service.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import 'settings_service.dart';

class PdfReportService {
  /// Gets the accessible Downloads directory path
  static Future<String> _getAccessibleDownloadsPath() async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('External storage not available');
    }
    
    // Use the external storage root path that's accessible to other apps
    final externalStoragePath = directory.path.split('/Android')[0];
    final downloadsPath = '$externalStoragePath/Download';
    
    // Create Downloads directory if it doesn't exist
    final downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    return downloadsPath;
  }

  /// Generates a PDF report and returns the file path for manual sharing
  static Future<String> generateMedicationReportFile(
    List<Medication> medications,
    List<DoseLog> doseLogs,
  ) async {
    try {
      // Get patient name from settings
      final patientName = await SettingsService.getPatientName();
      
      // Generate PDF report
      final pdf = await PdfService.generateMedicationReport(medications, doseLogs, patientName: patientName);
      
      // Save to accessible Downloads directory
      final downloadsPath = await _getAccessibleDownloadsPath();
      final fileName = 'Hospice_Medication_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('$downloadsPath/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Failed to generate PDF report: $e');
    }
  }
}
