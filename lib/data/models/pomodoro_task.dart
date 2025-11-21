class PomodoroTask {
  final String id;
  final String name;

  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  final int totalPomodoros;
  final int longBreakInterval;

  PomodoroTask({
    required this.id,
    required this.name,
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.totalPomodoros,
    required this.longBreakInterval,
  });

  PomodoroTask copyWith({
    String? id,
    String? name,
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? totalPomodoros,
    int? longBreakInterval,
  }) {
    return PomodoroTask(
      id: id ?? this.id,
      name: name ?? this.name,
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      totalPomodoros: totalPomodoros ?? this.totalPomodoros,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'pomodoroMinutes': pomodoroMinutes,
    'shortBreakMinutes': shortBreakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'totalPomodoros': totalPomodoros,
    'longBreakInterval': longBreakInterval,
  };

  factory PomodoroTask.fromMap(Map<String, dynamic> map) => PomodoroTask(
    id: map['id'] as String,
    name: map['name'] as String,
    pomodoroMinutes: map['pomodoroMinutes'] as int,
    shortBreakMinutes: map['shortBreakMinutes'] as int,
    longBreakMinutes: map['longBreakMinutes'] as int,
    totalPomodoros: map['totalPomodoros'] as int,
    longBreakInterval: map['longBreakInterval'] as int,
  );
}
