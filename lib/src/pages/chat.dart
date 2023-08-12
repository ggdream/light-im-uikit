import 'package:extended_image/extended_image.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:light_im_sdk/light_im_sdk.dart';
import 'package:provider/provider.dart';

import 'package:light_im_uikit/src/light_im_uikit.dart';
import 'package:light_im_uikit/src/model/model.dart';
import 'package:light_im_uikit/src/utils/date_format.dart';
import 'package:light_im_uikit/src/utils/file_size.dart';
import 'package:light_im_uikit/src/widgets/special_text_span.dart';

class LimChatPage extends StatefulWidget {
  LimChatPage({
    super.key,
    this.actions,
    this.onTapAvatar,
    required this.conversation,
    LimChatController? controller,
  }) : controller = controller ?? LimChatController(conversation: conversation);

  final List<Widget>? actions;
  final void Function(String)? onTapAvatar;

  final LimChatController controller;
  final LimConversation conversation;

  @override
  State<LimChatPage> createState() => _LimChatPageState();
}

class _LimChatPageState extends State<LimChatPage> {
  final _editingController = TextEditingController();
  final _scrollController = ScrollController();
  final _outlineInputBorder = const OutlineInputBorder(
    borderSide: BorderSide.none,
  );

  @override
  void dispose() {
    widget.controller.mark();
    _editingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: LightIMUIKit.getLimMessageModel(widget.conversation.userId),
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: appBar(),
        body: bodyView(),
      ),
    );
  }

  Widget bodyView() {
    return Column(
      children: [
        messageView(),
        panelView(),
      ],
    );
  }

  Widget messageView() {
    return Expanded(
      child: Consumer<LimMessageModel>(
        builder: (context, value, child) {
          final items = _calcDate(value.items.reversed.toList());

          return RefreshIndicator(
            onRefresh: widget.controller.pull,
            child: ListView.separated(
              reverse: true,
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return bubbleView(item);
              },
              separatorBuilder: (context, index) {
                return const SizedBox(height: 16);
              },
            ),
          );
        },
      ),
    );
  }

  Widget bubbleView(LimMessage message) {
    late final Widget child;
    switch (LimMessageType.values[message.type]) {
      case LimMessageType.date:
        return Center(child: Text(message.custom!.content));
      case LimMessageType.text:
        child = Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExtendedSelectableText(
              message.text!.text,
              specialTextSpanBuilder: CustomSpecialTextSpanBuilder(
                emoticons: {},
              ),
            ),
          ),
        );
        break;

      case LimMessageType.image:
        child = ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 160,
            maxHeight: 160,
          ),
          child: ExtendedImage.network(
            message.image!.url,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
          ),
        );
        break;

      case LimMessageType.audio:
        child = Text('音频: ${message.audio!.name}');
        break;

      case LimMessageType.video:
        child = Container(
          constraints: const BoxConstraints(
            maxWidth: 160,
            maxHeight: 160,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: ExtendedImage.network(
                  message.video!.thumbnailUrl,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.video!.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      FileSizeUtil.getSize(message.video!.size),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case LimMessageType.file:
        child = Text('文件: ${message.file!.name}');
        break;

      case LimMessageType.custom:
        child = Text('自定义: ${message.custom!.content}');
        break;

      case LimMessageType.record:
        child = Text('语音: ${message.record!.duration}');
        break;

      default:
        return const SizedBox();
    }

    return Row(
      textDirection: message.isSelf ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => widget.onTapAvatar?.call(widget.conversation.userId),
          child: ExtendedImage.network(
            message.avatar,
            width: 40,
            height: 40,
            shape: BoxShape.circle,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        child,
        const SizedBox(width: 108),
      ],
    );
  }

  Widget panelView() {
    return Container(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: 6,
      ),
      color: Colors.grey.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              inputView(),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: sendTextMessage,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('发送'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ButtonBar(
            buttonPadding: EdgeInsets.zero,
            alignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: sendRecordMessage,
                icon: const Icon(Icons.mic_none_outlined),
              ),
              IconButton(
                onPressed: sendImageMessage,
                icon: const Icon(Icons.image_outlined),
              ),
              // IconButton(
              //   onPressed: sendAudioMessage,
              //   icon: const Icon(Icons.music_note_outlined),
              // ),
              IconButton(
                onPressed: sendVideoMessage,
                icon: const Icon(CupertinoIcons.videocam_circle),
              ),
              IconButton(
                onPressed: sendFileMessage,
                icon: const Icon(CupertinoIcons.folder_circle),
              ),
              IconButton(
                onPressed: addEmoji,
                icon: const Icon(CupertinoIcons.smiley),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget inputView() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ExtendedTextField(
          controller: _editingController,
          specialTextSpanBuilder: CustomSpecialTextSpanBuilder(
            emoticons: {},
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            isCollapsed: true,
            hoverColor: Colors.white,
            border: _outlineInputBorder,
            enabledBorder: _outlineInputBorder,
            focusedBorder: _outlineInputBorder,
          ),
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      leading: const BackButton(),
      title: Text(widget.conversation.nickname),
      actions: widget.actions,
      centerTitle: true,
    );
  }

  Future<void> sendTextMessage() async {
    final text = _editingController.text;
    final res = await widget.controller.sendTextMessage(
      text,
    );
    if (!res) return;

    _editingController.clear();
    _postSendMessage();
  }

  Future<void> sendImageMessage() async {
    final res = await widget.controller.sendImageMessage();
    if (res == null) return;
    if (!res) return;

    _postSendMessage();
  }

  Future<void> sendAudioMessage() async {
    final res = await widget.controller.sendAudioMessage();
    if (res == null) return;
    if (!res) return;

    _postSendMessage();
  }

  Future<void> sendVideoMessage() async {
    final res = await widget.controller.sendVideoMessage();
    if (res == null) return;
    if (!res) return;

    _postSendMessage();
  }

  Future<void> sendFileMessage() async {
    final res = await widget.controller.sendFileMessage();
    if (res == null) return;
    if (!res) return;

    _postSendMessage();
  }

  Future<void> sendRecordMessage() async {
    final res = await widget.controller.sendRecordMessage();
    if (res == null) return;
    if (!res) return;

    _postSendMessage();
  }

  Future<void> addEmoji() async {}

  void _postSendMessage() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.linear,
    );
  }

  List<LimMessage> _calcDate(List<LimMessage> data) {
    if (data.isEmpty) return data;

    int count = 0;
    final ret = List<LimMessage>.from(data);
    for (var i = 0; i < data.length; i++) {
      if (i == 0 ||
          DateFormatUtil.gtThreeMinute(
            data[i - 1].createAt,
            data[i].createAt,
          )) {
        final limMessage = LimMessage(
          senderId: '',
          receiverId: '',
          userId: '',
          avatar: '',
          conversationId: '',
          isSelf: false,
          nickname: '',
          seq: 0,
          timestamp: 0,
          type: LimMessageType.date.index,
          isRead: false,
          isPeerRead: false,
          createAt: 0,
          text: null,
          image: null,
          audio: null,
          file: null,
          video: null,
          custom:
              LimCustomElem(content: DateFormatUtil.human(data[i].createAt)),
          record: null,
        );
        ret.insert(i + count, limMessage);
        count++;
      }
    }

    return ret.reversed.toList();
  }
}

