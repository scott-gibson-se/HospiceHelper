import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import '../models/question.dart';
import '../models/note.dart';

class PdfService {
  static Future<pw.Document> generateMedicationReport(
    List<Medication> medications,
    List<DoseLog> doseLogs, {
    String? patientName,
    DateTime? reportStartDate,
    DateTime? reportEndDate,
  }) async {
    final pdf = pw.Document();

    // Add header page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return _buildHeader(
            title: 'Hospice Medication Report',
            patientName: patientName,
            reportStartDate: reportStartDate,
            reportEndDate: reportEndDate,
          );
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
            _buildDoseHistoryTable(
              doseLogs,
              medications,
              hasDateRange: reportStartDate != null && reportEndDate != null,
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static Future<pw.Document> generateMedicationDoseGridReport(
    List<Medication> medications,
    List<DoseLog> doseLogs, {
    String? patientName,
    required DateTime reportStartDate,
    required DateTime reportEndDate,
  }) async {
    final pdf = pw.Document();
    final months = _monthsInRange(reportStartDate, reportEndDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                title: 'Hospice Medication Dose Grid Report',
                patientName: patientName,
                reportStartDate: reportStartDate,
                reportEndDate: reportEndDate,
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Each table shows daily doses by medication for one calendar month. '
                'Multiple doses on the same day are shown as dose amounts joined with +.',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
      ),
    );

    for (final monthStart in months) {
      final monthWidgets = _buildMonthlyDoseGridSection(
        monthStart,
        medications,
        doseLogs,
        reportStartDate,
        reportEndDate,
      );
      if (monthWidgets == null) {
        continue;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          maxPages: 100,
          build: (pw.Context context) => monthWidgets,
        ),
      );
    }

