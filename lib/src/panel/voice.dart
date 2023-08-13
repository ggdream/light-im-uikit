import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoicePanelView extends StatefulWidget {
  const VoicePanelView({
    super.key,
    required this.height,
    required this.onFinish,
  });

  final double height;
  final void Function(XFile, int) onFinish;

  @override
  State<VoicePanelView> createState() => _VoicePanelViewState();
}

class _VoicePanelViewState extends State<VoicePanelView> {
  bool _isPressing = false;
  int _second = 0;
  String _tmpPath = '';
  Timer? _timer;
  final _record = Record();

  @override
  void dispose() {
    _record.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isPressing
              ? Text(
                  '${((_second ~/ 1000) ~/ 60).toString().padLeft(2, '0')}:${((_second ~/ 1000) % 60).toString().padLeft(2, '0')}',
                )
              : const Text('按住说话'),
          const SizedBox(height: 8),
          GestureDetector(
            onLongPressDown: _onDown,
            onLongPressEnd: _onEnd,
            onLongPressCancel: _onCancel,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: _isPressing
                    ? Theme.of(context).primaryColorDark
                    : Theme.of(context).primaryColor,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.mic_none_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDown(LongPressDownDetails _) async {
    if (_tmpPath.isEmpty) {
      _tmpPath = (await getTemporaryDirectory()).path;
    }

    setState(() {
      _isPressing = true;
      _second = 0;
      _timer = Timer.periodic(const Duration(milliseconds: 50), _onTimer);
    });

    await _record.start(
      path: join(_tmpPath, '${DateTime.now().millisecondsSinceEpoch}.wav'),
      encoder: AudioEncoder.wav,
      bitRate: 128000,
      samplingRate: 44100,
    );
  }

  Future<void> _onEnd(LongPressEndDetails details) async {
    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;
    if (!(dx >= 0 && dy <= 64 && dy >= 0 && dy <= 64)) {
      await _onCancel();
      return;
    }

    final second = _second;
    final filePath = await _record.stop();
    setState(() {
      _isPressing = false;
      _second = 0;
      _timer?.cancel();
      _timer = null;
    });
    if (filePath == null) return;
    if (second < 1000) return;

    widget.onFinish.call(XFile(filePath), second);
  }

  Future<void> _onCancel() async {
    await _record.stop();
    setState(() {
      _isPressing = false;
      _second = 0;
      _timer?.cancel();
      _timer = null;
    });
  }

  void _onTimer(Timer _) {
    setState(() {
      _second += 50;
    });

    if (_second >= 60 * 1000) {
      _onEnd(const LongPressEndDetails());
    }
  }
}
