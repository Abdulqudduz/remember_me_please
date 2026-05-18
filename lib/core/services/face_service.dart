import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  Interpreter? _interpreter;

  /// Load the TFLite model once during app initialization
  Future<void> loadModel() async {
    final options = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(
      'assets/mobilefacenet.tflite',
      options: options,
    );
  }

  /// Use when SAVING a new person from the gallery or a captured [File]
  Future<Float32List> getEmbedding(File imageFile, Face face) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? fullImage = img.decodeImage(bytes);
    if (fullImage == null) throw Exception("Failed to decode image");
    return _processImage(fullImage, face);
  }

  /// Use for the LIVE CAMERA STREAM.
  /// Accepts pre-copied plane bytes — safe to call after any await because
  /// the live CameraImage buffer has already been released by this point.
  Future<Float32List> getEmbeddingFromBytes({
    required List<Uint8List> planeBytes,
    required int width,
    required int height,
    required List<int> bytesPerRow,
    required List<int> pixelStride,
    required Face face,
    required int sensorOrientation,
  }) async {
    img.Image convertedImage = _convertYUV420FromBytes(
      planeBytes: planeBytes,
      width: width,
      height: height,
      bytesPerRow: bytesPerRow,
      pixelStride: pixelStride,
    );
    if (sensorOrientation != 0) {
      convertedImage = img.copyRotate(convertedImage, angle: sensorOrientation);
    }
    return _processImage(convertedImage, face);
  }

  /// Internal: Crop → Resize → Normalize → Inference
  Future<Float32List> _processImage(img.Image image, Face face) async {
    if (_interpreter == null) throw Exception("Interpreter not initialized");

    // Clamp bounding box to image dimensions to avoid out-of-bounds crop
    final int cropX = face.boundingBox.left.toInt().clamp(0, image.width - 1);
    final int cropY = face.boundingBox.top.toInt().clamp(0, image.height - 1);
    final int cropW = face.boundingBox.width.toInt().clamp(
      1,
      image.width - cropX,
    );
    final int cropH = face.boundingBox.height.toInt().clamp(
      1,
      image.height - cropY,
    );

    // A. Crop to the face bounding box
    final img.Image faceCrop = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    // B. Resize to 112×112 (standard MobileFaceNet input)
    final img.Image resized = img.copyResize(faceCrop, width: 112, height: 112);

    // C. Convert pixels to Float32 and normalize to [-1, 1]
    final input = Float32List(1 * 112 * 112 * 3);
    int pixelIndex = 0;
    for (final pixel in resized) {
      input[pixelIndex++] = (pixel.r - 127.5) / 127.5;
      input[pixelIndex++] = (pixel.g - 127.5) / 127.5;
      input[pixelIndex++] = (pixel.b - 127.5) / 127.5;
    }

    // D. Prepare 192-dim output vector
    final output = List<double>.filled(192, 0).reshape([1, 192]);

    // E. Run inference
    _interpreter!.run(input.reshape([1, 112, 112, 3]), output);

    return Float32List.fromList(List<double>.from(output[0]));
  }

  /// Converts pre-copied YUV_420_888 plane bytes to an [img.Image] (RGB).
  /// Accepts copied data so it is safe to call inside async methods.
  img.Image _convertYUV420FromBytes({
    required List<Uint8List> planeBytes,
    required int width,
    required int height,
    required List<int> bytesPerRow,
    required List<int> pixelStride,
  }) {
    final imgImage = img.Image(width: width, height: height);

    final yPlane = planeBytes[0];
    final uPlane = planeBytes[1];
    final vPlane = planeBytes[2];

    final yRowStride = bytesPerRow[0];
    final uvRowStride = bytesPerRow[1];
    final uvPixelStride = pixelStride[1];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = (y >> 1) * uvRowStride + (x >> 1) * uvPixelStride;
        final yIndex = y * yRowStride + x;

        // Guard against index out-of-range on edge devices
        if (yIndex >= yPlane.length || uvIndex >= uPlane.length) continue;

        final yp = yPlane[yIndex];
        final up = uPlane[uvIndex];
        final vp = vPlane[uvIndex];

        final r = (yp + 1.370705 * (vp - 128)).toInt().clamp(0, 255);
        final g = (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128))
            .toInt()
            .clamp(0, 255);
        final b = (yp + 1.732446 * (up - 128)).toInt().clamp(0, 255);

        imgImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return imgImage;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
