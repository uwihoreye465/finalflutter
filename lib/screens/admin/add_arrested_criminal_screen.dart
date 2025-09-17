import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/arrested_criminal.dart';
import '../../models/criminal_record.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';

class AddArrestedCriminalScreen extends StatefulWidget {
  final ArrestedCriminal? arrestedCriminal;

  const AddArrestedCriminalScreen({super.key, this.arrestedCriminal});

  @override
  State<AddArrestedCriminalScreen> createState() => _AddArrestedCriminalScreenState();
}

class _AddArrestedCriminalScreenState extends State<AddArrestedCriminalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _crimeTypeController = TextEditingController();
  final _arrestLocationController = TextEditingController();
  final _idTypeController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _criminalRecordIdController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _imageUrl;
  File? _selectedImage;
  bool _isLoading = false;
  List<CriminalRecord> _criminalRecords = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.arrestedCriminal != null) {
      _populateFields();
    }
    _loadCriminalRecords();
  }

  void _populateFields() {
    final arrested = widget.arrestedCriminal!;
    _fullnameController.text = arrested.fullname;
    _crimeTypeController.text = arrested.crimeType;
    _arrestLocationController.text = arrested.arrestLocation ?? '';
    _idTypeController.text = arrested.idType ?? '';
    _idNumberController.text = arrested.idNumber ?? '';
    _criminalRecordIdController.text = arrested.criminalRecordId?.toString() ?? '';
    _selectedDate = arrested.dateArrested;
    _imageUrl = arrested.imageUrl;
  }

  Future<void> _loadCriminalRecords() async {
    try {
      final response = await ApiService.getCriminalRecords(page: 1, limit: 100);
      if (mounted) {
        setState(() {
          _criminalRecords = (response['data'] as List)
              .map((json) => CriminalRecord.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _searchCriminalById() async {
    final idNumber = _idNumberController.text.trim();
    if (idNumber.isEmpty) return;

    try {
      final criminal = await ApiService.searchCriminalRecord(idNumber);
      if (criminal != null && mounted) {
        setState(() {
          _fullnameController.text = '${criminal.firstName} ${criminal.lastName}';
          _crimeTypeController.text = criminal.crimeType;
          _idTypeController.text = criminal.idType;
          _criminalRecordIdController.text = criminal.criId?.toString() ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Criminal record found and auto-filled')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No criminal record found with this ID')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching criminal: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            if (_selectedImage != null || _imageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _imageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _imageUrl;
    
    try {
      // Convert image to base64 for now
      // In a real app, you would upload to Supabase Storage here
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // For now, we'll use a data URL format
      // In production, upload to Supabase and get the public URL
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
      return null;
    }
  }

  Future<void> _saveArrestedCriminal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image if selected
      final imageUrl = await _uploadImage();
      
      final arrested = ArrestedCriminal(
        arrestId: widget.arrestedCriminal?.arrestId,
        fullname: _fullnameController.text.trim(),
        imageUrl: imageUrl,
        crimeType: _crimeTypeController.text.trim(),
        dateArrested: _selectedDate,
        arrestLocation: _arrestLocationController.text.trim().isEmpty
            ? null
            : _arrestLocationController.text.trim(),
        idType: _idTypeController.text.trim().isEmpty
            ? null
            : _idTypeController.text.trim(),
        idNumber: _idNumberController.text.trim().isEmpty
            ? null
            : _idNumberController.text.trim(),
        criminalRecordId: _criminalRecordIdController.text.trim().isEmpty
            ? null
            : int.tryParse(_criminalRecordIdController.text.trim()),
      );

      if (widget.arrestedCriminal != null) {
        await ApiService.updateArrestedCriminal(
          widget.arrestedCriminal!.arrestId!,
          arrested,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arrested criminal updated successfully')),
          );
        }
      } else {
        await ApiService.addArrestedCriminal(arrested);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arrested criminal added successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving arrested criminal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.arrestedCriminal != null
            ? 'Edit Arrested Criminal'
            : 'Add Arrested Criminal'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _selectedImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _imageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _imageUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[400],
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_selectedImage != null || _imageUrl != null ? 'Change Photo' : 'Add Photo'),
                ),
              ),
              const SizedBox(height: 24),

              // ID Search Section
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _idNumberController,
                      labelText: 'ID Number',
                      hintText: 'Enter ID number to search',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _searchCriminalById,
                    child: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Form Fields
              CustomTextField(
                controller: _fullnameController,
                labelText: 'Full Name',
                hintText: 'Enter full name',
                validator: Validators.validateRequired,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _crimeTypeController,
                labelText: 'Crime Type',
                hintText: 'Enter type of crime',
                validator: Validators.validateRequired,
              ),
              const SizedBox(height: 16),

              // Date Selection
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        'Date Arrested: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _arrestLocationController,
                labelText: 'Arrest Location',
                hintText: 'Enter arrest location',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _idTypeController,
                labelText: 'ID Type',
                hintText: 'e.g., National ID, Passport',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _criminalRecordIdController,
                labelText: 'Criminal Record ID',
                hintText: 'Enter criminal record ID',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Save Button
              CustomButton(
                text: widget.arrestedCriminal != null ? 'Update' : 'Add Arrested Criminal',
                onPressed: _isLoading ? null : _saveArrestedCriminal,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _crimeTypeController.dispose();
    _arrestLocationController.dispose();
    _idTypeController.dispose();
    _idNumberController.dispose();
    _criminalRecordIdController.dispose();
    super.dispose();
  }
}
