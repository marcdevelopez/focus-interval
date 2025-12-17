class PomodoroTask {
  final String id;
  final String name;

  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  final int totalPomodoros;
  final int longBreakInterval;

  final String startSound;
  final String startBreakSound;
  final String finishTaskSound;

  PomodoroTask({
    required this.id,
    required this.name,
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.totalPomodoros,
    required this.longBreakInterval,
    required this.startSound,
    required this.startBreakSound,
    required this.finishTaskSound,
  });

  PomodoroTask copyWith({
    String? id,
    String? name,
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? totalPomodoros,
    int? longBreakInterval,
    String? startSound,
    String? startBreakSound,
    String? finishTaskSound,
  }) {
    return PomodoroTask(
      id: id ?? this.id,
      name: name ?? this.name,
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      totalPomodoros: totalPomodoros ?? this.totalPomodoros,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      startSound: startSound ?? this.startSound,
      startBreakSound: startBreakSound ?? this.startBreakSound,
      finishTaskSound: finishTaskSound ?? this.finishTaskSound,
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
    'startSound': startSound,
    'startBreakSound': startBreakSound,
    'finishTaskSound': finishTaskSound,
  };

  factory PomodoroTask.fromMap(Map<String, dynamic> map) => PomodoroTask(
    id: map['id'] as String,
    name: map['name'] as String? ?? '',
    pomodoroMinutes: map['pomodoroMinutes'] as int,
    shortBreakMinutes: map['shortBreakMinutes'] as int,
    longBreakMinutes: map['longBreakMinutes'] as int,
    totalPomodoros: map['totalPomodoros'] as int,
    longBreakInterval: map['longBreakInterval'] as int,
    startSound: (map['startSound'] as String?) ?? 'default_chime',
    startBreakSound: (map['startBreakSound'] as String?) ?? 'default_chime_break',
    finishTaskSound: (map['finishTaskSound'] as String?) ?? 'default_chime_finish',
  );
}
