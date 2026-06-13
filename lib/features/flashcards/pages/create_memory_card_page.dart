import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/core/widgets/app_scaffold.dart';
import 'package:remember_me_please/core/widgets/form_widgets.dart';
import 'package:remember_me_please/core/models/flashcard_model.dart';
import 'package:remember_me_please/data/repositories/flashcard_repository.dart';
import 'package:remember_me_please/features/flashcards/providers/flashcard_provider.dart';
import 'package:remember_me_please/features/people/widgets/photo_uploader_widget.dart';
import 'package:remember_me_please/main.dart';

class CreateMemoryCardPage extends StatefulWidget {
  const CreateMemoryCardPage({super.key});

  @override
  State<CreateMemoryCardPage> createState() => _CreateMemoryCardPageState();
}

class _CreateMemoryCardPageState extends State<CreateMemoryCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _moreDetailsController = TextEditingController();
  FlashcardCategory _selectedCategory = FlashcardCategory.person;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _moreDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveCard() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<FlashcardProvider>();
      final newCard = FlashcardModel(
        question: _nameController.text,
        categoryIndex: _selectedCategory.index,
        title: _nameController.text,
        subtitle: _relationshipController.text,
        moreDetails: _moreDetailsController.text,
        frontCardImage: _imageFile?.path,
      );
      provider.addFlashcard(newCard);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory Card Created!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  void onRefinePressed(TextEditingController controller, BuildContext context) {
    if (controller.text.isNotEmpty) {
      controller.text = 'Refined: ${controller.text}';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter details to refine.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Memory Card',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Guided Voice Tooltip (from screen.html)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.tertiary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Take your time. A memory card helps you remember important things or special moments. Add a photo if you have one. If you need help writing, tap the circle button on the screen. The smart helper will fix your words.',
                          style: TextStyle(
                            color: AppColors.onTertiaryContainer.withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Improved Category Selector
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle (Requested)
                Text(
                  'What type of memory is this?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CategoryCard(
                        label: 'Person',
                        icon: Icons.person_rounded,
                        isSelected:
                            _selectedCategory == FlashcardCategory.person,
                        onTap: () => setState(
                          () => _selectedCategory = FlashcardCategory.person,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CategoryCard(
                        label: 'Reminder',
                        icon: Icons.notifications_active_rounded,
                        isSelected:
                            _selectedCategory == FlashcardCategory.reminder,
                        onTap: () => setState(
                          () => _selectedCategory = FlashcardCategory.reminder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CategoryCard(
                        label: 'Moment',
                        icon: Icons.auto_awesome_rounded,
                        isSelected:
                            _selectedCategory == FlashcardCategory.moment,
                        onTap: () => setState(
                          () => _selectedCategory = FlashcardCategory.moment,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Inputs
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Front of card',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      suffixIcon: CircleAvatar(
                        child: IconButton(
                          onPressed: () =>
                              onRefinePressed(_nameController, context),
                          icon: const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      label: 'Main memory',
                      hint: 'e.g. Who or what is this?',
                      controller: _nameController,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a prompt' : null,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      suffixIcon: CircleAvatar(
                        child: IconButton(
                          onPressed: () =>
                              onRefinePressed(_relationshipController, context),
                          icon: const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      label: 'Relationship',
                      hint: 'e.g. Your son, Your keys, Your daughter, etc.',
                      controller: _relationshipController,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a prompt' : null,
                    ),
                    const SizedBox(height: 15),
                    const Text('Visual aid (optional)'),
                    const SizedBox(height: 8),
                    PhotoUploaderWidget(
                      onTap: _pickImage,
                      imageFile: _imageFile,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Back of card (Details)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      suffixIcon: CircleAvatar(
                        child: IconButton(
                          onPressed: () =>
                              onRefinePressed(_moreDetailsController, context),
                          icon: const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),

                      label: 'Helpful details',
                      hint: 'e.g. This is Sarah, your daughter.',
                      controller: _moreDetailsController,
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter the answer' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CreateCardButton(
                  icon: Icons.save_outlined,
                  label: 'Create Card',
                  color: AppColors.primary,
                  onPressed: _saveCard,
                ),
                const SizedBox(height: 24),

                // Action Button
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
          border: Border.all(
            // Replaced hardcoded Colors.transparent with AppColors.transparent to match design system
            color: isSelected
                ? AppColors.transparent
                : AppColors.outlineVariant.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.onPrimary.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.onPrimary : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateCardButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  final String label;
  final TextStyle? labelStyle;
  final IconData icon;
  final Color? iconColor;
  final double height;
  final double borderRadius;

  const CreateCardButton({
    super.key,
    required this.onPressed,
    required this.color,
    required this.label,
    required this.icon,
    this.iconColor,
    this.height = 72,
    this.borderRadius = 36,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          // Replaced hardcoded Colors.transparent with AppColors.transparent to match design system
          backgroundColor: AppColors.transparent,
          // Replaced hardcoded Colors.transparent with AppColors.transparent to match design system
          shadowColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? AppColors.onPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style:
                  labelStyle ??
                  const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
