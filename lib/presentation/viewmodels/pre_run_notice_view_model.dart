import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

final preRunNoticeMinutesProvider =
    AsyncNotifierProvider.autoDispose<PreRunNoticeViewModel, int>(
      PreRunNoticeViewModel.new,
    );

class PreRunNoticeViewModel extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    return ref.read(taskRunNoticeServiceProvider).getNoticeMinutes();
  }

  Future<int> setNoticeMinutes(int value) async {
    final updated =
        await ref.read(taskRunNoticeServiceProvider).setNoticeMinutes(value);
    state = AsyncData(updated);
    return updated;
  }
}
