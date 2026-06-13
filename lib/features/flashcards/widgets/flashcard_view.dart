import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/core/models/flashcard_model.dart';
import 'package:remember_me_please/features/flashcards/providers/flashcard_provider.dart';
import 'package:remember_me_please/features/flashcards/widgets/flashcard_action_button.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';

class FlashcardView extends StatefulWidget {
  final String category;
  final FlashcardModel card;
  final VoidCallback onIwasRight;
  final VoidCallback onIwasWrong;

  const FlashcardView({
    super.key,
    required this.category,
    required this.card,
    required this.onIwasRight,
    required this.onIwasWrong,
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flipAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final isFront = _flipAnimation.value < math.pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_flipAnimation.value),
          child: isFront
              ? _buildFront(context)
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _buildBack(context),
                ),
        );
      },
    );
  }

  Widget _buildFront(BuildContext context) {
    final question = widget.card.question;
    final subtitle =
        widget.card.subtitle ??
        (widget.category == 'People' ? 'Unknown Person' : widget.category);
    final provider = context.watch<FlashcardProvider>();
    final state = provider.getCategoryState(widget.category);

    return Stack(
      alignment: Alignment.center,
      children: [
        _buildBackgroundCard(),
        _buildMainCard(
          child: Column(
            children: [
              Text(
                question,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildImage(
                  onImageTap: () {
                    if (widget.card.frontCardImage != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OpenImagePreview(
                            imagePreviewedPath: widget.card.frontCardImage!,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (!state.isRevealed)
                GestureDetector(
                  onTap: () => context.read<FlashcardProvider>().revealCard(
                    widget.category,
                  ),
                  child: _buildRevealButton(),
                )
              else
                Column(
                  children: [
                    // Text(
                    //   widget.card.title,
                    //   style: const TextStyle(fontSize: 28),
                    // ),
                    // const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FlashcardActionButton(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          onTap: widget.onIwasWrong,
                          icon: Icons.close,
                          label: 'I Was wrong',
                        ),
                        FlashcardActionButton(
                          backgroundColor: AppColors.primary,
                          onTap: () {
                            _flipController.reset();
                            _flipController.forward();
                          },
                          icon: Icons.sync,
                          label: 'turn',
                        ),

                        FlashcardActionButton(
                          backgroundColor: AppColors.secondary,
                          onTap: widget.onIwasRight,
                          icon: Icons.check,
                          label: 'I Was right',
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBack(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildBackgroundCard(),
        _buildMainCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "More Details",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                widget.card.moreDetails ??
                    "No additional information available.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => _flipController.reverse(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync),
                      SizedBox(width: 6),
                      Text(
                        "Back",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundCard() {
    return Transform.translate(
      offset: const Offset(8, 8),
      child: Transform.rotate(
        angle: 1.5 * math.pi / 180,
        child: Container(
          width: double.infinity,
          height: 420,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(32),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildImage({required final VoidCallback onImageTap}) {
    return GestureDetector(
      onTap: onImageTap,
      child: Hero(
        tag: widget.card.frontCardImage ?? '',
        child: Container(
          decoration: BoxDecoration(
            image: widget.card.frontCardImage != null
                ? DecorationImage(
                    image: FileImage(File(widget.card.frontCardImage!)),
                    fit: BoxFit.cover,
                  )
                : null,
            borderRadius: BorderRadius.circular(24),
            color: AppColors.surfaceContainer,
          ),
          child: widget.card.frontCardImage == null
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              : Center(
                  child: Text(
                    'Tap to view image',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontStyle: FontStyle.italic,
                      fontSize: 20,
                      color: AppColors.onPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRevealButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.tertiary, AppColors.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility, color: AppColors.onTertiary),
          SizedBox(width: 8),
          Text(
            'Reveal',
            style: TextStyle(
              color: AppColors.onTertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class OpenImagePreview extends StatelessWidget {
  final String imagePreviewedPath;

  const OpenImagePreview({super.key, required this.imagePreviewedPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      // SafeArea prevents the close button from getting cut off by status bars or notches
      body: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Aligns close button to the left
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                color: AppColors.darkOnSurface,
              ),
            ),
            // Expanded sits directly in the Column to take up all available middle space
            Expanded(
              child: Center(
                child: Hero(
                  tag: imagePreviewedPath,
                  child: Image.file(
                    File(imagePreviewedPath),
                    fit: BoxFit
                        .contain, // Ensures the whole image fits on screen without cropping
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
