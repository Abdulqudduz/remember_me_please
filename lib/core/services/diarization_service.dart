import 'dart:io';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

class DiarizationService {
  /// Returns the diarization segments and the raw wave data
  Future<Map<String, dynamic>> getSpeakerSegments({
    required String audioPath,
    required String segmentationModelPath,
    required String embeddingModelPath,
  }) async {
    if (!File(audioPath).existsSync()) throw Exception("Audio file missing.");
    if (!File(segmentationModelPath).existsSync())
      throw Exception("Segmentation model missing.");
    if (!File(embeddingModelPath).existsSync())
      throw Exception("Embedding model missing.");

    final segmentationConfig =
        sherpa_onnx.OfflineSpeakerSegmentationModelConfig(
          pyannote: sherpa_onnx.OfflineSpeakerSegmentationPyannoteModelConfig(
            model: segmentationModelPath,
          ),
        );
    final embeddingConfig = sherpa_onnx.SpeakerEmbeddingExtractorConfig(
      model: embeddingModelPath,
    );

    // Set to 2 speakers, or -1 for auto-detect
    final clusteringConfig = sherpa_onnx.FastClusteringConfig(
      numClusters: 2,
      threshold: 0.5,
    );

    final diarizationConfig = sherpa_onnx.OfflineSpeakerDiarizationConfig(
      segmentation: segmentationConfig,
      embedding: embeddingConfig,
      clustering: clusteringConfig,
      minDurationOn: 0.2,
      minDurationOff: 0.5,
    );

    final sd = sherpa_onnx.OfflineSpeakerDiarization(diarizationConfig);
    final waveData = sherpa_onnx.readWave(audioPath);
    final segments = sd.process(samples: waveData.samples);

    return {'segments': segments, 'waveData': waveData};
  }
}
