import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/arrested_criminal.dart';
import '../../services/api_service.dart';
import 'add_arrested_criminal_screen.dart';

class ArrestedCriminalDetailScreen extends StatefulWidget {
  final ArrestedCriminal arrestedCriminal;

  const ArrestedCriminalDetailScreen({
    super.key,
    required this.arrestedCriminal,
  });

  @override
  State<ArrestedCriminalDetailScreen> createState() => _ArrestedCriminalDetailScreenState();
}

class _ArrestedCriminalDetailScreenState extends State<ArrestedCriminalDetailScreen> {
  bool _isLoading = false;

  Future<void> _deleteArrestedCriminal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.deleteArrestedCriminal(widget.arrestedCriminal.arrestId!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arrested criminal deleted successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting arrested criminal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Arrested Criminal'),
        content: Text('Are you sure you want to delete ${widget.arrestedCriminal.fullname}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteArrestedCriminal();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arrested = widget.arrestedCriminal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrested Criminal Details'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddArrestedCriminalScreen(
                    arrestedCriminal: arrested,
                  ),
                ),
              ).then((_) {
                // Refresh the screen if needed
                setState(() {});
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(75),
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: arrested.imageUrl != null
                          ? ClipOval(
                              child: arrested.imageUrl!.startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(arrested.imageUrl!.split(',')[1]),
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.grey[400],
                                        );
                                      },
                                    )
                                  : Image.network(
                                      arrested.imageUrl!,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.grey[400],
                                        );
                                      },
                                    ),
                            )
                          : Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Basic Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Full Name', arrested.fullname),
                          _buildInfoRow('Crime Type', arrested.crimeType),
                          _buildInfoRow(
                            'Date Arrested',
                            '${arrested.dateArrested.day}/${arrested.dateArrested.month}/${arrested.dateArrested.year}',
                          ),
                          if (arrested.arrestLocation != null)
                            _buildInfoRow('Arrest Location', arrested.arrestLocation!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Identification Card
                  if (arrested.idType != null || arrested.idNumber != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Identification',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (arrested.idType != null)
                              _buildInfoRow('ID Type', arrested.idType!),
                            if (arrested.idNumber != null)
                              _buildInfoRow('ID Number', arrested.idNumber!),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // System Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'System Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (arrested.criminalRecordId != null)
                            _buildInfoRow('Criminal Record ID', arrested.criminalRecordId.toString()),
                          if (arrested.arrestingOfficerId != null)
                            _buildInfoRow('Arresting Officer ID', arrested.arrestingOfficerId.toString()),
                          if (arrested.createdAt != null)
                            _buildInfoRow(
                              'Created At',
                              '${arrested.createdAt!.day}/${arrested.createdAt!.month}/${arrested.createdAt!.year}',
                            ),
                          if (arrested.updatedAt != null)
                            _buildInfoRow(
                              'Updated At',
                              '${arrested.updatedAt!.day}/${arrested.updatedAt!.month}/${arrested.updatedAt!.year}',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddArrestedCriminalScreen(
                                  arrestedCriminal: arrested,
                                ),
                              ),
                            ).then((_) {
                              // Refresh the screen if needed
                              setState(() {});
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showDeleteDialog,
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
