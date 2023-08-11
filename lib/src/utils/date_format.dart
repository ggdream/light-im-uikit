class DateFormatUtil {
  DateFormatUtil._();

  static String ymd(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  static String ymdhmsFromDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  static String msFromDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String ymdhms(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  static bool gtThreeMinute(int a, b) {
    final t1 = DateTime.fromMillisecondsSinceEpoch(a);
    final t2 = DateTime.fromMillisecondsSinceEpoch(b);

    return t2.difference(t1).inMinutes > 3;
  }

  static String human(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final nowDateTime = DateTime.now();
    final a = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final b = DateTime(nowDateTime.year, nowDateTime.month, nowDateTime.day);
    final diffTime = b.difference(a);

    switch (diffTime.inDays) {
      case 0:
        return msFromDateTime(dateTime);
      case 1:
        return '昨天 ${msFromDateTime(dateTime)}';
      case 2:
        return '前天 ${msFromDateTime(dateTime)}';
      default:
        return '${dateTime.month.toString().padLeft(2, '0')}月${dateTime.day.toString().padLeft(2, '0')}日 ${msFromDateTime(dateTime)}';
    }
  }

  static String humanSimple(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final nowDateTime = DateTime.now();
    final a = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final b = DateTime(nowDateTime.year, nowDateTime.month, nowDateTime.day);
    final diffTime = b.difference(a);

    switch (diffTime.inDays) {
      case 0:
        return msFromDateTime(dateTime);
      case 1:
        return '昨天 ${msFromDateTime(dateTime)}';
      case 2:
        return '前天 ${msFromDateTime(dateTime)}';
      default:
        return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}
