import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dose_log.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';

class LogDoseScreen extends StatefulWidget {
  final String title;
  final Medication? medication;
  final List<Medication>? medications;
  final DoseLog? doseLog;

  LogDoseScreen({
    super.key,
    required this.title,
    this.medication,
    this.medications,
    this.doseLog,
  }) : assert(
         medication != null || (medications != null && medications.isNotEmpty),
         'Provide a medication or a non-empty medications list',
       );

  static Future<bool?> showForMedication(
    BuildContext context, {
    required Medication medication,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => LogDoseScreen(
          title: 'Log Dose - ${medication.name}',
          medication: medication,
        ),
      ),
    );
  }

  static Future<bool?> showForDoseEntry(
    BuildContext context, {
    required String title,
    required List<Medication> medications,
    DoseLog? doseLog,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => LogDoseScreen(
          title: title,
          medications: medications,
          doseLog: doseLog,
        ),
      ),
    );
  }

  @override
  State<LogDoseScreen> createState() => _LogDoseScreenState();
}

class _LogDoseScreenState extends State<LogDoseScreen> {
  late final TextEditingController _doseController;
  late final TextEditingController _givenByController;
  late final TextEditingController _noteController;
  late DateTime _selectedDateTime;
  late DateTime _initialDateTime;
  Medication? _selectedMedication;
  Medication? _initialMedication;
  bool _isSaving = false;

  bool get _isEditing => widget.doseLog != null;

  @override
  void initState() {
    super.initState();
    _doseController = TextEditingController(
      text: widget.doseLog?.doseGiven.toString() ?? '',
    );
    _givenByController = TextEditingController(
      text: widget.doseLog?.givenBy ?? '',
    );
    _noteController = TextEditingController(text: widget.doseLog?.note ?? '');
    _selectedDateTime = widget.doseLog?.dateTime ?? DateTime.now();
    _initialDateTime = _selectedDateTime;
    _selectedMedication =
        widget.medication ??
        (widget.doseLog != null
            ? widget.medications!.firstWhere(
                (m) => m.id == widget.doseLog!.medicationId,
              )
            : widget.medications!.first);
    _initialMedication = _selectedMedication;

    _doseController.addListener(_onControllerChanged);
    _givenByController.addListener(_onControllerChanged);
    _noteController.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _doseController.removeListener(_onControllerChanged);
    _givenByController.removeListener(_onControllerChanged);
    _noteController.removeListener(_onControllerChanged);
    _doseController.dispose();
    _givenByController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (_isEditing) {
      final log = widget.doseLog!;
      final note = _noteController.text.trim();
      return _doseController.text != log.doseGiven.toString() ||
          _givenByController.text.trim() != log.givenBy ||
          (note.isEmpty ? null : note) != log.note ||
          !_isSameDateTime(_selectedDateTime, log.dateTime) ||
          _activeMedication.id != log.medicationId;
    }

    return _doseController.text.isNotEmpty ||
        _givenByController.text.isNotEmpty ||
        _noteController.text.isNotEmpty ||
        !_isSameDateTime(_selectedDateTime, _initialDateTime) ||
        _selectedMedication?.id != _initialMedication?.id;
  }

  bool _isSameDateTime(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  Future<bool> _showDiscardDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Medication get _activeMedication {
    if (widget.medication != null) {
      return widget.medication!;
    }
    return _selectedMedication!;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveDose() async {
    if (widget.medication == null && _selectedMedication == null) {
      _showMessage('Please select a medication', isError: true);
      return;
    }

    final dose = double.tryParse(_doseController.text);
    if (dose == null || dose <= 0) {
      _showMessage('Please enter a valid dose amount', isError: true);
      return;
    }

    if (_givenByController.text.trim().isEmpty) {
      _showMessage('Please enter who gave the dose', isError: true);
      return;
    }

    final medication = _activeMedication;
    final noteText = _noteController.text.trim();
    final doseLog = DoseLog(
      id: widget.doseLog?.id,
      medicationId: medication.id!,
      dateTime: _selectedDateTime,
      doseGiven: dose,
      givenBy: _givenByController.text.trim(),
      note: noteText.isEmpty ? null : noteText,
      createdAt: widget.doseLog?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<MedicationProvider>();
    if (_isEditing) {
      await provider.updateDoseLog(doseLog);
      _showMessage('Dose updated successfully');
    } else {
      await provider.logDose(doseLog);
      _showMessage('Dose logged successfully');
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
      Navigator.of(context).pop(true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.orange : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medication = _activeMedication;

    return PopScope(
      canPop: !_hasUnsavedChanges || _isSaving,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final bool shouldPop = await _showDiscardDialog();
        if (shouldPop && context.mounted) {
          setState(() {
            _isSaving = true;
          });
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.medication == null) ...[
                  DropdownButtonFormField<Medication>(
                    value: _selectedMedication,
                    decoration: const InputDecoration(
                      labelText: 'Medication',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.medications!.map((med) {
                      return DropdownMenuItem(
                        value: med,
                        child: Text(med.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMedication = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _doseController,
                  autofocus: widget.medication != null,
                  decoration: InputDecoration(
                    labelText: 'Dose Given',
                    hintText: 'Enter amount',
                    suffixText: medication.form,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _givenByController,
                  decoration: const InputDecoration(
                    labelText: 'Given By',
                    hintText: 'Who administered the dose?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date'),
                        subtitle: Text(
                          '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Time'),
                        subtitle: Text(
                          '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'Any additional notes...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveDose,
                      child: Text(_isEditing ? 'Update Dose' : 'Log Dose'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
