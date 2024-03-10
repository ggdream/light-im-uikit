import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:light_im_uikit/light_im_uikit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LightIMUIKit.init(endpoint: '127.0.0.1:8080/im');
  await LightIMUIKit.login(
    userId: '6',
    token:
        'eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNiIsInJvbGUiOjAsInN0YXR1cyI6MCwiaXNzIjoic3FueSIsImV4cCI6MTcwODMyNTQyOCwibmJmIjoxNzA3NzIwNjI4LCJpYXQiOjE3MDc3MjA2Mjh9.z1xT9Zv_AkITLPr3VCjb2RR5uEewer06HOvcroSlyc-xoXumuC4ehdLdTOlX2KReMxd7kKhi3sNqIFh7gAsJAA',
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
