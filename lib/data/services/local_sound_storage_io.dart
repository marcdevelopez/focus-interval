import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'local_sound_storage.dart';

class _LocalSoundStorageIo implements LocalSoundStorage {
  @override
  bool get isSupported => true;

  @override
  Future<int?> fileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return file.length();
  }

  @override
  Future<LocalSoundImportResult> importSound({
    required String sourcePath,
    required String targetFileName,
    required bool copyOnImport,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      return const LocalSoundImportResult(
        error: 'The selected file no longer exists.',
      );
    }

    if (!copyOnImport) {
      return LocalSoundImportResult(path: sourcePath);
    }

    final baseDir = await getApplicationDocumentsDirectory();
    final soundsDir = Directory('${baseDir.path}/sounds');
    await soundsDir.create(recursive: true);

    final target = File('${soundsDir.path}/$targetFileName');
    final copied = await source.copy(target.path);
    return LocalSoundImportResult(path: copied.path);
  }
}

LocalSoundStorage createLocalSoundStorageImpl() => _LocalSoundStorageIo();
