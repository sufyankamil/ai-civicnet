import 'package:get/get.dart';
import '../../../../services/supabase_service.dart';
import '../data/datasources/chat_remote_data_source.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/usecases/chat_usecases.dart';
import '../domain/usecases/delete_message_usecase.dart';
import '../presentation/viewmodels/chat_viewmodel.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Data Source
    Get.lazyPut(() => ChatRemoteDataSource(SupabaseService()));

    // Repository
    Get.lazyPut(() => ChatRepositoryImpl(Get.find<ChatRemoteDataSource>()));

    // UseCases
    Get.lazyPut(() => GetConversationsUseCase(Get.find<ChatRepositoryImpl>()));
    Get.lazyPut(() => SendMessageUseCase(Get.find<ChatRepositoryImpl>()));
    Get.lazyPut(() => MarkConversationAsReadUseCase(Get.find<ChatRepositoryImpl>()));
    Get.lazyPut(() => MarkAllConversationsAsReadUseCase(Get.find<ChatRepositoryImpl>()));
    Get.lazyPut(() => DeleteMessageUseCase(Get.find<ChatRepositoryImpl>()));

    // ViewModel
    Get.lazyPut(() => ChatViewModel(
      getConversationsUseCase: Get.find<GetConversationsUseCase>(),
      sendMessageUseCase: Get.find<SendMessageUseCase>(),
      markConversationAsReadUseCase: Get.find<MarkConversationAsReadUseCase>(),
      markAllConversationsAsReadUseCase: Get.find<MarkAllConversationsAsReadUseCase>(),
      deleteMessageUseCase: Get.find<DeleteMessageUseCase>(),
    ));
  }
}

Future<void> initChatDI() async {
  Get.lazyPut(() => ChatRemoteDataSource(SupabaseService()), fenix: true);
  Get.lazyPut(() => ChatRepositoryImpl(Get.find<ChatRemoteDataSource>()), fenix: true);
  Get.lazyPut(() => GetConversationsUseCase(Get.find<ChatRepositoryImpl>()), fenix: true);
  Get.lazyPut(() => SendMessageUseCase(Get.find<ChatRepositoryImpl>()), fenix: true);
  Get.lazyPut(() => MarkConversationAsReadUseCase(Get.find<ChatRepositoryImpl>()), fenix: true);
  Get.lazyPut(() => MarkAllConversationsAsReadUseCase(Get.find<ChatRepositoryImpl>()), fenix: true);
  Get.lazyPut(() => DeleteMessageUseCase(Get.find<ChatRepositoryImpl>()), fenix: true);
  Get.lazyPut(() => ChatViewModel(
    getConversationsUseCase: Get.find<GetConversationsUseCase>(),
    sendMessageUseCase: Get.find<SendMessageUseCase>(),
    markConversationAsReadUseCase: Get.find<MarkConversationAsReadUseCase>(),
    markAllConversationsAsReadUseCase: Get.find<MarkAllConversationsAsReadUseCase>(),
    deleteMessageUseCase: Get.find<DeleteMessageUseCase>(),
  ), fenix: true);
}
