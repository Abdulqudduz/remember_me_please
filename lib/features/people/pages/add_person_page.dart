import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/people_provider.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/widgets/app_scaffold.dart';

class AddPersonPage extends StatefulWidget {
  int? id;
  final String? personName;
  final String? relationship;
  final String? description;
  final String? profilePicturePath;

  AddPersonPage({
    super.key,
    this.id,
    this.personName,
    this.relationship,
    this.description,
    this.profilePicturePath,
  });

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _biographyController1 = TextEditingController();
  final _biographyController2 = TextEditingController();
  String _selectedRelationship = 'Family';
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pre-populate the fields IF we are in Edit Mode (id != null)
    if (widget.id != null && widget.id! > 0) {
      _nameController.text = widget.personName ?? '';
      _biographyController1.text = widget.description ?? '';

      // Ensure the passed relationship exists in our dropdown options
      if (widget.relationship != null && widget.relationship!.isNotEmpty) {
        _selectedRelationship = widget.relationship!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _biographyController1.dispose();
    _biographyController2.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _savePerson() {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null && widget.profilePicturePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image'),
            backgroundColor: AppColors.redAccent,
          ),
        );
        return;
      }

      final peopleProvider = Provider.of<PeopleProvider>(
        context,
        listen: false,
      );

      try {
        peopleProvider.addPerson(
          id: widget.id ?? 0,
          name: _nameController.text.trim(),
          relationship: _selectedRelationship,
          imageFile: _imageFile ?? File(widget.profilePicturePath!),
          memoryNote1: _biographyController1.text.trim(),
          memoryNote2: _biographyController2.text.trim(),
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, IconData> relationshipOptions = {
      'Family': Icons.family_restroom,
      'Friend': Icons.people,
      'Doctor': Icons.local_hospital,
      'Other': Icons.more_horiz,
    };

    // Determine if we are updating an existing person
    final isEditing = widget.id != null && widget.id! > 0;

    return AppScaffold(
      appBar: AppBar(
        // Dynamic Title based on mode
        title: Text(
          isEditing ? 'Edit Person' : 'Add New Person',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: AppColors.transparent,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: AppColors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.scaffoldBackground,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.photo_library,
                                color: AppColors.primary,
                              ),
                              title: const Text('Gallery'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.camera_alt,
                                color: AppColors.primary,
                              ),
                              title: const Text('Camera'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      image:
                          _imageFile != null ||
                              widget.profilePicturePath != null
                          ? DecorationImage(
                              image: FileImage(
                                _imageFile ?? File(widget.profilePicturePath!),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        _imageFile == null && widget.profilePicturePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 40,
                                color: AppColors.primary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add Cover',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              CustomTextField(
                label: 'Name',
                hint: 'e.g. Martha Jones',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomDropdown<String>(
                label: 'Relationship',
                hint: 'Select relationship',
                value: _selectedRelationship,
                items: relationshipOptions.keys.toList(),
                itemLabelBuilder: (value) => value,
                prefixIcon: relationshipOptions[_selectedRelationship],
                onChanged: (value) {
                  setState(() {
                    _selectedRelationship = value!;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a relationship'
                    : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Biography',
                hint: 'Tell a short story about this person...',
                controller: _biographyController1,
                maxLines: 4,
                validator: (value) {
                  // Ensure we do not override the existing value unnecessarily
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write a short bio';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Memory',
                hint: 'Tell one found memory you shared together',
                controller: _biographyController2,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write a memory';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              Consumer<PeopleProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _savePerson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(
                            color: AppColors.onPrimary,
                          )
                        : Text(
                            isEditing ? 'Update Person' : 'Save Person',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
