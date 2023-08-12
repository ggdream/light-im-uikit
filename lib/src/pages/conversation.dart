import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:light_im_sdk/light_im_sdk.dart';
import 'package:provider/provider.dart';

import 'package:light_im_uikit/src/light_im_uikit.dart';
import 'package:light_im_uikit/src/model/model.dart';
import 'package:light_im_uikit/src/utils/date_format.dart';

class LimConversationPage extends StatefulWidget {
  LimConversationPage({
    super.key,
    this.leading,
    this.title,
    this.actions,
    required this.onTapItem,
    LimConversationController? controller,
  }) : controller = controller ?? LimConversationController();

  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;

  final LimConversationController controller;
  final void Function(LimConversation)? onTapItem;

  @override
  State<LimConversationPage> createState() => _LimConversationPageState();
}

class _LimConversationPageState extends State<LimConversationPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: LightIMUIKit.getLimConversationModel(),
      child: Scaffold(
        appBar: appBar(),
        body: bodyView(),
      ),
    );
  }

  Widget bodyView() {
    return Consumer<LimConversationModel>(
      builder: (context, value, _) {
        final items = value.items;

        return RefreshIndicator(
          onRefresh: widget.controller.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return convView(item);
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: 4);
            },
          ),
        );
      },
    );
  }

  Widget convView(LimConversation item) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _deleteConversation(item),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: '删除',
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onTapItem?.call(item),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Row(
            children: [
              ExtendedImage.network(
                item.avatar,
                width: 48,
                height: 48,
                shape: BoxShape.circle,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.lastMessage.nickname,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.lastMessage.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormatUtil.humanSimple(item.lastMessage.createAt),
                  ),
                  const SizedBox(height: 8),
                  CircleAvatar(
                    backgroundColor:
                        item.unread == 0 ? Colors.transparent : Colors.red,
                    radius: 10,
                    child: Text(
                      item.unread > 99 ? '..' : item.unread.toString(),
                      style: TextStyle(
                        color: item.unread == 0
                            ? Colors.transparent
                            : Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: widget.leading,
      title: widget.title,
      actions: widget.actions,
      centerTitle: true,
    );
  }

  Future<void> _deleteConversation(LimConversation conversation) async {
    await widget.controller.delete(conversation);
  }
}

class LimConversationController {
  final model = LightIMUIKit.getLimConversationModel();

  Future<void> refresh() async {
    await model.refresh();
  }

  Future<void> delete(LimConversation conversation) async {
    await model.delete(conversation);
  }
}
