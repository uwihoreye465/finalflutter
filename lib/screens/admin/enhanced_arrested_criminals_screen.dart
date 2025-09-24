import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../models/arrested_criminal.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EnhancedArrestedCriminalsScreen extends StatefulWidget {
  const EnhancedArrestedCriminalsScreen({super.key});

  @override
  State<EnhancedArrestedCriminalsScreen> createState() => _EnhancedArrestedCriminalsScreenState();
}

class _EnhancedArrestedCriminalsScreenState extends State<EnhancedArrestedCriminalsScreen> {
  List<ArrestedCriminal> _arrestedCriminals = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();

  // Add/Edit arrested criminal form controllers
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _crimeTypeController = TextEditingController();
  final _arrestLocationController = TextEditingController();
  final _idNumberController = TextEditingController();
  
  String? _selectedIdType;
  String? _selectedCrimeType;
  DateTime? _selectedDateArrested;
  bool _isSubmitting = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  ArrestedCriminal? _editingArrested;

  // Crime types list
  final List<String> _crimeTypes = [
    'Theft',
    'Assault',
    'Battery',
    'Robbery',
    'Burglary',
    'Fraud',
    'Drug Possession',
    'Drug Trafficking',
    'Domestic Violence',
    'Sexual Assault',
    'Murder',
    'Manslaughter',
    'Kidnapping',
    'Arson',
    'Vandalism',
    'Trespassing',
    'Embezzlement',
    'Money Laundering',
    'Cyber Crime',
    'Terrorism',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadArrestedCriminals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fullnameController.dispose();
    _crimeTypeController.dispose();
    _arrestLocationController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadArrestedCriminals() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.getArrestedCriminals(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      if (response['success'] == true) {
        final List<dynamic> records = response['data']['records'] ?? [];
        final List<ArrestedCriminal> arrestedCriminals = records
            .map((json) {
              try {
                // Handle the case where json might be a Map<String, dynamic> or already parsed
                Map<String, dynamic> jsonMap;
                if (json is Map<String, dynamic>) {
                  jsonMap = json;
                } else {
                  jsonMap = Map<String, dynamic>.from(json);
                }
                
                // Handle image_url which might be a Buffer object
                if (jsonMap['image_url'] != null && jsonMap['image_url'] is Map) {
                  final imageData = jsonMap['image_url'] as Map<String, dynamic>;
                  if (imageData['type'] == 'Buffer' && imageData['data'] != null) {
                    // Convert buffer data to string - handle both List<int> and List<dynamic>
                    final bufferData = imageData['data'];
                    if (bufferData is List<int>) {
                      final imageString = String.fromCharCodes(bufferData);
                      jsonMap['image_url'] = imageString;
                    } else if (bufferData is List) {
                      // Convert List<dynamic> to List<int>
                      final intList = bufferData.map((e) => e as int).toList();
                      final imageString = String.fromCharCodes(intList);
                      jsonMap['image_url'] = imageString;
                    }
                  }
                }
                
                return ArrestedCriminal.fromJson(jsonMap);
              } catch (e) {
                debugPrint('Error parsing arrested criminal: $e');
                debugPrint('JSON data: $json');
                debugPrint('JSON type: ${json.runtimeType}');
                return null;
              }
            })
            .where((criminal) => criminal != null)
            .cast<ArrestedCriminal>()
            .toList();

        setState(() {
          if (_currentPage == 1) {
            _arrestedCriminals = arrestedCriminals;
          } else {
            _arrestedCriminals.addAll(arrestedCriminals);
          }
          _hasMoreData = arrestedCriminals.length == _itemsPerPage;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load arrested criminals');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Error loading arrested criminals: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_hasMoreData && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      await _loadArrestedCriminals();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });
    await _loadArrestedCriminals();
  }

  void _onSearchChanged(String value) {
    setState(() {});
  }

  List<ArrestedCriminal> get _filteredArrestedCriminals {
    if (_searchController.text.isEmpty) {
      return _arrestedCriminals;
    }
    
    final searchTerm = _searchController.text.toLowerCase();
    return _arrestedCriminals.where((arrested) {
      return (arrested.fullname?.toLowerCase().contains(searchTerm) ?? false) ||
             (arrested.crimeType?.toLowerCase().contains(searchTerm) ?? false) ||
             (arrested.arrestLocation?.toLowerCase().contains(searchTerm) ?? false) ||
             (arrested.idNumber?.toLowerCase().contains(searchTerm) ?? false);
    }).toList();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error picking image: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  void _clearForm() {
    _fullnameController.clear();
    _arrestLocationController.clear();
    _idNumberController.clear();
    _selectedIdType = null;
    _selectedCrimeType = null;
    _selectedDateArrested = null;
    _selectedImage = null;
    _editingArrested = null;
  }

  Future<void> _addArrestedCriminal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIdType == null) {
      Fluttertoast.showToast(
        msg: 'Please select ID type',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
      return;
    }

    if (_selectedDateArrested == null) {
      Fluttertoast.showToast(
        msg: 'Please select arrest date',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload image first if selected
      String? uploadedImageUrl;
      if (_selectedImage != null) {
        try {
          debugPrint('Uploading image: ${_selectedImage!.path}');
          uploadedImageUrl = await ApiService.uploadImage(File(_selectedImage!.path));
          debugPrint('Image uploaded successfully: $uploadedImageUrl');
        } catch (e) {
          debugPrint('Error uploading image: $e');
          Fluttertoast.showToast(
            msg: 'Image upload failed: $e',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: AppColors.warningColor,
            textColor: Colors.white,
          );
          // Continue without image if upload fails
        }
      }

      final arrestedCriminal = ArrestedCriminal(
        arrestId: null,
        fullname: _fullnameController.text.trim(),
        imageUrl: uploadedImageUrl,
        crimeType: _selectedCrimeType ?? '',
        dateArrested: _selectedDateArrested!,
        arrestLocation: _arrestLocationController.text.trim(),
        idType: _selectedIdType,
        idNumber: _idNumberController.text.trim(),
        criminalRecordId: null,
        arrestingOfficerId: null,
        createdAt: null,
        updatedAt: null,
      );

      final response = await ApiService.addArrestedCriminal(arrestedCriminal);
      
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Arrested criminal added successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        _clearForm();
        _refresh();
        Navigator.of(context).pop();
      } else {
        throw Exception(response['message'] ?? 'Failed to add arrested criminal');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error adding arrested criminal: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> _updateArrestedCriminal() async {
    if (!_formKey.currentState!.validate() || _editingArrested == null) return;

    if (_selectedIdType == null) {
      Fluttertoast.showToast(
        msg: 'Please select ID type',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
      return;
    }

    if (_selectedDateArrested == null) {
      Fluttertoast.showToast(
        msg: 'Please select arrest date',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload new image if selected, otherwise keep existing
      String? imageUrl = _editingArrested!.imageUrl;
      if (_selectedImage != null) {
        try {
          imageUrl = await ApiService.uploadImage(File(_selectedImage!.path));
        } catch (e) {
          debugPrint('Error uploading image: $e');
          // Keep existing image if upload fails
        }
      }

      final arrestedCriminal = ArrestedCriminal(
        arrestId: _editingArrested!.arrestId,
        fullname: _fullnameController.text.trim(),
        imageUrl: imageUrl,
        crimeType: _selectedCrimeType ?? '',
        dateArrested: _selectedDateArrested!,
        arrestLocation: _arrestLocationController.text.trim(),
        idType: _selectedIdType,
        idNumber: _idNumberController.text.trim(),
        criminalRecordId: _editingArrested!.criminalRecordId,
        arrestingOfficerId: _editingArrested!.arrestingOfficerId,
        createdAt: _editingArrested!.createdAt,
        updatedAt: DateTime.now(),
      );

      final response = await ApiService.updateArrestedCriminal(
        _editingArrested!.arrestId!,
        arrestedCriminal,
      );
      
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Arrested criminal updated successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        _clearForm();
        _refresh();
        Navigator.of(context).pop();
      } else {
        throw Exception(response['message'] ?? 'Failed to update arrested criminal');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error updating arrested criminal: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> _deleteArrestedCriminal(ArrestedCriminal arrested) async {
    if (arrested.arrestId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Arrested Criminal'),
        content: Text('Are you sure you want to delete ${arrested.fullname}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteArrestedCriminal(arrested.arrestId!);
        
        setState(() {
          _arrestedCriminals.removeWhere((a) => a.arrestId == arrested.arrestId);
        });
        
        Fluttertoast.showToast(
          msg: 'Arrested criminal deleted successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error deleting arrested criminal: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      }
    }
  }

  void _showAddArrestedDialog() {
    _clearForm();
    _showArrestedDialog();
  }

  void _showEditArrestedDialog(ArrestedCriminal arrested) {
    _editingArrested = arrested;
    _fullnameController.text = arrested.fullname ?? '';
    _selectedCrimeType = arrested.crimeType;
    _arrestLocationController.text = arrested.arrestLocation ?? '';
    _idNumberController.text = arrested.idNumber ?? '';
    _selectedIdType = arrested.idType;
    _selectedDateArrested = arrested.dateArrested;
    _showArrestedDialog();
  }

  void _showArrestedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingArrested == null ? 'Add Arrested Criminal' : 'Edit Arrested Criminal'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: _fullnameController,
                    labelText: 'Full Name *',
                    hintText: 'Enter full name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedCrimeType != null && _crimeTypes.contains(_selectedCrimeType) 
                        ? _selectedCrimeType 
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Crime Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: _crimeTypes.map((String crimeType) {
                      return DropdownMenuItem<String>(
                        value: crimeType,
                        child: Text(crimeType),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCrimeType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select crime type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _arrestLocationController,
                    labelText: 'Arrest Location *',
                    hintText: 'Enter arrest location',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter arrest location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedIdType,
                    decoration: const InputDecoration(
                      labelText: 'ID Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.idTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedIdType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select ID type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _idNumberController,
                    labelText: 'ID Number *',
                    hintText: 'Enter ID number',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter ID number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateArrested ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDateArrested = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDateArrested != null
                                ? DateFormat('yyyy-MM-dd').format(_selectedDateArrested!)
                                : 'Select Arrest Date *',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image picker
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedImage != null)
                        Expanded(
                          child: Text(
                            'Image selected',
                            style: TextStyle(color: AppColors.successColor),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearForm();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: _editingArrested == null ? 'Add' : 'Update',
            onPressed: _isSubmitting ? null : (_editingArrested == null ? _addArrestedCriminal : _updateArrestedCriminal),
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Arrested Criminals'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search arrested criminals...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),
          ),
          
          // Arrested criminals list
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredArrestedCriminals.isEmpty
                    ? const Center(
                        child: Text(
                          'No arrested criminals found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          itemCount: _filteredArrestedCriminals.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredArrestedCriminals.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: ElevatedButton(
                                    onPressed: _loadMore,
                                    child: const Text('Load More'),
                                  ),
                                ),
                              );
                            }
                            
                            final arrested = _filteredArrestedCriminals[index];
                            return _buildArrestedCriminalCard(arrested);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddArrestedDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildArrestedCriminalCard(ArrestedCriminal arrested) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile image or placeholder
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: arrested.imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            arrested.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 30,
                                color: AppColors.primaryColor,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.primaryColor,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arrested.fullname ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crime: ${arrested.crimeType ?? 'Unknown'}',
                        style: TextStyle(
                          color: AppColors.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Arrested: ${arrested.dateArrested != null ? DateFormat('yyyy-MM-dd').format(arrested.dateArrested!) : 'Unknown'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (arrested.arrestLocation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Location: ${arrested.arrestLocation}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                      if (arrested.idNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${arrested.idNumber} (${arrested.idType?.replaceAll('_', ' ').toUpperCase() ?? 'Unknown'})',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                // Action buttons
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditArrestedDialog(arrested);
                        break;
                      case 'delete':
                        _deleteArrestedCriminal(arrested);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.primaryColor),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.errorColor),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
