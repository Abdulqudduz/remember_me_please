import 'package:remember_me_please/core/models/conversation_model.dart';
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

  int addNewConversationOrUpdate(ConversationModel conversation) {
    return objectBoxService.addOrUpdateConversation(conversation);
  }

  bool deleteConversationById(int id) {
    return objectBoxService.deleteConversation(id);
  }
}
