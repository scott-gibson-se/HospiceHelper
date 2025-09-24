import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/question.dart';
import '../providers/question_provider.dart';

class QuestionDetailScreen extends StatefulWidget {
  final Question question;

  const QuestionDetailScreen({super.key, required this.question});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _questionTextController;
  late TextEditingController _answerController;
  late DateTime _dateEntered;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.question.title);
    _questionTextController = TextEditingController(text: widget.question.questionText);
    _answerController = TextEditingController(text: widget.question.answer ?? '');
    _dateEntered = widget.question.dateEntered;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _questionTextController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateEntered,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateEntered),
    );
    if (pickedTime == null) return;
    setState(() {
      _dateEntered = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveAllChanges(Question current) async {
    if (_titleController.text.trim().isEmpty || _questionTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and question text'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final String answerText = _answerController.text.trim();
      final updated = current.copyWith(
        title: _titleController.text.trim(),
        questionText: _questionTextController.text.trim(),
        dateEntered: _dateEntered,
        answer: answerText.isEmpty ? null : answerText,
        answeredAt: answerText.isEmpty ? null : (current.answeredAt ?? DateTime.now()),
        updatedAt: DateTime.now(),
      );
      await context.read<QuestionProvider>().updateQuestion(updated);

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuestion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<QuestionProvider>().deleteQuestion(widget.question.id!);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting question: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestionProvider>();
    final Question current = provider.questions.firstWhere(
      (q) => q.id == widget.question.id,
      orElse: () => widget.question,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (!_isEditing) {
                  // sync controllers from latest provider value
                  _titleController.text = current.title;
                  _questionTextController.text = current.questionText;
                  _answerController.text = current.answer ?? '';
                  _dateEntered = current.dateEntered;
                }
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            tooltip: _isEditing ? 'Cancel' : 'Edit',
          ),
          if (_isEditing)
            IconButton(
              onPressed: () => _saveAllChanges(current),
              icon: const Icon(Icons.save),
              tooltip: 'Save',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteQuestion();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Question'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Title
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Question Title',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter question title',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      Text(
                        current.title,
                        style: const TextStyle(fontSize: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Question Text
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.question_answer,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Question',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextField(
                        controller: _questionTextController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Enter the question text',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      Text(
                        current.questionText,
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Date & Time Entered',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, MMMM dd, yyyy - HH:mm').format(_dateEntered),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _pickDateTime,
                            icon: const Icon(Icons.edit_calendar),
                            label: const Text('Change'),
                          )
                        ],
                      )
                    else
                      Text(
                        DateFormat('EEEE, MMMM dd, yyyy - HH:mm').format(current.dateEntered),
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Answer Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.question_answer,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Answer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: current.isAnswered 
                                ? Colors.green.shade100 
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            current.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: current.isAnswered 
                                  ? Colors.green.shade700 
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      Column(
                        children: [
                          TextField(
                            controller: _answerController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your answer here...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 5,
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _saveAllChanges(current),
                              icon: const Icon(Icons.save),
                              label: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (current.isAnswered) ...[
                            Text(
                              current.answer!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Answered on: ${DateFormat('MMM dd, yyyy - HH:mm').format(current.answeredAt!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'No answer provided yet.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Add Answer'),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
