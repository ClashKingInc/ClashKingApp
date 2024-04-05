String convertToTimeAgo(int timestamp) {
  DateTime now = DateTime.now();
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  Duration diff = now.difference(date);

  if (diff.inDays >= 1) {
    return '${diff.inDays} day${diff.inDays == 1 ? "" : "s"} ago';
  } else if (diff.inHours >= 1) {
    return '${diff.inHours} hour${diff.inHours == 1 ? "" : "s"} ago';
  } else if (diff.inMinutes >= 1) {
    return '${diff.inMinutes} minute${diff.inMinutes == 1 ? "" : "s"} ago';
  } else {
    return 'Just now';
  }
}

Map<String, dynamic> calculateStats(List<dynamic> list) {
  int sum = 0;
  if (list.isNotEmpty) {
    sum = list
        .whereType<Map>()
        .map((item) => item['change'])
        .reduce((value, element) => value + element);
  }
  int count = list.whereType<Map>().length +
      list.whereType<Map>().where((item) => item['change'] > 40).length;
  double average = count == 0 ? 0 : sum / count;
  int remaining = 320 - count * 40;
  int bestPossibleTrophies = remaining + sum;

  return {
    'sum': sum,
    'count': count,
    'average': average,
    'remaining': remaining,
    'bestPossibleTrophies': bestPossibleTrophies,
  };
}
