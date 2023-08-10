import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:light_im_sdk/light_im_sdk.dart';
import 'package:provider/provider.dart';

import 'package:light_im_uikit/src/light_im_uikit.dart';
import 'package:light_im_uikit/src/model/model.dart';
import 'package:light_im_uikit/src/utils/date_fotmat.dart';

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

        return ListView.separated(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return convView(item);
          },
          separatorBuilder: (context, index) {
            return const SizedBox(height: 4);
          },
        );
      },
    );
  }

  Widget convView(LimConversation item) {
    return InkWell(
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
                    item.lastMessage.text!,
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
                      color:
                          item.unread == 0 ? Colors.transparent : Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
}

class LimConversationController {
  final model = LightIMUIKit.getLimConversationModel();

  Future<bool> refresh() async {
    return await model.refresh();
  }
}