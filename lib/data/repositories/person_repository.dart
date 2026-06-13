import 'dart:typed_data';
import 'package:remember_me_please/core/models/person_model.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';

class PersonRepository {
  PersonRepository({required this.objectBoxService});

  final ObjectBoxService objectBoxService;
  List<PersonModel> fetchAllPeople() {
    return objectBoxService.getPeople();
  }

  int addNewPerson(PersonModel person) {
    return objectBoxService.addPerson(person);
  }

  bool deletePersonById(int id) {
    return objectBoxService.deletePerson(id);
  }

  PersonModel? findMatchingPerson(Float32List targetEmbedding) {
    return objectBoxService.findMatchingPerson(targetEmbedding);
  }
}
