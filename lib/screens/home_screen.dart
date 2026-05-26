import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../providers/question_provider.dart';
import '../providers/note_provider.dart';
import '../models/medication.dart';
import '../models/question.dart';
import '../models/note.dart';
import 'add_medication_screen.dart';
import 'medication_detail_screen.dart';
import 'dose_log_screen.dart';
import 'log_dose_screen.dart';
import 'settings_screen.dart';
import 'add_question_screen.dart';
import 'question_detail_screen.dart';
import 'add_note_screen.dart';
import 'note_detail_screen.dart';
import 'tab_reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late TabController _questionsTabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _questionsTabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to update FAB
    });
    _questionsTabController.addListener(() {
      setState(() {}); // Rebuild when questions filter tab changes
    });
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadMedications();
      context.read<MedicationProvider>().loadDoseLogs();
      context.read<QuestionProvider>().loadQuestions();
      context.read<NoteProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _questionsTabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh medications and dose logs when app becomes active
      context.read<MedicationProvider>().loadMedications();
      context.read<MedicationProvider>().loadDoseLogs();
      context.read<QuestionProvider>().loadQuestions();
      context.read<NoteProvider>().loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospice Helper'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Medications',
              icon: Icon(Icons.medication),
            ),
            Tab(
              text: 'Questions',
              icon: Icon(Icons.help_outline),
            ),
            Tab(
              text: 'Notes',
              icon: Icon(Icons.note),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await context.read<MedicationProvider>().loadMedications();
              await context.read<MedicationProvider>().loadDoseLogs();
              await context.read<QuestionProvider>().loadQuestions();
              await context.read<NoteProvider>().loadNotes();
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicationsTab(),
          _buildQuestionsTab(),
          _buildNotesTab(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_fab',
            tooltip: _addFabTooltip,
            onPressed: _onAddPressed,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'reports_fab',
            tooltip: _reportsFabTooltip,
            onPressed: _openReportsScreen,
            child: const Icon(Icons.assessment),
          ),
        ],
      ),
    );
  }

  String get _addFabTooltip {
    switch (_tabController.index) {
      case 0:
        return 'Add Medication';
      case 1:
        return 'Add Question';
      default:
        return 'Add Note';
    }
  }

  String get _reportsFabTooltip {
    switch (_tabController.index) {
      case 0:
        return 'Medication Reports';
      case 1:
        return 'Question Reports';
      default:
        return 'Note Reports';
    }
  }

  ReportTab get _currentReportTab {
    switch (_tabController.index) {
      case 0:
        return ReportTab.medications;
      case 1:
        return ReportTab.questions;
      default:
        return ReportTab.notes;
    }
  }

  Future<void> _onAddPressed() async {
    if (_tabController.index == 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddMedicationScreen(),
        ),
      );
      if (mounted) {
        context.read<MedicationProvider>().loadMedications();
      }
    } else if (_tabController.index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddQuestionScreen(),
        ),
      );
      if (mounted) {
        context.read<QuestionProvider>().loadQuestions();
      }
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddNoteScreen(),
        ),
      );
      if (mounted) {
        context.read<NoteProvider>().loadNotes();
      }
    }
  }

  void _openReportsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TabReportsScreen(reportTab: _currentReportTab),
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
    LogDoseScreen.showForMedication(context, medication: medication);
  }

  Widget _buildMedicationsTab() {
    return Consumer<MedicationProvider>(
      builder: (context, medicationProvider, child) {
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
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicationProvider.medications.length,
            itemBuilder: (context, index) {
              final medication = medicationProvider.medications[index];
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
            },
          ),
        );
      },
    );
  }

  Widget _buildQuestionsTab() {
    return Consumer<QuestionProvider>(
      builder: (context, questionProvider, child) {
        if (questionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Sub-tabs for filtering questions
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _questionsTabController,
                tabs: const [
                  Tab(
                    text: 'All',
                    icon: Icon(Icons.list),
                  ),
                  Tab(
                    text: 'Pending',
                    icon: Icon(Icons.pending),
                  ),
                  Tab(
                    text: 'Answered',
                    icon: Icon(Icons.check_circle),
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _questionsTabController,
                children: [
                  _buildQuestionsList(questionProvider.questions, questionProvider),
                  _buildQuestionsList(questionProvider.unansweredQuestions, questionProvider),
                  _buildQuestionsList(questionProvider.answeredQuestions, questionProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionsList(List<Question> questions, QuestionProvider questionProvider) {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No questions found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new question',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => questionProvider.loadQuestions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return _buildQuestionCard(question);
        },
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: question.isAnswered 
              ? Colors.green.shade100 
              : Colors.orange.shade100,
          child: Icon(
            question.isAnswered ? Icons.check : Icons.help_outline,
            color: question.isAnswered 
                ? Colors.green.shade700 
                : Colors.orange.shade700,
          ),
        ),
        title: Text(
          question.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              question.questionText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(question.dateEntered),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: question.isAnswered 
                        ? Colors.green.shade100 
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: question.isAnswered 
                          ? Colors.green.shade700 
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QuestionDetailScreen(question: question),
            ),
          );
          // Refresh questions when returning from detail screen
          if (mounted) {
            context.read<QuestionProvider>().loadQuestions();
          }
        },
      ),
    );
  }

  Widget _buildNotesTab() {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        if (noteProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (noteProvider.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notes added yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first note',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => noteProvider.loadNotes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: noteProvider.notes.length,
            itemBuilder: (context, index) {
              final note = noteProvider.notes[index];
              return _buildNoteCard(note);
            },
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: note.isModified 
              ? Colors.blue.shade100 
              : Colors.green.shade100,
          child: Icon(
            note.isModified ? Icons.edit : Icons.note,
            color: note.isModified 
                ? Colors.blue.shade700 
                : Colors.green.shade700,
          ),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              note.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(note.updatedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: note.isModified 
                        ? Colors.blue.shade100 
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.lastModifiedText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: note.isModified 
                          ? Colors.blue.shade700 
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(note: note),
            ),
          );
          // Refresh notes when returning from detail screen
          if (mounted) {
            context.read<NoteProvider>().loadNotes();
          }
        },
      ),
    );
  }
}
