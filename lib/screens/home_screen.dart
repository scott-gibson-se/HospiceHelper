import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/question_provider.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import 'add_medication_screen.dart';
import 'medication_detail_screen.dart';
import 'dose_log_screen.dart';
import 'settings_screen.dart';
import 'questions_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadMedications();
      context.read<MedicationProvider>().loadDoseLogs();
      context.read<QuestionProvider>().loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospice Medication Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuestionsListScreen(),
                ),
              );
              // Refresh questions when returning
              if (mounted) {
                context.read<QuestionProvider>().loadQuestions();
              }
            },
            tooltip: 'Questions',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await context.read<MedicationProvider>().loadMedications();
              await context.read<MedicationProvider>().loadDoseLogs();
              await context.read<QuestionProvider>().loadQuestions();
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoseLogScreen(),
                ),
              );
            },
            tooltip: 'View Dose History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer2<MedicationProvider, QuestionProvider>(
        builder: (context, medicationProvider, questionProvider, child) {
          if (medicationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (medicationProvider.medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medications added yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first medication',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await medicationProvider.loadMedications();
              await medicationProvider.loadDoseLogs();
              await questionProvider.loadQuestions();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Questions Summary Card
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: questionProvider.unansweredCount > 0 
                          ? Colors.orange.shade100 
                          : Colors.green.shade100,
                      child: Icon(
                        Icons.help_outline,
                        color: questionProvider.unansweredCount > 0 
                            ? Colors.orange.shade700 
                            : Colors.green.shade700,
                      ),
                    ),
                    title: const Text(
                      'Questions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${questionProvider.unansweredCount} pending, ${questionProvider.answeredCount} answered',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuestionsListScreen(),
                        ),
                      );
                      // Refresh questions when returning
                      if (mounted) {
                        context.read<QuestionProvider>().loadQuestions();
                      }
                    },
                  ),
                ),
                // Medications List
                ...medicationProvider.medications.map((medication) {
                  final isDue = medicationProvider.isMedicationDue(medication);
                  final timeUntilNext = medicationProvider.getTimeUntilNextDose(medication);
                  final lastDose = medicationProvider.doseLogs
                      .where((d) => d.medicationId == medication.id)
                      .isNotEmpty
                      ? medicationProvider.doseLogs
                          .where((d) => d.medicationId == medication.id)
                          .reduce((a, b) => a.dateTime.isAfter(b.dateTime) ? a : b)
                      : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDue 
                            ? Colors.red[100] 
                            : Colors.green[100],
                        child: Icon(
                          Icons.medication,
                          color: isDue ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Text(
                        medication.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${medication.form} • Max: ${medication.maxDosage} • Interval: ${medication.formattedTimeInterval}'),
                          if (lastDose != null)
                            Text(
                              'Last dose: ${lastDose.doseGiven} ${medication.form}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          if (timeUntilNext != null)
                            Text(
                              'Next dose in: ${_formatDuration(timeUntilNext)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            )
                          else if (isDue)
                            Text(
                              'Due now!',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDue)
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => _showLogDoseDialog(context, medication),
                              tooltip: 'Log Dose',
                            ),
                          IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicationDetailScreen(medication: medication),
                                ),
                              );
                            },
                            tooltip: 'View Details',
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicationDetailScreen(medication: medication),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicationScreen(),
            ),
          );
        },
        tooltip: 'Add Medication',
        child: const Icon(Icons.add),
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
