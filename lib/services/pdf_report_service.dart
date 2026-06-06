import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'pdf_service.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import '../models/question.dart';
import '../models/note.dart';
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

  static String _formatDateForFileName(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static Future<String> _saveReportFile(
    dynamic pdf,
    String reportPrefix,
    DateTime reportStartDate,
    DateTime reportEndDate,
  ) async {
    final downloadsPath = await _getAccessibleDownloadsPath();
    final fromDate = _formatDateForFileName(reportStartDate);
    final toDate = _formatDateForFileName(reportEndDate);
    final fileName = '${reportPrefix}_${fromDate}_to_$toDate.pdf';
    final file = File('$downloadsPath/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<String> generateMedicationsReportFile(
    List<Medication> medications, {
    required DateTime reportStartDate,
    required DateTime reportEndDate,
  }) async {
    try {
      final patientName = await SettingsService.getPatientName();
      final pdf = await PdfService.generateMedicationsReport(
        medications,
        patientName: patientName,
        reportStartDate: reportStartDate,
        reportEndDate: reportEndDate,
      );

      return await _saveReportFile(
        pdf,
        'Hospice_Medications_Report',
        reportStartDate,
        reportEndDate,
      );
    } catch (e) {
      throw Exception('Failed to generate medications PDF report: $e');
    }
  }

  static Future<String> generateDoseHistoryReportFile(
    List<Medication> medications,
    List<DoseLog> doseLogs, {
    required DateTime reportStartDate,
    required DateTime reportEndDate,
  }) async {
    try {
      final patientName = await SettingsService.getPatientName();
      final pdf = await PdfService.generateDoseHistoryReport(
        medications,
        doseLogs,
        patientName: patientName,
        reportStartDate: reportStartDate,
        reportEndDate: reportEndDate,
      );

      return await _saveReportFile(
        pdf,
        'Hospice_Dose_History_Report',
        reportStartDate,
        reportEndDate,
      );
    } catch (e) {
      throw Exception('Failed to generate dose history PDF report: $e');
    }
  }

  static Future<String> generateMedicationDoseActiveReportFile(
    List<Medication> medications,
    List<DoseLog> allDoseLogs,
    List<DoseLog> reportDoseLogs, {
    required DateTime reportStartDate,
    required DateTime reportEndDate,
    Medication? filteredMedication,
  }) async {
    try {
      final patientName = await SettingsService.getPatientName();
      final pdf = await PdfService.generateMedicationDoseActiveReport(
        medications,
        allDoseLogs,
        reportDoseLogs,
        patientName: patientName,
        reportStartDate: reportStartDate,
        reportEndDate: reportEndDate,
        filteredMedication: filteredMedication,
      );

      return await _saveReportFile(
        pdf,
        'Hospice_Medication_Dose_Active_Report',
        reportStartDate,
        reportEndDate,
      );
    } catch (e) {
      throw Exception('Failed to generate medication dose active PDF report: $e');
    }
  }

  static Future<String> generateMedicationDoseGridReportFile(
    List<Medication> medications,
    List<DoseLog> doseLogs, {
    required DateTime reportStartDate,
    required DateTime reportEndDate,
  }) async {
    try {
      final patientName = await SettingsService.getPatientName();
      final pdf = await PdfService.generateMedicationDoseGridReport(
        medications,
        doseLogs,
        patientName: patientName,
        reportStartDate: reportStartDate,
        reportEndDate: reportEndDate,
      );

      return await _saveReportFile(
        pdf,
        'Hospice_Medication_Dose_Grid_Report',
        reportStartDate,
        reportEndDate,
      );
    } catch (e) {
      throw Exception('Failed to generate medication dose grid PDF report: $e');
    }
  }

  static Future<String> generateQuestionsReportFile(
    List<Question> questions, {
    required DateTime reportStartDate,
    required DateTime reportEndDate,
  }) async {
    try {
      final patientName = await SettingsService.getPatientName();
      final pdf = await PdfService.generateQuestionsReport(
        questions,
        patientName: patientName,
        reportStartDate: reportStartDate,
        reportEndDate: reportEndDate,
      );

      return await _saveReportFile(
        pdf,
        'Hospice_Questions_Report',
        reportStartDate,
        reportEndDate,
      );
    } catch (e) {
      throw Exception('Failed to generate questions PDF report: $e');
    }
  }

  static Future<String> generateNotesReportFile(
    List<Note> notes, {
    required DateTime reportStartDate,
    required DateTime reportEndDate,
  }) async {
    try {
      final patientName = await SettingsService.getPatientName();
      final pdf = await PdfService.generateNotesReport(
        notes,
        patientName: patientName,
        reportStartDate: reportStartDate,
        reportEndDate: reportEndDate,
      );

      return await _saveReportFile(
        pdf,
        'Hospice_Notes_Report',
        reportStartDate,
        reportEndDate,
      );
    } catch (e) {
      throw Exception('Failed to generate PDF report: $e');
    }
  }
}
