import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/arrested_criminal.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import 'add_arrested_criminal_screen.dart';
import 'arrested_criminal_detail_screen.dart';

class ArrestedCriminalsScreen extends StatefulWidget {
  const ArrestedCriminalsScreen({super.key});

  @override
  State<ArrestedCriminalsScreen> createState() => _ArrestedCriminalsScreenState();
}

class _ArrestedCriminalsScreenState extends State<ArrestedCriminalsScreen> {
  List<ArrestedCriminal> _arrestedCriminals = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadArrestedCriminals();
  }

  Future<void> _loadArrestedCriminals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getArrestedCriminals(
        page: _currentPage,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _arrestedCriminals = (response['data'] as List)
              .map((json) => ArrestedCriminal.fromJson(json))
              .toList();
          _totalPages = response['total_pages'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading arrested criminals: $e')),
        );
      }
    }
  }

  Future<void> _deleteArrestedCriminal(int id) async {
    try {
      final success = await ApiService.deleteArrestedCriminal(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arrested criminal deleted successfully')),
        );
        _loadArrestedCriminals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting arrested criminal: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(ArrestedCriminal arrested) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Arrested Criminal'),
        content: Text('Are you sure you want to delete ${arrested.fullname}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteArrestedCriminal(arrested.arrestId!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrested Criminals'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArrestedCriminals,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search arrested criminals...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // Implement search functionality
              },
            ),
          ),
          // Statistics Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${_arrestedCriminals.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Text('Total Arrested'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${_arrestedCriminals.where((a) => a.dateArrested.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text('This Week'),
                  ],
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _arrestedCriminals.isEmpty
                    ? const Center(
                        child: Text(
                          'No arrested criminals found',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _arrestedCriminals.length,
                        itemBuilder: (context, index) {
                          final arrested = _arrestedCriminals[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red[100],
                                child: arrested.imageUrl != null
                                    ? ClipOval(
                                        child: arrested.imageUrl!.startsWith('data:image')
                                            ? Image.memory(
                                                base64Decode(arrested.imageUrl!.split(',')[1]),
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    color: Colors.red[700],
                                                  );
                                                },
                                              )
                                            : Image.network(
                                                arrested.imageUrl!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    color: Colors.red[700],
                                                  );
                                                },
                                              ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: Colors.red[700],
                                      ),
                              ),
                              title: Text(
                                arrested.fullname,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Crime: ${arrested.crimeType}'),
                                  Text(
                                    'Arrested: ${arrested.dateArrested.day}/${arrested.dateArrested.month}/${arrested.dateArrested.year}',
                                  ),
                                  if (arrested.arrestLocation != null)
                                    Text('Location: ${arrested.arrestLocation}'),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Text('View Details'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ArrestedCriminalDetailScreen(
                                            arrestedCriminal: arrested,
                                          ),
                                        ),
                                      );
                                      break;
                                    case 'edit':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddArrestedCriminalScreen(
                                            arrestedCriminal: arrested,
                                          ),
                                        ),
                                      ).then((_) => _loadArrestedCriminals());
                                      break;
                                    case 'delete':
                                      _showDeleteDialog(arrested);
                                      break;
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _loadArrestedCriminals();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                            _loadArrestedCriminals();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddArrestedCriminalScreen(),
            ),
          ).then((_) => _loadArrestedCriminals());
        },
        backgroundColor: Colors.red[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
