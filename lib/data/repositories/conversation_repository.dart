import 'package:remember_me_please/data/models/conversation_model.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';

class ConversationRepository {
  ConversationRepository({required this.objectBoxService});

  final ObjectBoxService objectBoxService;

  List<ConversationModel> fetchAllConversations() {
    return objectBoxService.getConversations();
  }

  ConversationModel? fetchConversationById(int id) {
    return objectBoxService.getConversationById(id);
  }

  int addNewConversation(ConversationModel conversation) {
    return objectBoxService.addConversation(conversation);
  }

  bool deleteConversationById(int id) {
    return objectBoxService.deleteConversation(id);
  }
}
