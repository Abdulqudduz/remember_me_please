// core/utils/wav_helper.dart
// Utility for converting raw PCM float samples into a WAV byte buffer.
// Adapted directly from the sample/ reference folder.
import 'dart:typed_data';

/// Converts a list of PCM float samples into a valid WAV file byte buffer.
///
/// The resulting [Uint8List] can be written directly to a .wav file or played
/// back using an audio player that accepts bytes.
class WavHelper {
  /// Encodes [samples] at the given [sampleRate] into a 16-bit mono WAV format.
  ///
  /// The WAV header is written with the standard RIFF/WAVE/fmt/data chunks
  /// before the interleaved sample data. Each float sample is clamped to the
  /// signed 16-bit range and packed in little-endian order.
  static Uint8List pcmToWav(List<double> samples, int sampleRate) {
    final bytes = BytesBuilder();

    // Helper to write a 16-bit signed integer in little-endian byte order
    void writeInt16(int v) {
      final b = ByteData(2)..setInt16(0, v, Endian.little);
      bytes.add(b.buffer.asUint8List());
    }

    // Helper to write a 32-bit signed integer in little-endian byte order
    void writeInt32(int v) {
      final b = ByteData(4)..setInt32(0, v, Endian.little);
      bytes.add(b.buffer.asUint8List());
    }

    // RIFF chunk descriptor
    bytes.add("RIFF".codeUnits);
    // Total file size minus the 8-byte RIFF header
    writeInt32(36 + samples.length * 2);
    bytes.add("WAVE".codeUnits);

    // fmt sub-chunk (PCM format descriptor)
    bytes.add("fmt ".codeUnits);
    writeInt32(16); // Sub-chunk size for PCM
    writeInt16(1); // Audio format: 1 = PCM (uncompressed)
    writeInt16(1); // Number of channels: 1 = mono
    writeInt32(sampleRate); // Sample rate in Hz
    writeInt32(sampleRate * 2); // Byte rate = sampleRate * numChannels * bitsPerSample/8
    writeInt16(2); // Block align = numChannels * bitsPerSample/8
    writeInt16(16); // Bits per sample

    // data sub-chunk (actual audio samples)
    bytes.add("data".codeUnits);
    writeInt32(samples.length * 2); // Data size in bytes

    for (final s in samples) {
      // Clamp and convert float [-1.0, 1.0] to signed 16-bit integer
      final v = (s * 32767).clamp(-32768, 32767).toInt();
      writeInt16(v);
    }

    return bytes.toBytes();
  }
}
