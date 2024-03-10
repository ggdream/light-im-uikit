import 'dart:async';
import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:light_im_sdk/light_im_sdk.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'package:light_im_uikit/src/assets/assets.dart';
import 'package:light_im_uikit/src/light_im_uikit.dart';
import 'package:light_im_uikit/src/model/model.dart';
import 'package:light_im_uikit/src/panel/panel.dart';
import 'package:light_im_uikit/src/utils/date_format.dart';
import 'package:light_im_uikit/src/utils/file_size.dart';
import 'package:light_im_uikit/src/widgets/special_text_span.dart';

import 'image_gallery.dart';
import 'video_player.dart';

class LimChatPage extends StatefulWidget {
  LimChatPage({
    super.key,
    this.actions,
    this.onTapAvatar,
    Map<String, String>? emoticons,
    required this.conversation,
    this.customElemBuilder,
    this.showPanel = true,
    LimChatController? controller,
  })  : emoticons = emoticons ?? _internalEmoticons,
        controller =
            controller ?? LimChatController(conversation: conversation);

  final List<Widget>? actions;
  final void Function(String)? onTapAvatar;
  final Map<String, String> emoticons;
  final Widget Function(BuildContext, String)? customElemBuilder;
  final bool showPanel;

  final LimChatController controller;
  final LimConversation conversation;

  // ignore: prefer_for_elements_to_map_fromiterable
  static final _internalEmoticons = Map<String, String>.fromIterable(
    Assets.emoticon.values,
    key: (item) => '[${item.path.split('_').last.split('.').first}]',
    value: (item) => 'packages/light_im_uikit/${item.path}',
  );

  @override
  State<LimChatPage> createState() => _LimChatPageState();
}

class _LimChatPageState extends State<LimChatPage> with WidgetsBindingObserver {
  double _height = 180;
  final _showTag = List<bool>.generate(2, (index) => false);