    return pdf;
  }

  static List<DateTime> _monthsInRange(DateTime startDate, DateTime endDate) {
    final months = <DateTime>[];
    var year = startDate.year;
    var month = startDate.month;
    final endYear = endDate.year;
    final endMonth = endDate.month;

    while (year < endYear || (year == endYear && month <= endMonth)) {
      months.add(DateTime(year, month, 1));
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    return months;
  }

  static bool _doseInMonthAndRange(
    DoseLog log,
    DateTime monthStart,
    DateTime reportStartDate,
    DateTime reportEndDate,
  ) {
    if (log.dateTime.year != monthStart.year || log.dateTime.month != monthStart.month) {
      return false;
    }

    final rangeStart = DateTime(
      reportStartDate.year,
      reportStartDate.month,
      reportStartDate.day,
    );
    final rangeEnd = DateTime(
      reportEndDate.year,
      reportEndDate.month,
      reportEndDate.day,
      23,
      59,
      59,
      999,
    );
    return !log.dateTime.isBefore(rangeStart) && !log.dateTime.isAfter(rangeEnd);
  }

  static String _formatDoseAmount(double dose) {
    if (dose == dose.roundToDouble()) {
      return dose.toInt().toString();
    }
    return dose.toString();
  }

  static String _formatDayDoses(List<DoseLog> doses) {
    if (doses.isEmpty) {
      return '';
    }
    return doses.map((dose) => _formatDoseAmount(dose.doseGiven)).join('+');
  }

  static List<pw.Widget>? _buildMonthlyDoseGridSection(
    DateTime monthStart,
    List<Medication> medications,
    List<DoseLog> doseLogs,
    DateTime reportStartDate,
    DateTime reportEndDate,
  ) {
    final medicationMap = {for (final med in medications) med.id!: med};
    final dosesByMedicationAndDay = <int, Map<int, List<DoseLog>>>{};

    for (final log in doseLogs) {
      if (!_doseInMonthAndRange(log, monthStart, reportStartDate, reportEndDate)) {
        continue;
      }

      final day = log.dateTime.day;
      dosesByMedicationAndDay.putIfAbsent(log.medicationId, () => {});
      dosesByMedicationAndDay[log.medicationId]!
          .putIfAbsent(day, () => [])
          .add(log);
    }

    if (dosesByMedicationAndDay.isEmpty) {
      return null;
    }

    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final medicationIds = dosesByMedicationAndDay.keys.toList()
      ..sort((a, b) {
        final nameA = medicationMap[a]?.name ?? '';
        final nameB = medicationMap[b]?.name ?? '';
        return nameA.compareTo(nameB);
      });

    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2),
    };
    for (var day = 1; day <= daysInMonth; day++) {
      columnWidths[day] = const pw.FlexColumnWidth(0.35);
    }

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _buildGridCell('Medication', isHeader: true, alignLeft: true),
        ...List.generate(
          daysInMonth,
          (index) => _buildGridCell('${index + 1}', isHeader: true),
        ),
      ],
    );

    final dataRows = medicationIds.map((medicationId) {
      final medication = medicationMap[medicationId];
      final dosesByDay = dosesByMedicationAndDay[medicationId]!;
      final medicationLabel = medication == null
          ? 'Unknown'
          : '${medication.name} (${medication.form})';

      return pw.TableRow(
        children: [
          _buildGridCell(medicationLabel, alignLeft: true),
          ...List.generate(daysInMonth, (index) {
            final day = index + 1;
            final dayDoses = dosesByDay[day] ?? const <DoseLog>[];
            return _buildGridCell(_formatDayDoses(dayDoses));
          }),
        ],
      );
    }).toList();

    return [
      pw.Text(
        DateFormat('MMMM yyyy').format(monthStart),
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: columnWidths,
        children: [headerRow, ...dataRows],
      ),
    ];
  }

  static pw.Widget _buildGridCell(
    String text, {
    bool isHeader = false,
    bool alignLeft = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: isHeader ? 7 : 6,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<pw.Document> generateQuestionsReport(
    List<Question> questions, {
    String? patientName,
    required DateTime reportStartDate,
    required DateTime reportEndDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return _buildHeader(
            title: 'Hospice Questions Report',
            patientName: patientName,
            reportStartDate: reportStartDate,
            reportEndDate: reportEndDate,
          );
        },
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        maxPages: 100,
        build: (pw.Context context) {
          return [
            pw.Text(
              'Questions',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            _buildQuestionsTable(questions),
          ];
        },
      ),
    );

    return pdf;
  }

  static Future<pw.Document> generateNotesReport(
    List<Note> notes, {
    String? patientName,
    required DateTime reportStartDate,
    required DateTime reportEndDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return _buildHeader(
            title: 'Hospice Notes Report',
            patientName: patientName,
            reportStartDate: reportStartDate,
            reportEndDate: reportEndDate,
          );
        },
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        maxPages: 100,
        build: (pw.Context context) {
          return [
            pw.Text(
              'Notes',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            _buildNotesTable(notes),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader({
    required String title,
    String? patientName,
    DateTime? reportStartDate,
    DateTime? reportEndDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
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
        if (reportStartDate != null && reportEndDate != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Report period: ${DateFormat('MMM dd, yyyy').format(reportStartDate)} – ${DateFormat('MMM dd, yyyy').format(reportEndDate)}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
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

  static pw.Widget _buildDoseHistoryTable(
    List<DoseLog> doseLogs,
    List<Medication> medications, {
    bool hasDateRange = false,
  }) {
    final medicationMap = {for (var med in medications) med.id: med};

    if (doseLogs.isEmpty) {
      return pw.Text(
        hasDateRange
            ? 'No doses logged in the selected date range'
            : 'No doses logged yet',
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

  static pw.Widget _buildQuestionsTable(List<Question> questions) {
    if (questions.isEmpty) {
      return pw.Text(
        'No questions in the selected date range',
        style: pw.TextStyle(
          fontSize: 12,
          color: PdfColors.grey600,
        ),
      );
    }

    final headers = ['Title', 'Question', 'Date Entered', 'Status', 'Answer', 'Answered'];
    final data = questions.map((question) {
      return [
        question.title,
        question.questionText,
        DateFormat('MMM dd, yyyy').format(question.dateEntered),
        question.status,
        question.answer ?? '',
        question.answeredAt != null
            ? DateFormat('MMM dd, yyyy hh:mm a').format(question.answeredAt!)
            : '',
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
      cellStyle: const pw.TextStyle(
        fontSize: 9,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(1.3),
      },
    );
  }

  static pw.Widget _buildNotesTable(List<Note> notes) {
    if (notes.isEmpty) {
      return pw.Text(
        'No notes in the selected date range',
        style: pw.TextStyle(
          fontSize: 12,
          color: PdfColors.grey600,
        ),
      );
    }

    final headers = ['Title', 'Note', 'Created', 'Last Updated'];
    final data = notes.map((note) {
      return [
        note.title,
        note.body,
        DateFormat('MMM dd, yyyy hh:mm a').format(note.createdAt),
        DateFormat('MMM dd, yyyy hh:mm a').format(note.updatedAt),
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
      cellStyle: const pw.TextStyle(
        fontSize: 9,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
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
