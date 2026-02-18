import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focus_interval/data/services/task_run_notice_service.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/presentation/viewmodels/pre_run_notice_view_model.dart';

class FakeTaskRunNoticeService extends TaskRunNoticeService {
  FakeTaskRunNoticeService(this._value) : super();

  int _value;

  @override
  Future<int> getNoticeMinutes() async => _value;

  @override
  Future<int> setNoticeMinutes(int value) async {
    _value = value;
    return _value;
  }
}

void main() {
  test('pre-run notice viewmodel loads and updates', () async {
    final service = FakeTaskRunNoticeService(5);
    final container = ProviderContainer(
      overrides: [
        taskRunNoticeServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(preRunNoticeMinutesProvider.future);
    expect(initial, 5);

    final updated = await container
        .read(preRunNoticeMinutesProvider.notifier)
        .setNoticeMinutes(10);
    expect(updated, 10);
    expect(container.read(preRunNoticeMinutesProvider).value, 10);
  });
}
