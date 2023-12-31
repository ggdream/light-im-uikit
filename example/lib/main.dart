import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:light_im_uikit/light_im_uikit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LightIMUIKit.init(endpoint: '127.0.0.1:8080/api/c');
  await LightIMUIKit.login(
    userId: '1',
    token:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIxIiwiaXNzIjoibGlnaHQtaW0iLCJleHAiOjE2OTIzNjQxNTgsIm5iZiI6MTY5MTc1OTM1OCwiaWF0IjoxNjkxNzU5MzU4fQ.wkV6JmS3zADVQXTMIi_JqcBZX_5a7gWDrGUhG01igXA',
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Light IM UIKit',
      home: const HomePage(),
      scrollBehavior: _CustomScrollBehavior(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LimConversationPage(
      title: const Text('会话列表'),
      onTapItem: (conv) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (BuildContext context) => LimChatPage(conversation: conv),
          ),
        );
      },
    );
  }
}

class _CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
