import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:light_im_uikit/light_im_uikit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LightIMUIKit.init(endpoint: '127.0.0.1:8080/api/c');
  await LightIMUIKit.login(
    userId: '1',
    token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIxIiwiaXNzIjoibGlnaHQtaW0iLCJleHAiOjE2OTIyNjc0MTIsIm5iZiI6MTY5MTY2MjYxMiwiaWF0IjoxNjkxNjYyNjEyfQ.Z3lBQs_OH9zkDfdeLewie5ySdJ1PVTCnAwD6VF3JCPQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Light IM UIKit',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
