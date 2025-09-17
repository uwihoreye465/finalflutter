import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/criminal_record.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';

class SearchResultScreen extends StatelessWidget {
  final CriminalRecord criminalRecord;
  final String searchId;

  const SearchResultScreen({
    super.key,
    required this.criminalRecord,
    required this.searchId,
  });

  void _showNotificationForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nearRibController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Alert to RIB'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nearRibController,
                    decoration: const InputDecoration(
                      labelText: 'Nearest RIB Station',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Kigali Central, Musanze, etc.',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter nearest RIB station';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Your Phone Number',
                      border: OutlineInputBorder(),
                      hintText: '+250788123456',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Current Location',
                      border: OutlineInputBorder(),
                      hintText: 'Where did you see this person?',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Additional Information',
                      border: OutlineInputBorder(),
                      hintText: 'Any additional details about the sighting...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await ApiService.sendNotification({
                      'near_rib': nearRibController.text.trim(),
                      'fullname': '${criminalRecord.firstName} ${criminalRecord.lastName}',
                      'address': addressController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'message': 'CRIMINAL SIGHTING ALERT: ${criminalRecord.firstName} ${criminalRecord.lastName} (ID: ${criminalRecord.idNumber}) spotted at ${addressController.text.trim()}. Crime: ${criminalRecord.crimeType}. Additional info: ${messageController.text.trim()}',
                    });
                    
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Alert sent to RIB successfully! They will contact you soon.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send alert: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Alert'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: const Text('Criminal Record Found', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'WAHUNZE UBUTABERA',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${criminalRecord.firstName} ${criminalRecord.lastName} afite amateka y\'ubugizi bwa nabi',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This person has committed: ${criminalRecord.crimeType}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Personal Information Card
            _buildInfoCard(
              title: 'Personal Information',
              children: [
                _buildInfoRow('ID Type', _formatIdType(criminalRecord.idType)),
                _buildInfoRow('ID Number', criminalRecord.idNumber),
                _buildInfoRow('Full Name', '${criminalRecord.firstName} ${criminalRecord.lastName}'),
                _buildInfoRow('Gender', criminalRecord.gender),
                if (criminalRecord.dateOfBirth != null)
                  _buildInfoRow('Date of Birth', DateFormat('yyyy-MM-dd').format(criminalRecord.dateOfBirth!)),
                if (criminalRecord.maritalStatus != null)
                  _buildInfoRow('Marital Status', criminalRecord.maritalStatus!),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Address Information Card
            if (_hasAddressInfo())
              _buildInfoCard(
                title: 'Address Information',
                children: [
                  if (criminalRecord.country != null)
                    _buildInfoRow('Country', criminalRecord.country!),
                  if (criminalRecord.province != null)
                    _buildInfoRow('Province', criminalRecord.province!),
                  if (criminalRecord.district != null)
                    _buildInfoRow('District', criminalRecord.district!),
                  if (criminalRecord.sector != null)
                    _buildInfoRow('Sector', criminalRecord.sector!),
                  if (criminalRecord.cell != null)
                    _buildInfoRow('Cell', criminalRecord.cell!),
                  if (criminalRecord.village != null)
                    _buildInfoRow('Village', criminalRecord.village!),
                  if (criminalRecord.addressNow != null)
                    _buildInfoRow('Current Address', criminalRecord.addressNow!),
                ],
              ),
            
            if (_hasAddressInfo())
              const SizedBox(height: 16),
            
            // Crime Information Card
            _buildInfoCard(
              title: 'Crime Information',
              children: [
                _buildInfoRow('Crime Type', criminalRecord.crimeType),
                if (criminalRecord.description != null)
                  _buildInfoRow('Description', criminalRecord.description!),
                if (criminalRecord.dateCommitted != null)
                  _buildInfoRow('Date Committed', DateFormat('yyyy-MM-dd').format(criminalRecord.dateCommitted!)),
                if (criminalRecord.createdAt != null)
                  _buildInfoRow('Record Created', DateFormat('yyyy-MM-dd HH:mm').format(criminalRecord.createdAt!)),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Send Notification to Admin Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.report_problem,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Found this person?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Send a notification to RIB with location details',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showNotificationForm(context),
                    icon: const Icon(Icons.send),
                    label: const Text('Send Alert to RIB'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.search),
                    label: const Text('Search Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAddressInfo() {
    return criminalRecord.country != null ||
           criminalRecord.province != null ||
           criminalRecord.district != null ||
           criminalRecord.sector != null ||
           criminalRecord.cell != null ||
           criminalRecord.village != null ||
           criminalRecord.addressNow != null;
  }

  String _formatIdType(String idType) {
    switch (idType) {
      case 'indangamuntu_yumunyarwanda':
        return 'Indangamuntu y\'Umunyarwanda';
      case 'indangamuntu_yumunyamahanga':
        return 'Indangamuntu y\'Umunyamahanga';
      case 'indangampunzi':
        return 'Indangampunzi';
      case 'passport':
        return 'Passport';
      default:
        return idType;
    }
  }
}