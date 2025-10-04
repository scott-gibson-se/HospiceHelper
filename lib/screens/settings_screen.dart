import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../services/email_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailController = TextEditingController();
  final _patientNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
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
          // Notification Testing Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Testing',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Test the notification system to verify it works:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  // Permission Status
                  FutureBuilder<Map<String, bool>>(
                    future: _getNotificationStatus(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      
                      final status = snapshot.data ?? {};
                      final notificationsEnabled = status['notifications'] ?? false;
                      final exactAlarmsEnabled = status['exactAlarms'] ?? false;
                      
                      return Column(
                        children: [
                          _buildStatusRow(
                            'Notifications',
                            notificationsEnabled,
                            'Required for all notifications',
                          ),
                          const SizedBox(height: 8),
                          _buildStatusRow(
                            'Exact Alarms',
                            exactAlarmsEnabled,
                            'Required for reliable scheduled notifications',
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await NotificationService().showTestNotification();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Test notification sent'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Test notification failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.notifications),
                          label: const Text('Test Immediate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await NotificationService().showTestScheduledNotification();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Test scheduled notification set for 10 seconds'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Test scheduled notification failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: const Text('Test Scheduled (10s)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If the immediate test works but scheduled doesn\'t, there may be Android background restrictions.',
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
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('Generate PDF Report'),
                    subtitle: const Text('Create a comprehensive medication report'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _generatePdfReport,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email Report'),
                    subtitle: const Text('Send medication report via email'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showEmailDialog,
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
                    title: const Text('Clear All Data'),
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
      final doseLogs = provider.doseLogs;

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

      // Use EmailService to save PDF to accessible Downloads directory
      final filePath = await EmailService.generateMedicationReportFile(medications, doseLogs);

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

  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Recipient Email',
                hintText: 'Enter email address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
              if (_emailController.text.isNotEmpty) {
                _sendEmailReport(_emailController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an email address')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmailReport(String email) async {
    try {
      // Check if patient name is set
      final isPatientNameSet = await SettingsService.isPatientNameSet();
      if (!isPatientNameSet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set the patient name in settings before sending a report'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final provider = context.read<MedicationProvider>();
      final medications = provider.medications;
      final doseLogs = provider.doseLogs;

      if (medications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No medications to send report for')),
        );
        return;
      }

      await EmailService.sendMedicationReport(medications, doseLogs, email);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email report sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: $e')),
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing data: $e')),
      );
    }
  }

  Future<Map<String, bool>> _getNotificationStatus() async {
    try {
      final notificationService = NotificationService();
      final notificationsEnabled = await notificationService.checkNotificationPermissions();
      final exactAlarmsEnabled = await notificationService.checkExactAlarmPermissions();
      
      return {
        'notifications': notificationsEnabled,
        'exactAlarms': exactAlarmsEnabled,
      };
    } catch (e) {
      return {
        'notifications': false,
        'exactAlarms': false,
      };
    }
  }

  Widget _buildStatusRow(String title, bool isEnabled, String description) {
    return Row(
      children: [
        Icon(
          isEnabled ? Icons.check_circle : Icons.cancel,
          color: isEnabled ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
