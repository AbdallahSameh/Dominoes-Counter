class Log {
  final int count;
  final DateTime time;

  Log({required this.count, required this.time});

  Map<String, dynamic> toJson() => {
    'count': count,
    'time': time.toIso8601String(),
  };

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(count: json['count'], time: DateTime.parse(json['time']));
  }
}
