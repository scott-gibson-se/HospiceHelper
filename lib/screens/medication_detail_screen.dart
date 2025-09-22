import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import '../services/notification_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDoseLogs();
  }

  Future<void> _loadDoseLogs() async {
    final provider = context.read<MedicationProvider>();
    final logs = await provider.getDoseLogsForMedication(widget.medication.id!);
    setState(() {
      _doseLogs = logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditMedicationScreen(medication: widget.medication),
                ),
              ).then((_) {
                // Refresh the medication data
                setState(() {});
              });
            },
            tooltip: 'Edit Medication',
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          final isDue = provider.isMedicationDue(widget.medication);
          final timeUntilNext = provider.getTimeUntilNextDose(widget.medication);

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
                                  widget.medication.name,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  widget.medication.officialName,
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
                      _buildInfoRow('Form', widget.medication.form),
                      _buildInfoRow('Max Dosage', '${widget.medication.maxDosage} ${widget.medication.form}'),
                      _buildInfoRow('Min Time Between Doses', '${widget.medication.minTimeBetweenDoses} minutes'),
                      _buildInfoRow('Notifications', widget.medication.notificationsEnabled ? 'Enabled' : 'Disabled'),
                      if (widget.medication.notificationsEnabled)
                        _buildInfoRow('Notification Sound', NotificationService.getSoundDescription(widget.medication.notificationSound)),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions
              if (isDue)
                Card(
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showLogDoseDialog(context, widget.medication),
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Log Dose'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                              title: Text('${log.doseGiven} ${widget.medication.form}'),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Dose - ${medication.name}'),
        content: Column(
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
                    dateTime: DateTime.now(),
                    doseGiven: dose,
                    givenBy: givenByController.text,
                    note: noteController.text.isNotEmpty ? noteController.text : null,
                    createdAt: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
                _loadDoseLogs(); // Refresh the dose logs
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
    );
  }
}
