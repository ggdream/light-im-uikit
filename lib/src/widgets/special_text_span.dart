import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

class CustomSpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  CustomSpecialTextSpanBuilder({
    required this.emoticons,
  });

  final Map<String, String> emoticons;

  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    required int index,
  }) {
    if (flag.isEmpty) return null;

    if (isStart(flag, EmoticonText.flag)) {
      return EmoticonText(
        start: index - (EmoticonText.flag.length - 1),
        textStyle: textStyle,
        emoticons: emoticons,
      );
    } else if (isStart(flag, AtText.flag)) {
      return AtText(
        start: index - (AtText.flag.length - 1),
        textStyle: textStyle,
        onTap: onTap,
      );
    }

    return null;
  }
}

class EmoticonText extends SpecialText {
  EmoticonText({
    required this.start,
    required TextStyle? textStyle,
    required this.emoticons,
  }) : super(flag, ']', textStyle);

  final int start;
  final Map<String, String> emoticons;

  static const flag = ']';

  @override
  InlineSpan finishText() {
    final text = toString();
    final asset = emoticons[text];
    if (asset == null) {
      return TextSpan(text: text, style: textStyle);
    }

    return ImageSpan(
      AssetImage(asset),
      imageWidth: 14,
      imageHeight: 14,
      start: start,
    );
  }
}

class AtText extends SpecialText {
  AtText({
    required this.start,
    required SpecialTextGestureTapCallback? onTap,
    required TextStyle? textStyle,
  }) : super(flag, ' ', textStyle, onTap: onTap);

  final int start;

  static const flag = '@';

  @override
  InlineSpan finishText() {
    final text = toString();

    return SpecialTextSpan(
      text: text,
      actualText: text,
      start: start,
      style: textStyle,
      recognizer: TapGestureRecognizer()..onTap = () => onTap?.call(text),
    );
  }
}
