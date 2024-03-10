import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({
    super.key,
    required this.index,
    required this.items,
  });

  final int index;
  final List<String> items;

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late final controller = ExtendedPageController(initialPage: widget.index);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      extendBodyBehindAppBar: true,
      appBar: appBar(),
      body: bodyView(),
    );
  }

  Widget bodyView() {
    return ExtendedImageGesturePageView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];

        return ExtendedImage.network(
          item,
          fit: BoxFit.contain,
          mode: ExtendedImageMode.gesture,
          initGestureConfigHandler: (state) {
            return GestureConfig(
              initialScale: .8,
              inPageView: true,
            );
          },
        );
      },
    );
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        color: Colors.white,
      ),
    );
  }
}
