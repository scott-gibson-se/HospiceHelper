import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'pdf_service.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';

class EmailService {
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
  static Future<void> sendMedicationReport(
    List<Medication> medications,
    List<DoseLog> doseLogs,
    String recipientEmail,
  ) async {
    try {
      // Generate PDF report
      final pdf = await PdfService.generateMedicationReport(medications, doseLogs);
      
      // Save to accessible Downloads directory
      final downloadsPath = await _getAccessibleDownloadsPath();
      final fileName = 'Hospice_Medication_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('$downloadsPath/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Create email subject and body with file location information
      final subject = 'Hospice Medication Report - ${DateTime.now().toString().split(' ')[0]}';
      final body = '''
Dear Caregiver,

Please find the medication report for the hospice patient.

IMPORTANT: The PDF report has been saved to your device at:
${file.path}

To attach this report to your email:
1. Open your email app
2. Create a new email to $recipientEmail
3. Use the "Attach" or "Paperclip" button
4. Navigate to the file location above and select the PDF

This report includes:
- Current medication list with dosages and timing
- Complete dose history with timestamps
- Caregiver information for each dose

If you have any questions about this report, please contact the healthcare team.

Best regards,
Hospice Helper
      ''';

      // Create email URI with file location information
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipientEmail,
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      // Launch email client
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  /// Generates a PDF report and returns the file path for manual sharing
  static Future<String> generateMedicationReportFile(
    List<Medication> medications,
    List<DoseLog> doseLogs,
  ) async {
    try {
      // Generate PDF report
      final pdf = await PdfService.generateMedicationReport(medications, doseLogs);
      
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

  static Future<void> sendDoseAlert(
    String medicationName,
    String caregiverName,
    String recipientEmail,
  ) async {
    try {
      final subject = 'Medication Dose Alert - $medicationName';
      final body = '''
Dear $caregiverName,

This is an automated alert that a dose of $medicationName has been administered.

Time: ${DateTime.now().toString()}

Please confirm receipt of this notification.

Best regards,
Hospice Medication Tracker
      ''';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipientEmail,
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      throw Exception('Failed to send dose alert: $e');
    }
  }

  static Future<void> sendEmergencyContact(
    String patientName,
    String emergencyInfo,
    String recipientEmail,
  ) async {
    try {
      final subject = 'Emergency Contact - $patientName';
      final body = '''
EMERGENCY ALERT

Patient: $patientName
Time: ${DateTime.now().toString()}

Emergency Information:
$emergencyInfo

Please respond immediately.

Best regards,
Hospice Medication Tracker
      ''';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipientEmail,
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      throw Exception('Failed to send emergency contact: $e');
    }
  }
}
