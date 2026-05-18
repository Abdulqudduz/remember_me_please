import 'dart:io';
import 'dart:typed_data'; // Required for Float32List
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'; // ML Kit
import 'package:remember_me_please/core/utils/file_utils.dart';
import 'package:remember_me_please/data/repositories/person_repository.dart';
import 'package:remember_me_please/data/models/person_model.dart';
import 'package:remember_me_please/core/services/face_service.dart';

class PeopleProvider with ChangeNotifier {
  final PersonRepository personRepository;

  PeopleProvider({required this.personRepository}) {
    loadPeople();
  }
  final List<PersonModel> _people = [];
  bool _isLoading = false;

  List<PersonModel> get people => [..._people];
  bool get isLoading => _isLoading;

  Future<void> addPerson({
    int id = 0, // Default to 0 for a new person
    required String name,
    required String relationship,
    required File imageFile,
    required String memoryNote1,
    required String memoryNote2,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final FileUtils fileService = FileUtils();

      // Save the HIGH-RES image for the UI
      final String savedImage = await fileService.saveImage(imageFile);

      // If updating an existing person, delete their old image file safely
      if (id > 0) {
        final oldPersonIndex = _people.indexWhere((p) => p.id == id);
        if (oldPersonIndex != -1) {
          final oldImagePath = _people[oldPersonIndex].profilePicturePath;
          try {
            File(oldImagePath).deleteSync();
          } catch (e) {
            debugPrint("Could not delete old image: $e");
          }
        }
      }

      // ========================================================
      // Generate embedding in memory before saving
      // ========================================================
      Float32List? generatedEmbedding;
      try {
        final faceDetector = FaceDetector(
          options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
        );

        // Let ML Kit find the face in the high-res image
        final inputImage = InputImage.fromFile(imageFile);
        final faces = await faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          // If a face is found, pass it to the TFLite model to generate the 192-dimension vector
          final faceService = FaceService();
          await faceService.loadModel();
          generatedEmbedding = await faceService.getEmbedding(
            imageFile,
            faces.first,
          );
        } else {
          debugPrint(
            "UI Alert: No face detected in the selected profile picture.",
          );
        }

        faceDetector.close();
      } catch (e) {
        debugPrint("Error generating face embedding: $e");
      }
      // ========================================================

      // Create the Model and attach the new faceEmbedding
      final personToSave = PersonModel(
        id: id,
        name: name,
        relationship: relationship,
        memoryNote1: memoryNote1,
        memoryNote2: memoryNote2,
        profilePicturePath: savedImage, // The high-res UI image
        faceEmbedding: generatedEmbedding, // The 192-dimension AI memory
      );

      // Save to database
      int resultId = personRepository.addNewPerson(personToSave);

      if (resultId > 0) {
        // Give the model its final, official ID
        final finalPerson = personToSave.copyWith(id: resultId);

        // Clean List Management
        final existingIndex = _people.indexWhere((p) => p.id == id);
        if (existingIndex != -1) {
          _people[existingIndex] = finalPerson;
          debugPrint("Updated existing person with ID: $resultId");
        } else {
          _people.add(finalPerson);
          debugPrint("Added new person with ID: $resultId");
        }
      } else if (resultId == -1) {
        debugPrint("UI Alert: Storage Full!");
      } else {
        debugPrint("UI Alert: Generic Save Error!");
      }
    } catch (e) {
      debugPrint("Provider Error processing file/data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadPeople() {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedPeople = personRepository.fetchAllPeople();
      _people.clear();
      _people.addAll(fetchedPeople);
    } catch (e) {
      debugPrint("Error loading people: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool deletePerson(int id) {
    try {
      final personToDelete = _people.firstWhere((p) => p.id == id);
      final deleted = personRepository.deletePersonById(id);

      if (deleted) {
        _people.removeWhere((p) => p.id == id);
        try {
          File(personToDelete.profilePicturePath).deleteSync();
        } catch (e) {
          debugPrint("Error deleting image file: $e");
        }
        notifyListeners();
      }
      return deleted;
    } catch (e) {
      debugPrint("Error deleting person: $e");
      return false;
    }
  }
}
