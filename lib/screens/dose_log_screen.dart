import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/dose_log.dart';
import '../models/medication.dart';
import 'log_dose_screen.dart';

class DoseLogScreen extends StatefulWidget {
  const DoseLogScreen({super.key});

  @override
  State<DoseLogScreen> createState() => _DoseLogScreenState();
}

class _DoseLogScreenState extends State<DoseLogScreen> {
  Map<int, Medication> _medicationCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<MedicationProvider>();
    await provider.loadDoseLogs();
    
    // Pre-load medication data to avoid async lookups during scrolling
    await _preloadMedications(provider);
  }

  Future<void> _preloadMedications(MedicationProvider provider) async {
    final medicationIds = provider.doseLogs.map((log) => log.medicationId).toSet();
    
    for (final id in medicationIds) {
      if (!_medicationCache.containsKey(id)) {
        try {
          final medication = await provider.getMedication(id);
          if (medication != null) {
            _medicationCache[id] = medication;
          }
        } catch (e) {
          // Handle error silently, will show as unknown medication
        }
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dose History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDoseDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.doseLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No doses logged yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Doses will appear here once they are logged',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.doseLogs.length,
            itemBuilder: (context, index) {
              final doseLog = provider.doseLogs[index];
              final medication = _medicationCache[doseLog.medicationId];
              
              if (medication == null) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Unknown Medication'),
                    subtitle: Text('Dose logged on ${DateFormat('MMM dd, yyyy - hh:mm a').format(doseLog.dateTime)}'),
                  ),
                );
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getMedicationColor(medication),
                    child: const Icon(Icons.medication, color: Colors.white),
                  ),
                  title: Text(
                    medication.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${doseLog.doseGiven} ${medication.form}'),
                      Text(
                        'Given by: ${doseLog.givenBy}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy - hh:mm a').format(doseLog.dateTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (doseLog.note != null && doseLog.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Note: ${doseLog.note}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDoseDialog(context, doseLog, medication);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, doseLog);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }


  Color _getMedicationColor(Medication medication) {
    // Generate a consistent color based on medication name
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];
    final index = medication.name.hashCode % colors.length;
    return colors[index];
  }

  void _showDeleteConfirmation(BuildContext context, DoseLog doseLog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dose Log'),
        content: const Text(
          'Are you sure you want to delete this dose log? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              context.read<MedicationProvider>().deleteDoseLog(doseLog.id!);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dose log deleted successfully')),
                );
                // Refresh the medication cache after deletion
                await _preloadMedications(context.read<MedicationProvider>());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDoseDialog(BuildContext context) {
    final provider = context.read<MedicationProvider>();
    if (provider.medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a medication first before logging a dose'),
        ),
      );
      return;
    }

    _showDoseDialog(
      context: context,
      title: 'Add New Dose',
      doseLog: null,
      medications: provider.medications,
    );
  }

  void _showEditDoseDialog(BuildContext context, DoseLog doseLog, Medication medication) {
    final provider = context.read<MedicationProvider>();
    _showDoseDialog(
      context: context,
      title: 'Edit Dose',
      doseLog: doseLog,
      medications: provider.medications,
    );
  }

  Future<void> _showDoseDialog({
    required BuildContext context,
    required String title,
    required DoseLog? doseLog,
    required List<Medication> medications,
  }) async {
    final saved = await LogDoseScreen.showForDoseEntry(
      context,
      title: title,
      medications: medications,
      doseLog: doseLog,
    );
    if (saved == true && mounted) {
      await _preloadMedications(context.read<MedicationProvider>());
    }
  }
}
