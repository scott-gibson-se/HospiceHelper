import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';

class PdfService {
  static Future<pw.Document> generateMedicationReport(
    List<Medication> medications,
    List<DoseLog> doseLogs, {
    String? patientName,
  }) async {
    final pdf = pw.Document();

    // Add header page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return _buildHeader(patientName);
        },
      ),
    );

    // Add medication summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return _buildMedicationSummary(medications);
        },
      ),
    );

    // Add dose history with proper pagination
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        maxPages: 100,
        build: (pw.Context context) {
          return [
            _buildDoseHistoryHeader(),
            pw.SizedBox(height: 12),
            _buildDoseHistoryTable(doseLogs, medications),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(String? patientName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Hospice Medication Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (patientName != null && patientName.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Patient: $patientName',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMedicationSummary(List<Medication> medications) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Medication Summary',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Medication Name', isHeader: true),
                _buildTableCell('Official Name', isHeader: true),
                _buildTableCell('Form', isHeader: true),
                _buildTableCell('Max Dosage', isHeader: true),
                _buildTableCell('Min Interval', isHeader: true),
              ],
            ),
            ...medications.map((med) => pw.TableRow(
              children: [
                _buildTableCell(med.name),
                _buildTableCell(med.officialName),
                _buildTableCell(med.form),
                _buildTableCell('${med.maxDosage}'),
                _buildTableCell(med.formattedTimeInterval),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDoseHistoryHeader() {
    return pw.Text(
      'Dose History',
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _buildDoseHistoryTable(List<DoseLog> doseLogs, List<Medication> medications) {
    final medicationMap = {for (var med in medications) med.id: med};

    if (doseLogs.isEmpty) {
      return pw.Text(
        'No doses logged yet',
        style: pw.TextStyle(
          fontSize: 12,
          color: PdfColors.grey600,
        ),
      );
    }

    // Prepare data for Table.fromTextArray
    final headers = ['Medication', 'Dose', 'Given By', 'Date & Time', 'Note'];
    final data = doseLogs.map((log) {
      final medication = medicationMap[log.medicationId];
      return [
        medication?.name ?? 'Unknown',
        '${log.doseGiven} ${medication?.form ?? ''}',
        log.givenBy,
        DateFormat('MMM dd, yyyy hh:mm a').format(log.dateTime),
        log.note ?? '',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey800,
      ),
      cellStyle: pw.TextStyle(
        fontSize: 9,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1),
      },
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
