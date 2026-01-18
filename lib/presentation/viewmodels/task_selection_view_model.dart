import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskSelectionViewModel extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool isSelected(String id) => state.contains(id);

  void toggle(String id) {
    final next = {...state};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
  }

  void clear() {
    state = <String>{};
  }

  void syncWithIds(Iterable<String> ids) {
    final allowed = ids.toSet();
    if (state.every(allowed.contains)) return;
    state = state.where(allowed.contains).toSet();
  }
}
