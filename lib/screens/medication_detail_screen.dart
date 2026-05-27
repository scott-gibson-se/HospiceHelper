import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import 'edit_medication_screen.dart';
import 'log_dose_screen.dart';

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
  bool _doseHistoryLoaded = false;
  bool _doseHistoryLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
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
    setState(() {
      _doseHistoryLoading = true;
    });

    final provider = context.read<MedicationProvider>();
    final logs = await provider.getDoseLogsForMedication(widget.medication.id!);
    if (!mounted) {
      return;
    }

    setState(() {
      _doseLogs = logs;
      _doseHistoryLoaded = true;
      _doseHistoryLoading = false;
    });
  }

  Future<void> _refreshState() async {
    if (_doseHistoryLoaded) {
      await _loadDoseLogs();
    } else if (mounted) {
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


  double _getTotalDosesInLastInterval(Medication medication, List<DoseLog> doseLogs) {
    final medicationLogs = doseLogs.where((log) => log.medicationId == medication.id);
    if (medicationLogs.isEmpty) return 0.0;

    final now = DateTime.now();
    final intervalStart = now.subtract(Duration(minutes: medication.minTimeBetweenDoses));

    return medicationLogs
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
                        'Total doses in last ${currentMedication.formattedTimeInterval}: ${_getTotalDosesInLastInterval(currentMedication, provider.doseLogs).toStringAsFixed(3)} ${currentMedication.form}',
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
                  final totalDosesInInterval = _getTotalDosesInLastInterval(
                    currentMedication,
                    provider.doseLogs,
                  );
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
                            final totalDosesInInterval = _getTotalDosesInLastInterval(
                    currentMedication,
                    provider.doseLogs,
                  );
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
                            final totalDosesInInterval = _getTotalDosesInLastInterval(
                    currentMedication,
                    provider.doseLogs,
                  );
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
                          if (_doseHistoryLoaded)
                            TextButton(
                              onPressed: _doseHistoryLoading ? null : _loadDoseLogs,
                              child: const Text('Refresh'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!_doseHistoryLoaded)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _doseHistoryLoading ? null : _loadDoseLogs,
                            icon: _doseHistoryLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.history),
                            label: Text(
                              _doseHistoryLoading ? 'Loading...' : 'Load Dose History',
                            ),
                          ),
                        )
                      else if (_doseLogs.isEmpty)
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

  Future<void> _showLogDoseDialog(BuildContext context, Medication medication) async {
    final saved = await LogDoseScreen.showForMedication(context, medication: medication);
    if (saved == true && mounted) {
      if (_doseHistoryLoaded) {
        await _loadDoseLogs();
      } else {
        setState(() {});
      }
    }
  }
}
