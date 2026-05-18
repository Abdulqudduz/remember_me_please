import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/data/models/person_model.dart';
import 'package:remember_me_please/features/people/pages/person_detail_page.dart';
import 'package:remember_me_please/features/people/providers/camera_view_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

class CameraViewPage extends StatefulWidget {
  const CameraViewPage({super.key});

  @override
  State<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage> {
  late CameraProvider _cameraProvider;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState(); 

    _cameraProvider = context.read<CameraProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraProvider.initialize();
    });
    _cameraProvider.addListener(_onCameraUpdate);
  }

  void _onCameraUpdate() {
    final person = _cameraProvider.matchedPerson;

    if (person == null) return;
    if (_hasNavigated) return;

    _hasNavigated = true;
    _cameraProvider.disposeCameraSync();

    Future.delayed(const Duration(microseconds: 100), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PersonDetailPage(
            personName: person.name,
            relationship: person.relationship,
            description: person.memoryNote1,
            profilePicturePath: person.profilePicturePath,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _cameraProvider.disposeCameraSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CameraProvider>();

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 30, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Who is with me?',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Expanded(child: _buildCameraPreview(context, provider)),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              provider.matchedPerson == null
                  ? 'Point your camera at the person'
                  : 'We found someone!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 48),
          _buildActionButtons(context, provider),

          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context, CameraProvider provider) {
    final bool faceFound = provider.matchedPerson != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          // Live camera feed
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(32),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: provider.isInitialized && provider.controller != null
                  ? CameraPreview(provider.controller!)
                  : const Center(
                      child: CircularProgressIndicator(color: AppColors.white),
                    ),
            ),
          ),

          // Animated dashed oval — green when a face is recognised
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.45,
              child: CustomPaint(
                painter: DashedOvalPainter(
                  color: faceFound
                      ? AppColors.green.withValues(alpha: 0.9)
                      : AppColors.surfaceContainerLow.withValues(alpha: 0.8),
                  strokeWidth: 4,
                ),
              ),
            ),
          ),

          // Instruction label — only shown when no face is matched yet
          if (!faceFound)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Text(
                    "Center the person's face",
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, PersonModel person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonDetailPage(
          personName: person.name,
          relationship: person.relationship,
          description: person.memoryNote1,
          profilePicturePath: person.profilePicturePath,
        ),
      ),
    );
  }

  Widget _buildTextButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(48),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: AppColors.surfaceVariant,
        padding: EdgeInsets.zero,
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onTap,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CameraProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTextButton('CANCEL', () => Navigator.of(context).pop()),
          _buildIconButton(
            Icons.flip_camera_ios_outlined,
            'SWITCH',
            provider.toggleCamera,
          ),
        ],
      ),
    );
  }
}

class DashedOvalPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const DashedOvalPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

    const double dashWidth = 10;
    const double dashSpace = 8;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  // ✅ Correctly re-paints when the oval colour changes (e.g. face found)
  bool shouldRepaint(DashedOvalPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
