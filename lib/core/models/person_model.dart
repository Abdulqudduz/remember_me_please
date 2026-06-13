import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';

@Entity()
class PersonModel {
  @Id() // To be explicit
  int id;

  final String name;
  final String relationship;
  final String memoryNote1;
  final String memoryNote2;
  final String profilePicturePath;

  // It a 192 dimensions based on specific model
  @Property(type: PropertyType.floatVector)
  @HnswIndex(dimensions: 192, distanceType: VectorDistanceType.euclidean)
  final Float32List? faceEmbedding;

  PersonModel({
    this.id = 0,
    required this.name,
    required this.relationship,
    required this.memoryNote1,
    required this.memoryNote2,
    required this.profilePicturePath,
    this.faceEmbedding,
  });

  PersonModel copyWith({
    int? id,
    String? name,
    String? relationship,
    String? memoryNote1,
    String? memoryNote2,
    String? profilePicturePath,
    Float32List? faceEmbedding,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      memoryNote1: memoryNote1 ?? this.memoryNote1,
      memoryNote2: memoryNote2 ?? this.memoryNote2,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
    );
  }
}
