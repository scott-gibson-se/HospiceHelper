import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/dose_log.dart';
import '../models/medication.dart';
import '../utils/date_range_utils.dart';
import 'log_dose_screen.dart';

class DoseLogScreen extends StatefulWidget {
  const DoseLogScreen({super.key});

  @override
  State<DoseLogScreen> createState() => _DoseLogScreenState();
}

class _DoseLogScreenState extends State<DoseLogScreen> {
  Map<int, Medication> _medicationCache = {};
  late DateTime _fromDate;
  late DateTime _toDate;
  late TimeOfDay _fromTime;
  late TimeOfDay _toTime;
  int? _selectedMedicationId;

  @override
  void initState() {
    super.initState();
    _fromDate = DateRangeUtils.defaultLastWeekFromDate();
    _toDate = DateRangeUtils.defaultToDate();
    _fromTime = const TimeOfDay(hour: 0, minute: 0);
    _toTime = const TimeOfDay(hour: 23, minute: 59);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<MedicationProvider>();
    await provider.loadMedications();
    await provider.loadDoseLogs();
    await _preloadMedications(provider);
  }

  Future<void> _preloadMedications(MedicationProvider provider) async {
    final medicationIds = {
      ...provider.doseLogs.map((log) => log.medicationId),
      ...provider.medications.map((med) => med.id!),
    };

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

  List<DoseLog> _filterDoseLogs(List<DoseLog> doseLogs) {
    return doseLogs.where((log) {
      if (!DateRangeUtils.isInRange(log.dateTime, _fromDate, _toDate)) {
        return false;
      }
      if (!DateRangeUtils.isTimeOfDayInRange(
        log.dateTime,
        _fromTime.hour,
        _fromTime.minute,
        _toTime.hour,
        _toTime.minute,
      )) {
        return false;
      }
      if (_selectedMedicationId != null &&
          log.medicationId != _selectedMedicationId) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate,
    );
    if (date != null) {
      setState(() {
        _fromDate = DateTime(date.year, date.month, date.day);
      });
    }
  }

  Future<void> _pickToDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _toDate = DateTime(date.year, date.month, date.day);
      });
    }
  }

  Future<void> _pickFromTime() async {
    final time = await showTimePicker(context: context, initialTime: _fromTime);
    if (time != null) {
      setState(() => _fromTime = time);
    }
  }

  Future<void> _pickToTime() async {
    final time = await showTimePicker(context: context, initialTime: _toTime);
    if (time != null) {
      setState(() => _toTime = time);
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('h:mm a').format(dateTime);
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
          final filteredLogs = _filterDoseLogs(provider.doseLogs);

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight < 120) {
                return _buildDoseList(filteredLogs, provider.doseLogs.isEmpty);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterPanel(provider),
                  Expanded(
                    child: _buildDoseList(
                      filteredLogs,
                      provider.doseLogs.isEmpty,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(MedicationProvider provider) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 360;
                final dateFrom = _buildFilterTile(
                  icon: Icons.date_range,
                  label: 'From Date',
                  value: DateFormat('MMM dd, yyyy').format(_fromDate),
                  onTap: _pickFromDate,
                );
                final dateTo = _buildFilterTile(
                  icon: Icons.event,
                  label: 'To Date',
                  value: DateFormat('MMM dd, yyyy').format(_toDate),
                  onTap: _pickToDate,
                );
                if (narrow) {
                  return Column(children: [dateFrom, dateTo]);
                }
                return Row(
                  children: [
                    Expanded(child: dateFrom),
                    const SizedBox(width: 8),
                    Expanded(child: dateTo),
                  ],
                );
              },
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 360;
                final timeFrom = _buildFilterTile(
                  icon: Icons.access_time,
                  label: 'From Time',
                  value: _formatTime(_fromTime),
                  onTap: _pickFromTime,
                );
                final timeTo = _buildFilterTile(
                  icon: Icons.schedule,
                  label: 'To Time',
                  value: _formatTime(_toTime),
                  onTap: _pickToTime,
                );
                if (narrow) {
                  return Column(children: [timeFrom, timeTo]);
                }
                return Row(
                  children: [
                    Expanded(child: timeFrom),
                    const SizedBox(width: 8),
                    Expanded(child: timeTo),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<int?>(
              value: _selectedMedicationId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Medication',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All medications'),
                ),
                ...provider.medications.map(
                  (med) => DropdownMenuItem<int?>(
                    value: med.id,
                    child: Text(med.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedMedicationId = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseList(List<DoseLog> filteredLogs, bool hasNoDoseLogs) {
    if (hasNoDoseLogs) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No doses logged yet',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Doses will appear here once they are logged',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No doses match filters',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting the date, time, or medication filters',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final doseLog = filteredLogs[index];
        final medication = _medicationCache[doseLog.medicationId];

        if (medication == null) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              isThreeLine: true,
              leading: const Icon(Icons.error, color: Colors.red),
              title: const Text('Unknown Medication'),
              subtitle: Text(
                'Dose logged on ${DateFormat('MMM dd, yyyy - hh:mm a').format(doseLog.dateTime)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            isThreeLine: true,
            leading: CircleAvatar(
              backgroundColor: _getMedicationColor(medication),
              child: const Icon(Icons.medication, color: Colors.white),
            ),
            title: Text(
              medication.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${doseLog.doseGiven} ${medication.form}',
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Given by: ${doseLog.givenBy}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(doseLog.dateTime),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (doseLog.note != null && doseLog.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Note: ${doseLog.note}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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
  }

  Color _getMedicationColor(Medication medication) {
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
                  const SnackBar(
                    content: Text('Dose log deleted successfully'),
                  ),
                );
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

  void _showEditDoseDialog(
    BuildContext context,
    DoseLog doseLog,
    Medication medication,
  ) {
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
