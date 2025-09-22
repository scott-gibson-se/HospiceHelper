import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';

class EditMedicationScreen extends StatefulWidget {
  final Medication medication;

  const EditMedicationScreen({
    super.key,
    required this.medication,
  });

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _officialNameController;
  late TextEditingController _formController;
  late TextEditingController _maxDosageController;
  late TextEditingController _minTimeController;

  late bool _notificationsEnabled;
  late String _selectedSound;

  final List<String> _medicationForms = [
    'Tablet',
    'Capsule',
    'Liquid',
    'Injection',
    'Patch',
    'Suppository',
    'Inhaler',
    'Drops',
    'Cream',
    'Ointment',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication.name);
    _officialNameController = TextEditingController(text: widget.medication.officialName);
    _formController = TextEditingController(text: widget.medication.form);
    _maxDosageController = TextEditingController(text: widget.medication.maxDosage.toString());
    _minTimeController = TextEditingController(text: widget.medication.minTimeBetweenDoses.toString());
    
    _notificationsEnabled = widget.medication.notificationsEnabled;
    _selectedSound = widget.medication.notificationSound;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _officialNameController.dispose();
    _formController.dispose();
    _maxDosageController.dispose();
    _minTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medication'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
            tooltip: 'Delete Medication',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medication Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication Name *',
                        hintText: 'e.g., Pain Relief',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a medication name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _officialNameController,
                      decoration: const InputDecoration(
                        labelText: 'Official Medication Name *',
                        hintText: 'e.g., Morphine Sulfate',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the official medication name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _formController.text.isNotEmpty ? _formController.text : null,
                      decoration: const InputDecoration(
                        labelText: 'Form *',
                        border: OutlineInputBorder(),
                      ),
                      items: _medicationForms.map((String form) {
                        return DropdownMenuItem<String>(
                          value: form,
                          child: Text(form),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _formController.text = newValue ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a form';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxDosageController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Dosage *',
                        hintText: 'e.g., 10',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter maximum dosage';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid dosage amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _minTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Time Between Doses (minutes) *',
                        hintText: 'e.g., 240',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter minimum time between doses';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Please enter a valid time in minutes';
                        }
                        return null;
                      },
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
                      'Notification Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Get reminded when it\'s time for the next dose'),
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    if (_notificationsEnabled) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSound,
                        decoration: const InputDecoration(
                          labelText: 'Notification Sound',
                          border: OutlineInputBorder(),
                        ),
                        items: NotificationService.getAvailableSounds().map((String sound) {
                          return DropdownMenuItem<String>(
                            value: sound,
                            child: Text(NotificationService.getSoundDescription(sound)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSound = newValue ?? 'gentle';
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateMedication,
                    child: const Text('Update Medication'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateMedication() {
    if (_formKey.currentState!.validate()) {
      final updatedMedication = widget.medication.copyWith(
        name: _nameController.text,
        officialName: _officialNameController.text,
        form: _formController.text,
        maxDosage: double.parse(_maxDosageController.text),
        minTimeBetweenDoses: int.parse(_minTimeController.text),
        notificationsEnabled: _notificationsEnabled,
        notificationSound: _selectedSound,
        updatedAt: DateTime.now(),
      );

      context.read<MedicationProvider>().updateMedication(updatedMedication).then((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication updated successfully')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating medication: $error')),
        );
      });
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text(
          'Are you sure you want to delete "${widget.medication.name}"? This action cannot be undone and will also delete all associated dose logs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MedicationProvider>().deleteMedication(widget.medication.id!).then((_) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close edit screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medication deleted successfully')),
                );
              }).catchError((error) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting medication: $error')),
                );
              });
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
}
