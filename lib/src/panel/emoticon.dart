import 'package:flutter/material.dart';

class EmoticonPanelView extends StatefulWidget {
  const EmoticonPanelView({
    super.key,
    required this.height,
    required this.onSelected,
    required this.items,
  });

  final double height;
  final void Function(String) onSelected;
  final List<({String name, String asset})> items;

  @override
  State<EmoticonPanelView> createState() => _EmoticonPanelViewState();
}

class _EmoticonPanelViewState extends State<EmoticonPanelView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: widget.items.isEmpty
          ? const Center(
              child: Text('暂无表情'),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                runAlignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                alignment: WrapAlignment.center,
                children: List.generate(
                  widget.items.length,
                  (index) {
                    final item = widget.items[index];

                    return GestureDetector(
                      onTap: () => widget.onSelected.call(item.name),
                      child: Image.asset(
                        item.asset,
                        width: 28,
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
