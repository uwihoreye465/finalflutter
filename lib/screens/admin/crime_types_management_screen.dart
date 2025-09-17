import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CrimeTypesManagementScreen extends StatefulWidget {
  const CrimeTypesManagementScreen({super.key});

  @override
  State<CrimeTypesManagementScreen> createState() => _CrimeTypesManagementScreenState();
}

class _CrimeTypesManagementScreenState extends State<CrimeTypesManagementScreen> {
  final List<String> _predefinedCrimeTypes = [
    'Theft',
    'Robbery',
    'Assault',
    'Battery',
    'Fraud',
    'Drug Offenses',
    'Drug Trafficking',
    'Drug Possession',
    'Violence',
    'Domestic Violence',
    'Sexual Assault',
    'Rape',
    'Murder',
    'Manslaughter',
    'Kidnapping',
    'Extortion',
    'Money Laundering',
    'Cybercrime',
    'Identity Theft',
    'Embezzlement',
    'Burglary',
    'Arson',
    'Vandalism',
    'Trespassing',
    'Public Disorder',
    'Drunk Driving',
    'Reckless Driving',
    'Hit and Run',
    'Terrorism',
    'Human Trafficking',
    'Child Abuse',
    'Elder Abuse',
    'Animal Cruelty',
    'Environmental Crimes',
    'Tax Evasion',
    'Forgery',
    'Counterfeiting',
    'Bribery',
    'Corruption',
    'Other',
  ];

  List<String> _customCrimeTypes = [];
  final TextEditingController _newCrimeTypeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomCrimeTypes();
  }

  Future<void> _loadCustomCrimeTypes() async {
    // In a real app, this would load from the database
    // For now, we'll use a static list
    setState(() {
      _customCrimeTypes = [
        'Custom Crime 1',
        'Custom Crime 2',
      ];
    });
  }

  Future<void> _addCustomCrimeType() async {
    final newType = _newCrimeTypeController.text.trim();
    if (newType.isEmpty) return;

    if (_predefinedCrimeTypes.contains(newType) || _customCrimeTypes.contains(newType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This crime type already exists')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, this would save to the database
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      setState(() {
        _customCrimeTypes.add(newType);
        _newCrimeTypeController.clear();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom crime type added successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding crime type: $e')),
      );
    }
  }

  Future<void> _removeCustomCrimeType(String crimeType) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, this would delete from the database
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      setState(() {
        _customCrimeTypes.remove(crimeType);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom crime type removed successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing crime type: $e')),
      );
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Crime Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _newCrimeTypeController,
              labelText: 'Crime Type',
              hintText: 'Enter new crime type',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _newCrimeTypeController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addCustomCrimeType();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(String crimeType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Custom Crime Type'),
        content: Text('Are you sure you want to remove "$crimeType"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeCustomCrimeType(crimeType);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Types Management'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${_predefinedCrimeTypes.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text('Predefined Types'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${_customCrimeTypes.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text('Custom Types'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${_predefinedCrimeTypes.length + _customCrimeTypes.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const Text('Total Types'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Predefined Crime Types
                  const Text(
                    'Predefined Crime Types',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These are standard crime types that cannot be modified.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _predefinedCrimeTypes.map((type) {
                          return Chip(
                            label: Text(type),
                            backgroundColor: Colors.blue[100],
                            labelStyle: const TextStyle(color: Colors.blue),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Custom Crime Types
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Custom Crime Types',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add New'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These are custom crime types that can be added or removed.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: _customCrimeTypes.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'No custom crime types added yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _customCrimeTypes.map((type) {
                                return Chip(
                                  label: Text(type),
                                  backgroundColor: Colors.green[100],
                                  labelStyle: const TextStyle(color: Colors.green),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _showRemoveDialog(type),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Usage Guidelines
                  Card(
                    color: Colors.amber[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.amber[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Usage Guidelines',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Predefined crime types are standard categories that cannot be modified\n'
                            '• Custom crime types can be added for specific cases\n'
                            '• Use "Other" for crimes that don\'t fit standard categories\n'
                            '• Custom types can be removed if no longer needed\n'
                            '• All crime types are used in criminal records and arrest reports',
                            style: TextStyle(fontSize: 14),
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

  @override
  void dispose() {
    _newCrimeTypeController.dispose();
    super.dispose();
  }
}
