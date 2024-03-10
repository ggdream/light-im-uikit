import 'package:cross_file/cross_file.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/foundation.dart';
import 'package:light_im_sdk/light_im_sdk.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LimMessageModel extends ChangeNotifier {
  // final String userId;
  final String conversationId;

  final _items = <LimMessage>[];
  bool isEnd = false;
  int sequence = 0;

  LimMessageModel(this.conversationId);

  final _thumbnailPlugin = FcNativeVideoThumbnail();

  Future<bool> refresh() async {
    if (isEnd) return false;

    final res = await LightIMSDK.pullMessage(
      sequence: sequence,
      conversationId: conversationId,
      size: 20,
    );
    if (res == null) return false;

    isEnd = res.isEnd == 1;
    sequence = res.sequence;
    _items.addAll(res.items);

    notifyListeners();

    return true;
  }

  Future<bool> sendTextMessage({
    required String text,
  }) async {
    final res = await LightIMSDK.sendTextMessage(
      conversationId: conversationId,
      text: text,
    );
    if (!LightIMSDKHttp.checkRes(res)) return false;

    return true;
  }

  Future<bool> sendImageMessage({
    required XFile file,
  }) async {
    final dir = await getTemporaryDirectory();
    final dst = join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    final isSuccess = await _thumbnailPlugin.getVideoThumbnail(
      srcFile: file.path,
      destFile: dst,
      width: 480,
      height: 480,
      format: 'jpeg',
      quality: 80,
      keepAspectRatio: true,
    );
    var thumbnailFile = XFile(dst);
    if (!isSuccess) {
      // return false;
      thumbnailFile = XFile('');
    }

    final res = await LightIMSDK.sendImageMessage(
      conversationId: conversationId,
      file: file,
      thumbnailFile: thumbnailFile,
    );
    if (!LightIMSDKHttp.checkRes(res)) return false;

    return true;
  }

  Future<bool> sendAudioMessage({
    required XFile file,
  }) async {
    final res = await LightIMSDK.sendAudioMessage(
      conversationId: conversationId,
      file: file,
    );
    if (!LightIMSDKHttp.checkRes(res)) return false;

    return true;
  }

  Future<bool> sendVideoMessage({
    required XFile file,
  }) async {
    final dir = await getTemporaryDirectory();
    final dst = join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    final isSuccess = await _thumbnailPlugin.getVideoThumbnail(
      srcFile: file.path,
      destFile: dst,
      width: 480,
      height: 480,
      format: 'jpeg',
      quality: 80,
      keepAspectRatio: true,
    );
    var thumbnailFile = XFile(dst);
    if (!isSuccess) {
      // return false;
      thumbnailFile = XFile('');
    }

    final res = await LightIMSDK.sendVideoMessage(
      conversationId: conversationId,
      file: file,
      thumbnailFile: thumbnailFile,
    );
    if (!LightIMSDKHttp.checkRes(res)) return false;

    return true;
  }

  Future<bool> sendFileMessage({
    required XFile file,
  }) async {
    final res = await LightIMSDK.sendFileMessage(
      conversationId: conversationId,
      file: file,
    );
    if (!LightIMSDKHttp.checkRes(res)) return false;

    return true;
  }

  Future<bool> sendCustomMessage({
    required String custom,
  }) async {
    final res = await LightIMSDK.sendCustomMessage(
      conversationId: conversationId,
      custom: custom,
    );
    if (!LightIMSDKHttp.checkRes(res)) return false;

    return true;
  }

  Future<bool> sendRecordMessage({
    required XFile file,
    required int duration,
  }) async {
    final res = await LightIMSDK.sendRecordMessage(
      conversationId: conversationId,
      file: file,
      duration: duration,
    );
    if (!LightIMSDKHttp.checkRes(res)) return false;

    return true;
  }

  Future<bool> mark() async {
    final res = await LightIMSDK.markMessage(
      conversationId: conversationId,
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
