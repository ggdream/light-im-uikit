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
  final void Function(XFile) onFinish;

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
        children: [
          _isPressing
              ? const Text('按住说话')
              : Text(
                  '${(_second / 60).toString().padLeft(2, '0')}:${(_second % 60).toString().padLeft(2, '0')}',
                ),
          const SizedBox(height: 16),
          GestureDetector(
            onLongPressDown: _onDown,
            onLongPressEnd: _onEnd,
            onLongPressCancel: _onCancel,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Theme.of(context).primaryColorLight,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.mic_none_outlined),
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
      _timer = Timer.periodic(const Duration(seconds: 1), _onTimer);
    });

    await _record.start(
      path: join(_tmpPath, '${DateTime.now().millisecondsSinceEpoch}.wav'),
      encoder: AudioEncoder.wav,
      bitRate: 128000,
      samplingRate: 44100,
    );
  }

  Future<void> _onEnd(LongPressEndDetails _) async {
    final filePath = await _record.stop();
    setState(() {
      _isPressing = false;
      _second = 0;
      _timer?.cancel();
      _timer = null;
    });
    if (filePath == null) return;

    widget.onFinish.call(XFile(filePath));
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
    if (++_second >= 60) {
      _onEnd(const LongPressEndDetails());
    }
  }
}
