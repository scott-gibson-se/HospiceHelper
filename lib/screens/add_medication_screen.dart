import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';


class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _officialNameController = TextEditingController();
  final _formController = TextEditingController();
  final _maxDosageController = TextEditingController();
  final _minTimeHoursController = TextEditingController();
  final _minTimeMinutesController = TextEditingController();

  bool _notificationsEnabled = false;

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
  void dispose() {
    _nameController.dispose();
    _officialNameController.dispose();
    _formController.dispose();
    _maxDosageController.dispose();
    _minTimeHoursController.dispose();
    _minTimeMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minTimeHoursController,
                            decoration: const InputDecoration(
                              labelText: 'Hours *',
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final hours = int.tryParse(value);
                              if (hours == null || hours < 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _minTimeMinutesController,
                            decoration: const InputDecoration(
                              labelText: 'Minutes *',
                              hintText: '30',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final minutes = int.tryParse(value);
                              if (minutes == null || minutes < 0 || minutes >= 60) {
                                return '0-59';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minimum time between doses',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveMedication,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Add Medication',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      final hours = int.parse(_minTimeHoursController.text);
      final minutes = int.parse(_minTimeMinutesController.text);
      
      // Validate that at least one field has a value
      if (hours == 0 && minutes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least 1 minute for the time interval')),
        );
        return;
      }
      
      final medication = Medication(
        name: _nameController.text,
        officialName: _officialNameController.text,
        form: _formController.text,
        maxDosage: double.parse(_maxDosageController.text),
        minTimeBetweenDoses: Medication.fromHoursAndMinutes(hours, minutes),
        notificationsEnabled: _notificationsEnabled,
        createdAt: DateTime.now(),
      );

      context.read<MedicationProvider>().addMedication(medication).then((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medication added successfully')),
          );
        }
      }).catchError((error) {
        String errorMessage = error.toString();
        
        // Check if it's a notification error and offer to save without notifications
        if (errorMessage.contains('Failed to set up notifications')) {
          _showNotificationErrorDialog(medication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding medication: $error')),
            );
          }
        }
      });
    }
  }

  void _showNotificationErrorDialog(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Permission Required'),
        content: const Text(
          'This app needs notification permission to send medication reminders. '
          'Please enable notifications in your device settings, or save the medication without notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Open app settings to enable notifications
              // Note: This would need to be implemented with a proper settings opener
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enable notifications in your device settings'),
                  duration: Duration(seconds: 5),
                ),
              );
            },
            child: const Text('Open Settings'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save medication without notifications
              final medicationWithoutNotifications = medication.copyWith(
                notificationsEnabled: false,
              );
              
              context.read<MedicationProvider>().addMedication(medicationWithoutNotifications).then((_) {
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close add medication screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medication added without notifications')),
                  );
                }
              }).catchError((error) {
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding medication: $error')),
                  );
                }
              });
            },
            child: const Text('Save Without Notifications'),
          ),
        ],
      ),
    );
  }
}
