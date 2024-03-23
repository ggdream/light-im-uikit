import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';

class ApplyPermDialog extends StatelessWidget {
  const ApplyPermDialog({
    super.key,
    required this.reason,
    required this.showCancel,
    required this.permNames,
  });

  final String reason;
  final bool showCancel;
  final List<String> permNames;

  static Future<bool> show({
    required BuildContext context,
    required String reason,
    required List<Permission> perms,
    bool showCancel = true,
    bool barrierDismissible = true,
  }) async {
    if (!kIsWeb && UniversalPlatform.isDesktop) {
      return true;
    }

    final isNotGrant = <Permission>[];
    for (var e in perms) {
      if (!await e.isGranted) {
        isNotGrant.add(e);
      }
    }
    if (isNotGrant.isEmpty) return true;

    if (context.mounted) {
      final res = (await showDialog(
            context: context,
            builder: (context) {
              return ApplyPermDialog(
                reason: reason,
                showCancel: showCancel,
                permNames: perms.map((e) => _names[e.value]).toList(),
              );
            },
            barrierDismissible: barrierDismissible,
          )) ??
          false;
      if (!res) return false;

      final resMap = await isNotGrant.request();
      for (var e in resMap.values) {
        if (!e.isGranted) {
          return false;
        }
      }

      return true;
    }

    return false;
  }

  static Future<Permission> get photo async {
    if (kIsWeb) return Permission.photos;

    if (UniversalPlatform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        return Permission.storage;
      } else {
        return Permission.photos;
      }
    } else {
      return Permission.photos;
    }
  }

  static Future<Permission> get video async {
    if (kIsWeb) return Permission.photos;

    if (UniversalPlatform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        return Permission.storage;
      } else {
        return Permission.videos;
      }
    } else {
      return Permission.photos;
    }
  }
  static Future<Permission> get audio async {
    if (kIsWeb) return Permission.photos;

    if (UniversalPlatform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        return Permission.storage;
      } else {
        return Permission.audio;
      }
    } else {
      return Permission.photos;
    }
  }

  static Future<Permission> get storage async {
    if (kIsWeb) return Permission.photos;

    if (UniversalPlatform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        return Permission.storage;
      } else {
        return Permission.manageExternalStorage;
      }
    } else {
      return Permission.storage;
    }
  }

  static const List<String> _names = <String>[
    '日历',
    '相机',
    '联系人',
    '位置',
    '位置始终',
    '使用时的位置',
    '媒体库',
    '麦克风',
    '电话',
    '相片',
    '照片仅添加',
    '提醒',
    '传感器',
    '短信',
    '演讲',
    '存储',
    '忽略电池优化',
    '通知',
    '访问媒体位置',
    '活动识别',
    '未知',
    '蓝牙',
    '管理外部存储',
    '系统警报窗口',
    '请求安装包',
    '应用程序跟踪透明度',
    '关键警报',
    '访问通知策略',
    '蓝牙扫描',
    '蓝牙广告',
    '蓝牙连接',
    '附近的Wifi设备',
    '视频',
    '声音的',
    '安排精确警报',
    '传感器始终',
    '日历只写',
    '日历完全访问',
    '助手',
    '背景刷新'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('权限申请说明'),
      content: Text('$reason\n所需权限: ${permNames.join('、')}'),
      actions: [
        TextButton(
          onPressed: () => submit(context),
          child: const Text('确定'),
        ),
        if (showCancel)
          TextButton(
            onPressed: () => cancel(context),
            child: const Text('取消'),
          ),
      ],
    );
  }

  void cancel(BuildContext context) {
    Navigator.of(context).pop(false);
  }

  void submit(BuildContext context) {
    Navigator.of(context).pop(true);
  }
}
