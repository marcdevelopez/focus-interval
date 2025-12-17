class PomodoroTask {
  final String id;
  final String name;

  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  final int totalPomodoros;
  final int longBreakInterval;

  final String startSound;
  final String endPomodoroSound;
  final String startBreakSound;
  final String endBreakSound;
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
    required this.endPomodoroSound,
    required this.startBreakSound,
    required this.endBreakSound,
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
    String? endPomodoroSound,
    String? startBreakSound,
    String? endBreakSound,
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
      endPomodoroSound: endPomodoroSound ?? this.endPomodoroSound,
      startBreakSound: startBreakSound ?? this.startBreakSound,
      endBreakSound: endBreakSound ?? this.endBreakSound,
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
    'endPomodoroSound': endPomodoroSound,
    'startBreakSound': startBreakSound,
    'endBreakSound': endBreakSound,
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
    endPomodoroSound:
        (map['endPomodoroSound'] as String?) ?? 'default_chime',
    startBreakSound:
        (map['startBreakSound'] as String?) ?? 'default_chime',
    endBreakSound: (map['endBreakSound'] as String?) ?? 'default_chime',
    finishTaskSound:
        (map['finishTaskSound'] as String?) ?? 'default_chime',
  );
}
