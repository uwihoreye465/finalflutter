import 'package:flutter/material.dart';
import '../../models/criminal_record.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _idNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isSearching = false;
  CriminalRecord? _foundCriminal;
  bool _isVerified = false;
  String _verificationStatus = '';

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _verifyPerson() async {
    if (_idNumberController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundCriminal = null;
      _isVerified = false;
      _verificationStatus = '';
    });

    try {
      final criminal = await ApiService.searchCriminalRecord(_idNumberController.text.trim());
      
      if (criminal != null) {
        setState(() {
          _foundCriminal = criminal;
          _isVerified = false;
          _verificationStatus = 'FLAGGED - Criminal record found';
        });
        
        // Send alert notification
        await ApiService.sendNotification({
          'near_rib': 'Security Personnel',
          'fullname': '${criminal.firstName} ${criminal.lastName}',
          'address': criminal.addressNow ?? 'Unknown',
          'phone': criminal.phone ?? 'Unknown',
          'message': 'SECURITY ALERT: Person with criminal record attempting relocation. Name: ${criminal.firstName} ${criminal.lastName}, Crime: ${criminal.crimeType}, Date: ${criminal.dateCommitted?.day}/${criminal.dateCommitted?.month}/${criminal.dateCommitted?.year}',
        });
        
      } else {
        setState(() {
          _isVerified = true;
          _verificationStatus = 'CLEAR - No criminal record found';
        });
      }
    } catch (e) {
      setState(() {
        _verificationStatus = 'ERROR - Unable to verify';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _clearVerification() {
    setState(() {
      _idNumberController.clear();
      _foundCriminal = null;
      _isVerified = false;
      _verificationStatus = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Verification'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 48,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Person Verification System',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter ID number to check for criminal records',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ID Input Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ID Verification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _idNumberController,
                              labelText: 'ID Number',
                              hintText: 'Enter person\'s ID number',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter ID number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSearching ? null : _verifyPerson,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            child: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Verify'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Verification Result
              if (_verificationStatus.isNotEmpty)
                Card(
                  color: _isVerified ? Colors.green[50] : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isVerified ? Icons.check_circle : Icons.warning,
                              color: _isVerified ? Colors.green[700] : Colors.red[700],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Verification Result',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isVerified ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _verificationStatus,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _isVerified ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        if (!_isVerified && _foundCriminal != null) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Criminal Details:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCriminalDetails(_foundCriminal!),
                        ],
                        if (_isVerified) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'This person has no criminal record and is cleared for relocation.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Clear',
                      onPressed: _clearVerification,
                      backgroundColor: Colors.grey[600] ?? Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: _isVerified ? 'Allow Relocation' : 'Deny Relocation',
                      onPressed: _verificationStatus.isEmpty ? null : () {
                        if (_isVerified) {
                          _showRelocationApprovedDialog();
                        } else {
                          _showRelocationDeniedDialog();
                        }
                      },
                      backgroundColor: _isVerified ? (Colors.green[700] ?? Colors.green) : (Colors.red[700] ?? Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriminalDetails(CriminalRecord criminal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Name', '${criminal.firstName} ${criminal.lastName}'),
        _buildDetailRow('Crime Type', criminal.crimeType),
        _buildDetailRow('Date Committed', 
            criminal.dateCommitted != null 
                ? '${criminal.dateCommitted!.day}/${criminal.dateCommitted!.month}/${criminal.dateCommitted!.year}'
                : 'Unknown'),
        if (criminal.province != null)
          _buildDetailRow('Province', criminal.province!),
        if (criminal.phone != null)
          _buildDetailRow('Phone', criminal.phone!),
        if (criminal.description != null)
          _buildDetailRow('Description', criminal.description!),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  void _showRelocationApprovedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Relocation Approved'),
          ],
        ),
        content: const Text(
          'This person has been verified and cleared for relocation. No criminal record found.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearVerification();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRelocationDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Relocation Denied'),
          ],
        ),
        content: const Text(
          'This person has a criminal record and relocation has been denied. Security personnel have been notified.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearVerification();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