class LimChatController {
  LimChatController({
    required this.conversation,
  }) : model = LightIMUIKit.getLimMessageModel(conversation.userId);

  final LimConversation conversation;
  final LimMessageModel model;

  Future<void> pull() async {
    await model.refresh();
  }

  Future<bool> mark() async {
    final cModel = LightIMUIKit.getLimConversationModel();
    final idx = cModel.items.indexWhere((e) => e.userId == model.userId);
    if (idx == -1 || cModel.items[idx].unread == 0) return true;

    final res = await model.mark();
    if (!res) return false;

    cModel.clearUnread(conversation.conversationId);

    return true;
  }

  Future<bool> sendTextMessage(String text) async {
    return await model.sendTextMessage(text: text);
  }

  Future<bool?> sendImageMessage() async {
    const typeGroup = XTypeGroup(
      label: '图片',
      extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;

    return await model.sendImageMessage(file: file);
  }

  Future<bool?> sendAudioMessage() async {
    const typeGroup = XTypeGroup(
      label: '音频',
      extensions: <String>['aac', 'mp3', 'm4a', 'wav', 'flac', 'ogg', 'opus'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;

    return await model.sendAudioMessage(file: file);
  }

  Future<bool?> sendVideoMessage() async {
    const typeGroup = XTypeGroup(
      label: '视频',
      extensions: <String>[
        'mp4',
        'm4s',
        'ts',
        '3pg',
        'mov',
        'm4v',
        'avi',
        'mkv',
        'flv',
        'wmv'
      ],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;

    return await model.sendVideoMessage(file: file);
  }

  Future<bool?> sendFileMessage() async {
    const typeGroup = XTypeGroup(
      label: '所有文件',
      extensions: <String>['*'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;

    return await model.sendFileMessage(file: file);
  }

  Future<bool> sendCustomMessage(String custom) async {
    return await model.sendCustomMessage(custom: custom);
  }

  Future<bool?> sendRecordMessage() async {
    const typeGroup = XTypeGroup(
      label: '所有文件',
      extensions: <String>['*'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;

    return await model.sendRecordMessage(file: file);
  }
}
