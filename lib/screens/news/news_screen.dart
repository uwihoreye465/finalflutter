import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/arrested_criminal.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<ArrestedCriminal> _arrestedCriminals = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _itemsPerPage = 4; // 4 items per page for 2x2 grid
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadArrestedCriminals();
  }

  Future<void> _loadArrestedCriminals({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _arrestedCriminals = [];
        _hasMoreData = true;
        _isLoading = true;
      });
    }

    try {
      final response = await ApiService.getArrestedCriminals(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      debugPrint('Arrested criminals API response: $response');

      List<ArrestedCriminal> newCriminals = [];
      
      // Handle the actual API response structure
      if (response['success'] == true && response['data'] != null) {
        final dataMap = response['data'] as Map<String, dynamic>;
        
        // The API returns data in data.records structure
        if (dataMap['records'] != null && dataMap['records'] is List) {
          final records = dataMap['records'] as List;
          newCriminals = records.map((record) {
            try {
              // Ensure record is a Map<String, dynamic>
              Map<String, dynamic> recordMap;
              if (record is Map<String, dynamic>) {
                recordMap = record;
              } else {
                recordMap = Map<String, dynamic>.from(record);
              }
              
              // Extract only essential fields for news display
              return ArrestedCriminal(
                arrestId: recordMap['arrest_id'] ?? 0,
                fullname: recordMap['fullname']?.toString() ?? 'Unknown',
                imageUrl: recordMap['image_url']?.toString(),
                crimeType: recordMap['crime_type']?.toString() ?? 'Unknown Crime',
                dateArrested: recordMap['date_arrested'] != null 
                    ? DateTime.parse(recordMap['date_arrested'].toString())
                    : DateTime.now(),
                arrestLocation: recordMap['arrest_location']?.toString(),
                idType: recordMap['id_type']?.toString(),
                idNumber: recordMap['id_number']?.toString(),
                criminalRecordId: recordMap['criminal_record_id'],
                arrestingOfficerId: recordMap['arresting_officer_id'],
              );
            } catch (e) {
              debugPrint('Error parsing arrested criminal record: $e');
              debugPrint('Record data: $record');
              return null;
            }
          }).where((criminal) => criminal != null).cast<ArrestedCriminal>().toList();
        }
      }

      // Get pagination info from response
      final pagination = response['data']['pagination'];
      if (pagination != null) {
        _totalPages = pagination['totalPages'] ?? 1;
      }

      setState(() {
        if (refresh) {
          _arrestedCriminals = newCriminals;
        } else {
          _arrestedCriminals.addAll(newCriminals);
        }
        _hasMoreData = _currentPage < _totalPages;
        _currentPage++;
        _isLoading = false;
      });

      debugPrint('Loaded ${newCriminals.length} arrested criminals (Page $_currentPage of $_totalPages)');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading arrested criminals: $e');
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load news: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _goToNextPage() {
    if (_hasMoreData) {
      _loadArrestedCriminals();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage = _currentPage - 1;
        _arrestedCriminals = [];
        _hasMoreData = true;
        _isLoading = true;
      });
      _loadArrestedCriminals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Latest News - Arrested Criminals', 
                         style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryColor, AppColors.secondaryColor],
              ),
            ),
            child: const Column(
              children: [
                Text(
                  'Rwanda Investigation Bureau',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Criminal Alert System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // News List
          Expanded(
            child: _isLoading && _arrestedCriminals.isEmpty
                ? const Center(child: LoadingWidget())
                : _arrestedCriminals.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.newspaper, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No news available at the moment',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Check back later for updates',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadArrestedCriminals(refresh: true),
                        child: Column(
                          children: [
                            // 2x2 Grid Layout
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.8,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _arrestedCriminals.length,
                                itemBuilder: (context, index) {
                                  final criminal = _arrestedCriminals[index];
                                  return _buildNewsCard(criminal);
                                },
                              ),
                            ),
                            
                            // Pagination Controls
                            if (_totalPages > 1)
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Previous Page Button
                                    ElevatedButton(
                                      onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Previous'),
                                    ),
                                    
                                    // Page Info
                                    Text(
                                      'Page $_currentPage of $_totalPages',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    
                                    // Next Page Button
                                    ElevatedButton(
                                      onPressed: _hasMoreData ? _goToNextPage : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Next'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(ArrestedCriminal criminal) {
    return Container(
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
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with alert badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ARRESTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd').format(criminal.dateArrested),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Photo placeholder or actual image
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: criminal.imageUrl != null && criminal.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              criminal.imageUrl!,
                              width: double.infinity,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPhotoPlaceholder();
                              },
                            ),
                          )
                        : _buildPhotoPlaceholder(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Criminal details
                  Text(
                    criminal.fullname,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    criminal.crimeType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (criminal.arrestLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      criminal.arrestLocation!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, color: Colors.grey[600], size: 32),
          Text(
            'Photo',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
