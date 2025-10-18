import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import 'edit_medication_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailScreen({
    super.key,
    required this.medication,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  List<DoseLog> _doseLogs = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDoseLogs();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh state when dependencies change (e.g., medication data updates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshState();
      }
    });
  }

  Future<void> _loadDoseLogs() async {
    final provider = context.read<MedicationProvider>();
    final logs = await provider.getDoseLogsForMedication(widget.medication.id!);
    setState(() {
      _doseLogs = logs;
    });
  }

  Future<void> _refreshState() async {
    // Reload dose logs to get the latest data
    await _loadDoseLogs();
    // Force a rebuild to update computed values
    if (mounted) {
      setState(() {});
    }
  }

  void _startRefreshTimer() {
    // Refresh every minute to update computed values based on time
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        // Only refresh the computed values, not the dose logs
        setState(() {});
      }
    });
  }


  double _getTotalDosesInLastInterval(Medication medication) {
    if (_doseLogs.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final intervalStart = now.subtract(Duration(minutes: medication.minTimeBetweenDoses));
    
    return _doseLogs
        .where((log) => log.dateTime.isAfter(intervalStart))
        .fold(0.0, (sum, log) => sum + log.doseGiven);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<MedicationProvider>(
          builder: (context, provider, child) {
            final currentMedication = provider.medications.firstWhere(
              (med) => med.id == widget.medication.id,
              orElse: () => widget.medication,
            );
            return Text(currentMedication.name);
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditMedicationScreen(medication: widget.medication),
                ),
              );
              // Refresh the medication data and dose logs
              if (mounted) {
                await _refreshState();
              }
            },
            tooltip: 'Edit Medication',
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          // Get the current medication from the provider
          final currentMedication = provider.medications.firstWhere(
            (med) => med.id == widget.medication.id,
            orElse: () => widget.medication,
          );
          
          final isDue = provider.isMedicationDue(currentMedication);
          final timeUntilNext = provider.getTimeUntilNextDose(currentMedication);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Medication Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medication,
                            size: 32,
                            color: isDue ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentMedication.name,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  currentMedication.officialName,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Form', currentMedication.form),
                      _buildInfoRow('Max Dosage', '${currentMedication.maxDosage} ${currentMedication.form}'),
                      _buildInfoRow('Min Time Between Doses', currentMedication.formattedTimeInterval),
                      _buildInfoRow('Notifications', currentMedication.notificationsEnabled ? 'Enabled' : 'Disabled'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Card
              Card(
                color: isDue ? Colors.red[50] : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDue ? Icons.warning : Icons.check_circle,
                            color: isDue ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isDue ? 'Due for Next Dose' : 'Up to Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDue ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (timeUntilNext != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Next dose in: ${_formatDuration(timeUntilNext)}',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Total doses in last ${currentMedication.formattedTimeInterval}: ${_getTotalDosesInLastInterval(currentMedication).toStringAsFixed(3)} ${currentMedication.form}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions
              Builder(
                builder: (context) {
                  final totalDosesInInterval = _getTotalDosesInLastInterval(currentMedication);
                  final canLogDose = totalDosesInInterval < currentMedication.maxDosage;
                  final shouldShowQuickActions = isDue || canLogDose;
                  
                  if (!shouldShowQuickActions) return const SizedBox.shrink();
                  
                  return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final totalDosesInInterval = _getTotalDosesInLastInterval(currentMedication);
                            final canLogDose = totalDosesInInterval < currentMedication.maxDosage;
                            
                            
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: canLogDose ? () => _showLogDoseDialog(context, currentMedication) : null,
                                icon: const Icon(Icons.add_circle),
                                label: Text(canLogDose ? 'Log Dose' : 'Max Dosage Reached'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canLogDose ? Colors.green : Colors.grey,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final totalDosesInInterval = _getTotalDosesInLastInterval(currentMedication);
                            final canLogDose = totalDosesInInterval < currentMedication.maxDosage;
                            
                            if (!canLogDose) {
                              return Text(
                                'Maximum dosage (${currentMedication.maxDosage} ${currentMedication.form}) reached for this time interval.',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }
                            
                            return Text(
                              'Current total: ${totalDosesInInterval.toStringAsFixed(3)} ${currentMedication.form} / ${currentMedication.maxDosage} ${currentMedication.form}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
                },
              ),
              const SizedBox(height: 16),

              // Dose History
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dose History',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: _loadDoseLogs,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_doseLogs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No doses logged yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _doseLogs.length,
                          itemBuilder: (context, index) {
                            final log = _doseLogs[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: const Icon(Icons.medication, color: Colors.blue),
                              ),
                              title: Text('${log.doseGiven} ${currentMedication.form}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Given by: ${log.givenBy}'),
                                  Text(
                                    DateFormat('MMM dd, yyyy - hh:mm a').format(log.dateTime),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (log.note != null && log.note!.isNotEmpty)
                                    Text(
                                      'Note: ${log.note}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  void _showLogDoseDialog(BuildContext context, Medication medication) {
    final doseController = TextEditingController();
    final givenByController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Log Dose - ${medication.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: doseController,
                  decoration: InputDecoration(
                    labelText: 'Dose Given',
                    hintText: 'Enter amount',
                    suffixText: medication.form,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: givenByController,
                  decoration: const InputDecoration(
                    labelText: 'Given By',
                    hintText: 'Who administered the dose?',
                  ),
                ),
                const SizedBox(height: 16),
                // Date and Time Selection
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Date'),
                        subtitle: Text(
                          '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                selectedDateTime.hour,
                                selectedDateTime.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ListTile(
                        title: const Text('Time'),
                        subtitle: Text(
                          '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                selectedDateTime.year,
                                selectedDateTime.month,
                                selectedDateTime.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'Any additional notes...',
                  ),
                  maxLines: 2,
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
                final dose = double.tryParse(doseController.text);
                if (dose != null && dose > 0 && givenByController.text.isNotEmpty) {
                  context.read<MedicationProvider>().logDose(
                    DoseLog(
                      medicationId: medication.id!,
                      dateTime: selectedDateTime,
                      doseGiven: dose,
                      givenBy: givenByController.text,
                      note: noteController.text.isNotEmpty ? noteController.text : null,
                      createdAt: DateTime.now(),
                    ),
                  );
                  Navigator.pop(context);
                  _refreshState(); // Refresh the dose logs and computed values
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dose logged successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid dose and who gave it')),
                  );
                }
              },
              child: const Text('Log Dose'),
            ),
          ],
        ),
      ),
    );
  }
}
