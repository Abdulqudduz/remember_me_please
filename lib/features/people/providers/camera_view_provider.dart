import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:remember_me_please/core/services/active_person_tracker.dart';
import 'package:remember_me_please/core/services/face_service.dart';
import 'package:remember_me_please/core/utils/image_utils.dart';
import 'package:remember_me_please/data/models/person_model.dart';
import 'package:remember_me_please/data/repositories/person_repository.dart';

class CameraProvider extends ChangeNotifier {
  final PersonRepository personRepository;

  CameraController? controller;
  List<CameraDescription> cameras = [];

  bool isInitialized = false;
  bool isProcessing = false;

  int cameraIndex = 0;

  PersonModel? matchedPerson;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: false,
    ),
  );

  final FaceService _faceService = FaceService();

  CameraProvider({required this.personRepository});

  // INITIALIZATION

  Future<void> initialize() async {
    resetSession(); // clean start every time
    cameras = await availableCameras();
    if (cameras.isEmpty) return;
    // Always start with back camera
    cameraIndex = cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    // Fallback if no back camera exists
    if (cameraIndex == -1) {
      cameraIndex = 0;
    }

    await _faceService.loadModel();
    await _setupCamera();
  }

  Future<void> _setupCamera() async {
    controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller!.initialize();

      if (controller == null) return;

      isInitialized = true;
      notifyListeners();

      await controller!.startImageStream(_processCameraFrame);
    } catch (e) {
      debugPrint("Camera Init Error: $e");
    }
  }

  // FRAME PROCESSING

  void _processCameraFrame(CameraImage image) {
    if (!isInitialized || isProcessing || controller == null) return;

    isProcessing = true;

    final copiedPlaneBytes = image.planes
        .map((p) => Uint8List.fromList(p.bytes))
        .toList();

    final width = image.width;
    final height = image.height;

    final bytesPerRow = image.planes.map((p) => p.bytesPerRow).toList();

    final pixelStride = image.planes.map((p) => p.bytesPerPixel ?? 1).toList();

    _handleFrame(
      copiedPlaneBytes: copiedPlaneBytes,
      width: width,
      height: height,
      bytesPerRow: bytesPerRow,
      pixelStride: pixelStride,
      camera: cameras[cameraIndex],
    );
  }

  Future<void> _handleFrame({
    required List<Uint8List> copiedPlaneBytes,
    required int width,
    required int height,
    required List<int> bytesPerRow,
    required List<int> pixelStride,
    required CameraDescription camera,
  }) async {
    try {
      if (!isInitialized) return;

      final inputImage = ImageUtils.convertFromCopiedBytes(
        planeBytes: copiedPlaneBytes,
        width: width,
        height: height,
        bytesPerRow: bytesPerRow,
        pixelStride: pixelStride,
        camera: camera,
      );

      if (inputImage == null || !isInitialized) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (!isInitialized) return;

      if (faces.isNotEmpty) {
        await _recognizeFace(
          copiedPlaneBytes: copiedPlaneBytes,
          width: width,
          height: height,
          bytesPerRow: bytesPerRow,
          pixelStride: pixelStride,
          face: faces.first,
          sensorOrientation: camera.sensorOrientation, // ALREADY CORRECT HERE
        );
      } else {
        if (matchedPerson != null) {
          matchedPerson = null;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Frame processing error: $e");
    } finally {
      isProcessing = false;
    }
  }

  Future<void> _recognizeFace({
    required List<Uint8List> copiedPlaneBytes,
    required int width,
    required int height,
    required List<int> bytesPerRow,
    required List<int> pixelStride,
    required Face face,
    required int sensorOrientation,
  }) async {
    try {
      if (!isInitialized) return;

      final embedding = await _faceService.getEmbeddingFromBytes(
        planeBytes: copiedPlaneBytes,
        width: width,
        height: height,
        bytesPerRow: bytesPerRow,
        pixelStride: pixelStride,
        face: face,
        sensorOrientation: sensorOrientation,
      );

      final result = personRepository.findMatchingPerson(embedding);

      if (!isInitialized) return;

      if (result != null && result.id != matchedPerson?.id) {
        matchedPerson = result;

        // =========================================================
        // THE INTERCEPT: Tell the AI Tracker who we just saw!
        // =========================================================
        ActivePersonTracker().registerFaceMatch(
          result.name,
          result.profilePicturePath,
        );

        notifyListeners();
        debugPrint("MATCH FOUND: ${result.name}");
      }
    } catch (e) {
      debugPrint("Recognition error: $e");
    }
  }
  // CAMERA SWITCHING

  Future<void> toggleCamera() async {
    if (cameras.length < 2) return;

    await _disposeCameraInternal();

    cameraIndex = (cameraIndex + 1) % cameras.length;

    await _setupCamera();
  }

  // SAFE DISPOSAL (IMPORTANT)

  void disposeCameraSync() {
    isInitialized = false;
    isProcessing = false;
    matchedPerson = null;

    final cam = controller;
    controller = null;

    // DO NOT notifyListeners here

    if (cam != null) {
      try {
        cam.stopImageStream().then((_) {
          cam.dispose();
        });
      } catch (e) {
        debugPrint("Camera dispose error: $e");
      }
    }
  }

  Future<void> _disposeCameraInternal() async {
    isInitialized = false;
    isProcessing = false;
    matchedPerson = null;

    final cam = controller;
    controller = null;

    if (cam != null) {
      try {
        if (cam.value.isStreamingImages) {
          await cam.stopImageStream();
        }
        await cam.dispose();
      } catch (e) {
        debugPrint("Camera dispose error: $e");
      }
    }
  }

  void resetSession() {
    matchedPerson = null;
    isProcessing = false;

    // ensures next session is clean
    isInitialized = false;

    debugPrint('This is match person current value: $matchedPerson');
    debugPrint('This is isProcessing current value: $isProcessing');
    debugPrint('This is isInitialized current value: $isInitialized');

    notifyListeners();
  }

  // PROVIDER DISPOSE

  @override
  void dispose() {
    disposeCameraSync();
    _faceDetector.close();
    _faceService.dispose();
    super.dispose();
  }
}