  final _editingController = TextEditingController();
  final _scrollController = ScrollController();
  final _extendedTextFieldKey = GlobalKey<ExtendedTextFieldState>();
  final _outlineInputBorder = const OutlineInputBorder(
    borderSide: BorderSide.none,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    widget.controller.mark();
    WidgetsBinding.instance.removeObserver(this);
    _editingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final bottom = MediaQuery.of(context).viewInsets.bottom;
    _height = max(bottom, _height);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value:
          LightIMUIKit.getLimMessageModel(widget.conversation.conversationId),
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
        if (widget.showPanel) panelView(),
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
        child = TextBubbleView(
          elem: message.text!,
          emoticons: widget.emoticons,
        );
        break;

      case LimMessageType.image:
        child = GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (BuildContext context) => ImageGalleryPage(
                  index: 0,
                  items: [message.image!.url],
                ),
              ),
            );
          },
          child: ImageBubbleView(elem: message.image!),
        );
        break;

      case LimMessageType.audio:
        child = Text('音频: ${message.audio!.name}');
        break;

      case LimMessageType.video:
        child = GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (BuildContext context) => VideoPlayerPage(
                  url: message.video!.url,
                ),
              ),
            );
          },
          child: VideoBubbleView(elem: message.video!),
        );
        break;

      case LimMessageType.file:
        child = Text('文件: ${message.file!.name}');
        break;

      case LimMessageType.custom:
        child =
            widget.customElemBuilder?.call(context, message.custom!.content) ??
                Text('自定义: ${message.custom!.content}');
        break;

      case LimMessageType.record:
        child = RecordBubbleView(elem: message.record!);
        break;

      default:
        return const SizedBox();
    }

    return Row(
      textDirection: message.isSelf ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => widget.onTapAvatar?.call(message.senderId),
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
        // const SizedBox(width: 108),
        const SizedBox(width: 32),
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
                icon: _showTag[0]
                    ? Icon(
                        Icons.mic_none_outlined,
                        color: Theme.of(context).primaryColor,
                      )
                    : const Icon(Icons.mic_none_outlined),
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
                icon: _showTag[1]
                    ? Icon(
                        CupertinoIcons.smiley,
                        color: Theme.of(context).primaryColor,
                      )
                    : const Icon(CupertinoIcons.smiley),
              ),
            ],
          ),
          if (_showTag.contains(true)) const SizedBox(height: 16),
          tabsView(),
        ],
      ),
    );
  }

  Widget tabsView() {
    if (_showTag[0]) {
      return VoicePanelView(
        height: _height,
        onFinish: (file, duration) async {
          final res = await widget.controller.sendRecordMessage(file, duration);
          if (res == true) {
            _postSendMessage();
          }
        },
      );
    } else if (_showTag[1]) {
      final List<({String name, String asset})> items = [];
      widget.emoticons.forEach(
        (key, value) {
          items.add((name: key, asset: value));
        },
      );

      return EmoticonPanelView(
        height: _height,
        onSelected: (text) {
          final TextEditingValue value = _editingController.value;
          final int start = value.selection.baseOffset;
          int end = value.selection.extentOffset;
          if (value.selection.isValid) {
            String newText = '';
            if (value.selection.isCollapsed) {
              if (end > 0) {
                newText += value.text.substring(0, end);
              }
              newText += text;
              if (value.text.length > end) {
                newText += value.text.substring(end, value.text.length);
              }
            } else {
              newText = value.text.replaceRange(start, end, text);
              end = start;
            }

            _editingController.value = value.copyWith(
                text: newText,
                selection: value.selection.copyWith(
                    baseOffset: end + text.length,
                    extentOffset: end + text.length));
          } else {
            _editingController.value = TextEditingValue(
                text: text,
                selection: TextSelection.fromPosition(
                    TextPosition(offset: text.length)));
          }

          SchedulerBinding.instance.addPostFrameCallback((_) {
            _extendedTextFieldKey.currentState
                ?.bringIntoView(_editingController.selection.base);
          });
        },
        items: items,
      );
    }

    return const SizedBox();
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
          onTap: _onTapTextField,
          specialTextSpanBuilder: CustomSpecialTextSpanBuilder(
            emoticons: widget.emoticons,
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

  void _onTapTextField() {
    setState(() {
      _showTag.fillRange(0, _showTag.length, false);
    });
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
    final origin = _showTag[0];
    setState(() {
      _showTag.fillRange(0, _showTag.length, false);
      _showTag[0] = !origin;
    });
  }

  Future<void> addEmoji() async {
    final now = !_showTag[1];
    setState(() {
      _showTag.fillRange(0, _showTag.length, false);
      _showTag[1] = now;
    });

    if (now) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } else {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

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

class RecordBubbleView extends StatefulWidget {
  const RecordBubbleView({
    super.key,
    required this.elem,
  });

  final LimRecordElem elem;

  @override
  State<RecordBubbleView> createState() => _RecordBubbleViewState();
}

class _RecordBubbleViewState extends State<RecordBubbleView> {
  // int _currentSecond = 0;
  bool _isPlaying = false;

  final player = Player();
  // late final StreamSubscription<Duration> _positionStream;
  late final StreamSubscription<bool> _completedStream;

  @override
  void initState() {
    super.initState();
    // _positionStream = player.stream.position.listen(_onPosition);
    _completedStream = player.stream.completed.listen(_onCompleted);
    player.setVideoTrack(VideoTrack.no());
  }

  @override
  void dispose() {
    // _positionStream.cancel();
    _completedStream.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 20),
            Text(_time),
            const SizedBox(width: 4),
            _isPlaying
                ? const Icon(Icons.volume_up_rounded)
                : const Icon(Icons.volume_mute_rounded),
            // const SizedBox(width: 4),
            // SizedBox(
            //   height: 12,
            //   width: 72,
            //   child: ClipRRect(
            //     borderRadius: BorderRadius.circular(32),
            //     child: LinearProgressIndicator(
            //       value: _currentSecond / widget.elem.duration,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      await player.open(Media(widget.elem.url), play: false);
      await player.play();
    } else {
      await player.pause();
    }
  }

  String get _time {
    final second = widget.elem.duration ~/ 1000;
    if (second > 60) {
      return '${(second ~/ 60)}′${second % 60}″';
    }

    return '$second″';
  }

  // void _onPosition(Duration value) {
  //   setState(() {
  //     _currentSecond = value.inMilliseconds;
  //   });
  // }

  void _onCompleted(bool value) {
    if (value) {
      setState(() {
        _isPlaying = false;
        // _currentSecond = 0;
      });
    }
  }
}

class TextBubbleView extends StatelessWidget {
  const TextBubbleView({
    super.key,
    required this.elem,
    this.emoticons = const {},
  });

  final LimTextElem elem;
  final Map<String, String> emoticons;

  @override
  Widget build(BuildContext context) {
    return Flexible(
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
          elem.text,
          specialTextSpanBuilder: CustomSpecialTextSpanBuilder(
            emoticons: emoticons,
          ),
        ),
      ),
    );
  }
}

class ImageBubbleView extends StatelessWidget {
  const ImageBubbleView({
    super.key,
    required this.elem,
  });

  final LimImageElem elem;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 160,
        maxHeight: 160,
      ),
      child: ExtendedImage.network(
        elem.url,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class VideoBubbleView extends StatelessWidget {
  const VideoBubbleView({
    super.key,
    required this.elem,
  });

  final LimVideoElem elem;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              elem.thumbnailUrl,
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
                  elem.name,
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  FileSizeUtil.getSize(elem.size),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LimChatController {
  LimChatController({
    required this.conversation,
  }) : model = LightIMUIKit.getLimMessageModel(conversation.conversationId);

  final LimConversation conversation;
  final LimMessageModel model;

  Future<void> pull() async {
    await model.refresh();
  }

  Future<bool> mark() async {
    final cModel = LightIMUIKit.getLimConversationModel();
    final idx = cModel.items
        .indexWhere((e) => e.conversationId == model.conversationId);
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

  Future<bool?> sendRecordMessage(XFile file, int duration) async {
    return await model.sendRecordMessage(
      file: file,
      duration: duration,
    );
  }
}
