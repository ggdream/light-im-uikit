import 'package:light_im_sdk/light_im_sdk.dart';
import 'package:media_kit/media_kit.dart';

import 'model/model.dart';

class LightIMUIKit {
  LightIMUIKit._();

  static final _conversationModel = LimConversationModel();
  static final _messageModelMap = <String, LimMessageModel>{};

  static void init({
    required String endpoint,
    bool tls = false,
  }) {
    LightIMSDK.init(
      endpoint: endpoint,
      tls: tls,
      listener: LightIMSDKListener(
        onReceiveNewMessage: _onReceiveNewMessage,
        onOpenNewConversation: _onOpenNewConversation,
      ),
    );

    MediaKit.ensureInitialized();
  }

  static Future<bool> login({
    required String userId,
    required String token,
  }) async {
    return await LightIMSDK.login(
      userId: userId,
      token: token,
    );
  }

  static Future<bool> logout() async {
    final res = await LightIMSDK.logout();
    if (!LightIMSDKHttp.checkRes(res)) {
      return false;
    }

    _conversationModel.clear();
    _messageModelMap.clear();

    return true;
  }

  static void _onReceiveNewMessage(LimMessage message) {
    _conversationModel.update(message);

    final model = _messageModelMap[message.conversationId];
    if (model == null) return;

    model.add(message);
  }

  static void _onOpenNewConversation(LimConversation conversation) {
    _conversationModel.add(conversation);
  }

  static LimConversationModel getLimConversationModel() {
    // _conversationModel.refresh();
    return _conversationModel;
  }

  static LimMessageModel getLimMessageModel(String conversationId) {
    var model = _messageModelMap[conversationId];
    if (model == null) {
      model = LimMessageModel(conversationId);
      model.refresh();
      _messageModelMap[conversationId] = model;
    }

    return model;
  }
}
