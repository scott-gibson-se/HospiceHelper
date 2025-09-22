import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'pdf_service.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';

class EmailService {
  static Future<void> sendMedicationReport(
    List<Medication> medications,
    List<DoseLog> doseLogs,
    String recipientEmail,
  ) async {
    try {
      // Generate PDF report
      final pdf = await PdfService.generateMedicationReport(medications, doseLogs);
      
      // Save PDF to temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/medication_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Create email subject and body
      final subject = 'Hospice Medication Report - ${DateTime.now().toString().split(' ')[0]}';
      final body = '''
Dear Caregiver,

Please find attached the medication report for the hospice patient.

This report includes:
- Current medication list with dosages and timing
- Complete dose history with timestamps
- Caregiver information for each dose

If you have any questions about this report, please contact the healthcare team.

Best regards,
Hospice Medication Tracker
      ''';

      // Create email URI
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
