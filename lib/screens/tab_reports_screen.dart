import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/dose_log.dart';
import '../models/note.dart';
import '../models/question.dart';
import '../providers/medication_provider.dart';
import '../providers/note_provider.dart';
import '../providers/question_provider.dart';
import '../services/pdf_report_service.dart';
import '../services/settings_service.dart';
import '../utils/date_range_utils.dart';

enum ReportTab {
  medications,
  questions,
  notes,
}

class TabReportsScreen extends StatefulWidget {
  final ReportTab reportTab;

  const TabReportsScreen({
    super.key,
    required this.reportTab,
  });

  @override
  State<TabReportsScreen> createState() => _TabReportsScreenState();
}

class _TabReportsScreenState extends State<TabReportsScreen> {
  late DateTime _reportFromDate;
  late DateTime _reportToDate;

  @override
  void initState() {
    super.initState();
    _reportFromDate = DateRangeUtils.defaultFromDate();
    _reportToDate = DateRangeUtils.defaultToDate();
  }

  String get _screenTitle {
    switch (widget.reportTab) {
      case ReportTab.medications:
        return 'Medication Reports';
      case ReportTab.questions:
        return 'Question Reports';
      case ReportTab.notes:
        return 'Note Reports';
    }
  }

  String get _dateRangeHelpText {
    switch (widget.reportTab) {
      case ReportTab.medications:
        return 'Only dose history within this date range will be included in the report.';
      case ReportTab.questions:
        return 'Only questions entered within this date range will be included in the report.';
      case ReportTab.notes:
        return 'Only notes updated within this date range will be included in the report.';
    }
  }

  List<_ReportOption> get _availableReports {
    switch (widget.reportTab) {
      case ReportTab.medications:
        return [
          _ReportOption(
            title: 'Medication & Dose History Report',
            subtitle: 'Medication summary and dose history for the selected dates',
            icon: Icons.medication,
            onGenerate: _generateMedicationReport,
          ),
          _ReportOption(
            title: 'Medication Dose Grid Report',
            subtitle: 'Daily dose totals by medication, grouped by calendar month',
            icon: Icons.table_chart,
            onGenerate: _generateMedicationDoseGridReport,
          ),
        ];
      case ReportTab.questions:
        return [
          _ReportOption(
            title: 'Questions Report',
            subtitle: 'Questions and answers entered during the selected dates',
            icon: Icons.help_outline,
            onGenerate: _generateQuestionsReport,
          ),
        ];
      case ReportTab.notes:
        return [
          _ReportOption(
            title: 'Notes Report',
            subtitle: 'Notes updated during the selected dates',
            icon: Icons.note,
            onGenerate: _generateNotesReport,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Date Range',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.date_range),
                    title: const Text('From Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_reportFromDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickReportFromDate,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('To Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_reportToDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickReportToDate,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dateRangeHelpText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Reports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ..._availableReports.map(
                    (report) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(report.icon),
                      title: Text(report.title),
                      subtitle: Text(report.subtitle),
                      trailing: const Icon(Icons.picture_as_pdf),
                      onTap: report.onGenerate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReportFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reportFromDate,
      firstDate: DateTime(2020),
      lastDate: _reportToDate,
    );
    if (date != null) {
      setState(() {
        _reportFromDate = DateTime(date.year, date.month, date.day);
      });
    }
  }

  Future<void> _pickReportToDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reportToDate,
      firstDate: _reportFromDate,
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _reportToDate = DateTime(date.year, date.month, date.day);
      });
    }
  }

  List<DoseLog> _filterDoseLogsByDateRange(List<DoseLog> doseLogs) {
    return doseLogs
        .where((log) => DateRangeUtils.isInRange(log.dateTime, _reportFromDate, _reportToDate))
        .toList();
  }

  List<Question> _filterQuestionsByDateRange(List<Question> questions) {
    return questions
        .where((question) => DateRangeUtils.isInRange(question.dateEntered, _reportFromDate, _reportToDate))
        .toList();
  }

  List<Note> _filterNotesByDateRange(List<Note> notes) {
    return notes
        .where((note) => DateRangeUtils.isInRange(note.updatedAt, _reportFromDate, _reportToDate))
        .toList();
  }

  Future<bool> _ensurePatientNameSet() async {
    final isPatientNameSet = await SettingsService.isPatientNameSet();
    if (!isPatientNameSet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set the patient name in settings before generating a report'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return isPatientNameSet;
  }

  Future<void> _runReportGeneration({
    required Future<String> Function() generate,
  }) async {
    if (!await _ensurePatientNameSet()) {
      return;
    }

    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final filePath = await generate();
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF report saved to: $filePath')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  Future<void> _generateMedicationReport() async {
    final provider = context.read<MedicationProvider>();
    if (provider.medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medications to generate report for')),
      );
      return;
    }

    final doseLogs = _filterDoseLogsByDateRange(provider.doseLogs);
    await _runReportGeneration(
      generate: () => PdfReportService.generateMedicationReportFile(
        provider.medications,
        doseLogs,
        reportStartDate: _reportFromDate,
        reportEndDate: _reportToDate,
      ),
    );
  }

  Future<void> _generateMedicationDoseGridReport() async {
    final provider = context.read<MedicationProvider>();
    if (provider.medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medications to generate report for')),
      );
      return;
    }

    final doseLogs = _filterDoseLogsByDateRange(provider.doseLogs);
    if (doseLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No doses in the selected date range')),
      );
      return;
    }

    await _runReportGeneration(
      generate: () => PdfReportService.generateMedicationDoseGridReportFile(
        provider.medications,
        doseLogs,
        reportStartDate: _reportFromDate,
        reportEndDate: _reportToDate,
      ),
    );
  }

  Future<void> _generateQuestionsReport() async {
    final provider = context.read<QuestionProvider>();
    final questions = _filterQuestionsByDateRange(provider.questions);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions in the selected date range')),
      );
      return;
    }

    await _runReportGeneration(
      generate: () => PdfReportService.generateQuestionsReportFile(
        questions,
        reportStartDate: _reportFromDate,
        reportEndDate: _reportToDate,
      ),
    );
  }

  Future<void> _generateNotesReport() async {
    final provider = context.read<NoteProvider>();
    final notes = _filterNotesByDateRange(provider.notes);
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes in the selected date range')),
      );
      return;
    }

    await _runReportGeneration(
      generate: () => PdfReportService.generateNotesReportFile(
        notes,
        reportStartDate: _reportFromDate,
        reportEndDate: _reportToDate,
      ),
    );
  }
}

class _ReportOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Future<void> Function() onGenerate;

  const _ReportOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onGenerate,
  });
}
