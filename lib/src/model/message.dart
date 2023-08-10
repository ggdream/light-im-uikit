import 'package:flutter/foundation.dart';
import 'package:light_im_sdk/light_im_sdk.dart';

class LimMessageModel extends ChangeNotifier {
  final String userId;

  final _items = <LimMessage>[];
  bool isEnd = false;
  int sequence = 0;

  LimMessageModel(this.userId);

  Future<bool> refresh() async {
    if (isEnd) return false;

    final res = await LightIMSDK.pullMessage(
      userId: userId,
      sequence: sequence,
    );
    if (res == null) return false;

    isEnd = res.isEnd == 1;
    sequence = res.sequence;
    _items.addAll(res.items);

    notifyListeners();

    return true;
  }

  Future<bool> send({
    required LimMessageType type,
    String? text,
  }) async {
    final res = await LightIMSDK.createMessage(
      userId: userId,
      type: type,
      text: text,
    );
    if (!LightIMSDKHttp.checkRes(res)) return false;

    return true;
  }

  Future<bool> mark() async {
    final res = await LightIMSDK.markMessage(
      userId: userId,
      sequence: sequence,
    );
    if (!LightIMSDKHttp.checkRes(res)) return false;

    return true;
  }

  void add(LimMessage data) {
    _items.insert(0, data);
    notifyListeners();
  }

  List<LimMessage> get items => _items;
}
