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
  final int _itemsPerPage = 10;

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

      if (response['success'] == true && response['data'] != null) {
        final List<ArrestedCriminal> newCriminals = (response['data'] as List)
            .map((json) => ArrestedCriminal.fromJson(json))
            .toList();

        setState(() {
          if (refresh) {
            _arrestedCriminals = newCriminals;
          } else {
            _arrestedCriminals.addAll(newCriminals);
          }
          _hasMoreData = newCriminals.length == _itemsPerPage;
          _currentPage++;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        debugPrint('No data received from API');
      }
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
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _arrestedCriminals.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _arrestedCriminals.length) {
                              // Load more indicator
                              if (_hasMoreData) {
                                _loadArrestedCriminals();
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: LoadingWidget(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final criminal = _arrestedCriminals[index];
                            return _buildNewsCard(criminal);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(ArrestedCriminal criminal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Header with alert badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ARRESTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(criminal.dateArrested),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Photo placeholder or actual image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: criminal.imageUrl != null && criminal.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            criminal.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPhotoPlaceholder();
                            },
                          ),
                        )
                      : _buildPhotoPlaceholder(),
                ),
                
                const SizedBox(width: 16),
                
                // Criminal details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        criminal.fullname,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      _buildDetailRow('Crime', criminal.crimeType),
                      
                      if (criminal.idNumber != null)
                        _buildDetailRow('ID', criminal.idNumber!),
                      
                      if (criminal.arrestLocation != null)
                        _buildDetailRow('Location', criminal.arrestLocation!),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Warning footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This person has been arrested and charged. If you have any information related to this case, please contact RIB.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
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
