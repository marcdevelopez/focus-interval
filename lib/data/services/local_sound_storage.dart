import 'local_sound_storage_stub.dart'
    if (dart.library.io) 'local_sound_storage_io.dart';

class LocalSoundImportResult {
  final String? path;
  final String? error;

  const LocalSoundImportResult({this.path, this.error});

  bool get isSuccess => path != null && error == null;
}

abstract class LocalSoundStorage {
  bool get isSupported;
  Future<int?> fileSize(String path);
  Future<LocalSoundImportResult> importSound({
    required String sourcePath,
    required String targetFileName,
    required bool copyOnImport,
  });
}

LocalSoundStorage createLocalSoundStorage() => createLocalSoundStorageImpl();
