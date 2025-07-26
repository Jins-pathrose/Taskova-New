class MonthlyJobCount {
  final String month;
  final int count;

  MonthlyJobCount({required this.month, required this.count});

  factory MonthlyJobCount.fromJson(Map<String, dynamic> json) {
    return MonthlyJobCount(
      month: json['month'],
      count: json['count'],
    );
  }
}