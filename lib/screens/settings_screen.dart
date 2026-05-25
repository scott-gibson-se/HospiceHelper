import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/dose_log.dart';
import '../services/pdf_report_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _patientNameController = TextEditingController();
  late DateTime _reportFromDate;
  late DateTime _reportToDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _reportToDate = DateTime(now.year, now.month, now.day);
    _reportFromDate = _reportToDate.subtract(const Duration(days: 30));
    _loadSettings();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final patientName = await SettingsService.getPatientName();
    if (patientName != null) {
      _patientNameController.text = patientName;
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                    'Patient Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _patientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
                      hintText: 'Enter the patient\'s name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) async {
                      if (value.trim().isNotEmpty) {
                        await SettingsService.setPatientName(value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This name will be included in all generated reports.',
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
                    'Export & Reports',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.date_range),
                    title: const Text('From Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_reportFromDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickReportFromDate(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('To Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_reportToDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickReportToDate(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only dose history within this date range will be included in the report.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('Generate PDF Report'),
                    subtitle: const Text('Create a medication report for the selected dates'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _generatePdfReport,
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
                    'Data Management',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Clear All Medication and Dose Data'),
                    subtitle: const Text('Remove all medications and dose logs'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showClearDataDialog,
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
                    'App Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('About'),
                    subtitle: const Text('Hospice Medication Tracker'),
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
    final rangeStart = DateTime(
      _reportFromDate.year,
      _reportFromDate.month,
      _reportFromDate.day,
    );
    final rangeEnd = DateTime(
      _reportToDate.year,
      _reportToDate.month,
      _reportToDate.day,
      23,
      59,
      59,
      999,
    );

    return doseLogs.where((log) {
      return !log.dateTime.isBefore(rangeStart) && !log.dateTime.isAfter(rangeEnd);
    }).toList();
  }

  Future<void> _generatePdfReport() async {
    try {
      // Check if patient name is set
      final isPatientNameSet = await SettingsService.isPatientNameSet();
      if (!isPatientNameSet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set the patient name in settings before generating a report'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final provider = context.read<MedicationProvider>();
      final medications = provider.medications;
      final doseLogs = _filterDoseLogsByDateRange(provider.doseLogs);

      if (medications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No medications to generate report for')),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Use PdfReportService to save PDF to accessible Downloads directory
      final filePath = await PdfReportService.generateMedicationReportFile(
        medications,
        doseLogs,
        reportStartDate: _reportFromDate,
        reportEndDate: _reportToDate,
      );

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF report saved to: $filePath'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // You could add functionality to open the PDF here
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }


  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all medications and dose logs? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _clearAllData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final provider = context.read<MedicationProvider>();
      
      // Delete all medications (this will also delete associated dose logs due to foreign key constraints)
      for (final medication in provider.medications) {
        await provider.deleteMedication(medication.id!);
      }
      
      // Navigate back to home screen
      Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing data: $e')),
      );
    }
  }

}
