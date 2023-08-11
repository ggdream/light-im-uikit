import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:light_im_sdk/light_im_sdk.dart';
import 'package:provider/provider.dart';

import 'package:light_im_uikit/src/light_im_uikit.dart';
import 'package:light_im_uikit/src/model/model.dart';
import 'package:light_im_uikit/src/utils/date_format.dart';

class LimChatPage extends StatefulWidget {
  LimChatPage({
    super.key,
    this.actions,
    required this.conversation,
    LimChatController? controller,
  }) : controller = controller ?? LimChatController(conversation: conversation);

  final List<Widget>? actions;

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
        Expanded(
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
        ),
        panelView(),
      ],
    );
  }

  Widget bubbleView(LimMessage message) {
    switch (LimMessageType.values[message.type]) {
      case LimMessageType.date:
        return Center(child: Text(message.custom!));
      case LimMessageType.text:
        return Row(
          textDirection: message.isSelf ? TextDirection.rtl : TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExtendedImage.network(
              message.avatar,
              width: 40,
              height: 40,
              shape: BoxShape.circle,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(message.text!),
              ),
            ),
            const SizedBox(width: 108),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget panelView() {
    return Container(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: 16,
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
                onPressed: sendMessage,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('发送'),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _editingController,
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

  Future<void> sendMessage() async {
    final text = _editingController.text;
    final res = await widget.controller.sendTextMessage(
      text,
    );
    if (!res) return;

    _editingController.clear();
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
          text: '',
          image: '',
          audio: '',
          video: '',
          custom: DateFormatUtil.human(data[i].createAt),
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
    return await model.send(type: LimMessageType.text, text: text);
  }
}
