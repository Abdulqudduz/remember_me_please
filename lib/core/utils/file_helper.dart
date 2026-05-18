import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class FileHelpers {
  static Future<String> getCopyOfAsset(
    String assetPath,
    String filename,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await file.writeAsBytes(bytes);
    }
    return file.path;
  }

  static Future<File> saveFloat32ListToWav(
    Float32List samples,
    int sampleRate,
    String filePath,
  ) async {
    final int16List = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      double val = samples[i].clamp(-1.0, 1.0);
      int16List[i] = (val * 32767).toInt();
    }

    int byteRate = sampleRate * 2;
    int dataSize = int16List.lengthInBytes;
    int fileSize = 36 + dataSize;
    final byteData = ByteData(44);

    void writeString(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        byteData.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    byteData.setUint32(4, fileSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    byteData.setUint32(40, dataSize, Endian.little);

    final builder = BytesBuilder()
      ..add(byteData.buffer.asUint8List())
      ..add(int16List.buffer.asUint8List());

    return await File(filePath).writeAsBytes(builder.toBytes());
  }
}
