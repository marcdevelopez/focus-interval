import 'local_sound_storage.dart';

class _LocalSoundStorageStub implements LocalSoundStorage {
  @override
  bool get isSupported => false;

  @override
  Future<int?> fileSize(String path) async => null;

  @override
  Future<LocalSoundImportResult> importSound({
    required String sourcePath,
    required String targetFileName,
    required bool copyOnImport,
  }) async {
    return const LocalSoundImportResult(
      error: 'Custom sounds are not supported on this platform.',
    );
  }
}

LocalSoundStorage createLocalSoundStorageImpl() => _LocalSoundStorageStub();
