import 'package:flutter/foundation.dart';
import 'package:light_im_sdk/light_im_sdk.dart';

class LimConversationModel extends ChangeNotifier {
  final _items = <LimConversation>[];

  Future<bool> refresh() async {
    final res = await LightIMSDK.pullConversation();
    if (res == null) return false;

    _items.sort((a, b) => b.createAt - a.createAt);
    _items
      ..clear()
      ..addAll(res);
    notifyListeners();

    return true;
  }

  void add(LimConversation data) {
    if (items.indexWhere((e) => e.conversationId == data.conversationId) ==
        -1) {
      data.unread = 0;
      _items.insert(0, data);
      notifyListeners();
    }
  }

  Future<bool> delete(LimConversation data) async {
    _items.removeWhere((e) => e.conversationId == data.conversationId);
    notifyListeners();

    final res = await LightIMSDK.deleteConversation(
      conversationId: data.conversationId,
    );
    if (!LightIMSDKHttp.checkRes(res)) {
      return false;
    }

    return true;
  }

  void clearUnread(String conversationId) {
    final index = _items.indexWhere(
      (e) => e.conversationId == conversationId,
    );
    if (index == -1) return;

    _items[index].unread = 0;
    notifyListeners();
  }

  void update(LimMessage message) {
    final index = _items.indexWhere(
      (e) => e.conversationId == message.conversationId,
    );
    if (index == -1) return;

    _items[index].lastMessage = message;
    if (!message.isSelf) {
      _items[index].unread++;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<LimConversation> get items => _items;
}
