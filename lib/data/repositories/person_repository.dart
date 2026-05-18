import 'dart:typed_data';
import 'package:remember_me_please/data/models/person_model.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';

class PersonRepository {
  PersonRepository({required this.objectBoxservice});

  final ObjectBoxService objectBoxservice;
  List<PersonModel> fetchAllPeople() {
    return objectBoxservice.getPeople();
  }

  int addNewPerson(PersonModel person) {
    return objectBoxservice.addPerson(person);
  }

  bool deletePersonById(int id) {
    return objectBoxservice.deletePerson(id);
  }

  PersonModel? findMatchingPerson(Float32List targetEmbedding) {
    return objectBoxservice.findMatchingPerson(targetEmbedding);
  }
}
