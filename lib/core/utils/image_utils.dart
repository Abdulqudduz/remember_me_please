import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ImageUtils {
  /// Converts pre-copied plane bytes (safe to use after awaits) into an
  /// [InputImage] for ML Kit. Always call this with bytes already copied
  /// out of the CameraImage — never pass live CameraImage data after an await.
  static InputImage? convertFromCopiedBytes({
    required List<Uint8List> planeBytes,
    required int width,
    required int height,
    required List<int> bytesPerRow,
    required List<int> pixelStride,
    required CameraDescription camera,
  }) {
    try {
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      if (Platform.isAndroid) {
        // ML Kit on Android expects NV21, not raw concatenated YUV planes
        final nv21 = _yuv420ToNv21(
          planeBytes: planeBytes,
          width: width,
          height: height,
          bytesPerRow: bytesPerRow,
          pixelStride: pixelStride,
        );
        if (nv21 == null) return null;

        return InputImage.fromBytes(
          bytes: nv21,
          metadata: InputImageMetadata(
            size: Size(width.toDouble(), height.toDouble()),
            rotation: imageRotation,
            format: InputImageFormat.nv21, // ← NV21, not yuv_420_888
            bytesPerRow: width, // ← full image width for NV21
          ),
        );
      } else {
        // iOS BGRA8888: single plane, direct passthrough
        return InputImage.fromBytes(
          bytes: planeBytes[0],
          metadata: InputImageMetadata(
            size: Size(width.toDouble(), height.toDouble()),
            rotation: imageRotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: bytesPerRow[0],
          ),
        );
      }
    } catch (e) {
      debugPrint("InputImage conversion error: $e");
      return null;
    }
  }

  /// Converts YUV_420_888 plane bytes to NV21 (interleaved VU) format.
  /// NV21 layout: [Y rows tightly packed] + [interleaved VU rows]
  static Uint8List? _yuv420ToNv21({
    required List<Uint8List> planeBytes,
    required int width,
    required int height,
    required List<int> bytesPerRow,
    required List<int> pixelStride,
  }) {
    try {
      final yPlane = planeBytes[0];
      final uPlane = planeBytes[1];
      final vPlane = planeBytes[2];

      final int ySize = width * height;
      final int uvSize = width * (height ~/ 2);
      final nv21 = Uint8List(ySize + uvSize);

      // Copy Y plane row by row (strips any stride/padding)
      int nv21Index = 0;
      for (int row = 0; row < height; row++) {
        final srcOffset = row * bytesPerRow[0];
        nv21.setRange(nv21Index, nv21Index + width, yPlane, srcOffset);
        nv21Index += width;
      }

      // Interleave V then U (NV21 = V before U)
      final int uvHeight = height ~/ 2;
      final int uvWidth = width ~/ 2;

      for (int row = 0; row < uvHeight; row++) {
        for (int col = 0; col < uvWidth; col++) {
          final vIndex = row * bytesPerRow[2] + col * pixelStride[2];
          final uIndex = row * bytesPerRow[1] + col * pixelStride[1];
          nv21[nv21Index++] = vPlane[vIndex];
          nv21[nv21Index++] = uPlane[uIndex];
        }
      }

      return nv21;
    } catch (e) {
      debugPrint("YUV→NV21 conversion error: $e");
      return null;
    }
  }
}
