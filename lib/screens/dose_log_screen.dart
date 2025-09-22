import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/dose_log.dart';
import '../models/medication.dart';

class DoseLogScreen extends StatefulWidget {
  const DoseLogScreen({super.key});

  @override
  State<DoseLogScreen> createState() => _DoseLogScreenState();
}

class _DoseLogScreenState extends State<DoseLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadDoseLogs();
    });
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
              return FutureBuilder<Medication?>(
                future: _getMedicationForDoseLog(provider, doseLog),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Loading...'),
                      ),
                    );
                  }

                  final medication = snapshot.data;
                  if (medication == null) {
                    return Card(
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
          );
        },
      ),
    );
  }

  Future<Medication?> _getMedicationForDoseLog(MedicationProvider provider, DoseLog doseLog) async {
    try {
      return await provider.getMedication(doseLog.medicationId);
    } catch (e) {
      return null;
    }
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
            onPressed: () {
              context.read<MedicationProvider>().deleteDoseLog(doseLog.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dose log deleted successfully')),
              );
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

  void _showDoseDialog({
    required BuildContext context,
    required String title,
    required DoseLog? doseLog,
    required List<Medication> medications,
  }) {
    final doseController = TextEditingController(text: doseLog?.doseGiven.toString() ?? '');
    final givenByController = TextEditingController(text: doseLog?.givenBy ?? '');
    final noteController = TextEditingController(text: doseLog?.note ?? '');
    DateTime selectedDateTime = doseLog?.dateTime ?? DateTime.now();
    Medication? selectedMedication = doseLog != null 
        ? medications.firstWhere((m) => m.id == doseLog.medicationId)
        : medications.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medication selection
                DropdownButtonFormField<Medication>(
                  value: selectedMedication,
                  decoration: const InputDecoration(
                    labelText: 'Medication',
                    border: OutlineInputBorder(),
                  ),
                  items: medications.map((medication) {
                    return DropdownMenuItem(
                      value: medication,
                      child: Text(medication.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMedication = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Date and time selection
                ListTile(
                  title: const Text('Date & Time'),
                  subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(selectedDateTime)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Dose amount
                TextFormField(
                  controller: doseController,
                  decoration: InputDecoration(
                    labelText: 'Dose Amount',
                    suffixText: selectedMedication?.form ?? '',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a dose amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Given by
                TextFormField(
                  controller: givenByController,
                  decoration: const InputDecoration(
                    labelText: 'Given By',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter who gave the dose';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Note
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMedication == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a medication')),
                  );
                  return;
                }

                final doseAmount = double.tryParse(doseController.text);
                if (doseAmount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid dose amount')),
                  );
                  return;
                }

                if (givenByController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter who gave the dose')),
                  );
                  return;
                }

                final newDoseLog = DoseLog(
                  id: doseLog?.id,
                  medicationId: selectedMedication!.id!,
                  dateTime: selectedDateTime,
                  doseGiven: doseAmount,
                  givenBy: givenByController.text,
                  note: noteController.text.isEmpty ? null : noteController.text,
                  createdAt: doseLog?.createdAt ?? DateTime.now(),
                );

                if (doseLog == null) {
                  // Adding new dose
                  context.read<MedicationProvider>().logDose(newDoseLog);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dose logged successfully')),
                  );
                } else {
                  // Editing existing dose
                  context.read<MedicationProvider>().updateDoseLog(newDoseLog);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dose updated successfully')),
                  );
                }

                Navigator.pop(context);
              },
              child: Text(doseLog == null ? 'Add Dose' : 'Update Dose'),
            ),
          ],
        ),
      ),
    );
  }
}
