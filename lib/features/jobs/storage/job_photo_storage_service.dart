import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class JobPhotoStorageService {
  Future<Directory> _getBaseMeccaDir() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final meccaDir = Directory(join(baseDir.path, 'mecca'));

    if (!await meccaDir.exists()) {
      await meccaDir.create(recursive: true);
    }

    return meccaDir;
  }

  Future<Directory> createJobFolder(int jobId) async {
    final meccaDir = await _getBaseMeccaDir();

    final jobDir = Directory(
      join(meccaDir.path, 'jobs', jobId.toString(), 'photos'),
    );

    if (!await jobDir.exists()) {
      await jobDir.create(recursive: true);
    }
    return jobDir;
  }

  Future<File> copyImageToJobFolder({
    required String sourcePath,
    required int jobId,
  }) async {
    final jobDir = await createJobFolder(jobId);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final newPath = join(jobDir.path, fileName);

    final sourceFile = File(sourcePath);

    return sourceFile.copy(newPath);
  }

  Future<void> deletePhotoFile(String path) async {
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteJobFolder(int jobId) async {
    final meccaDir = await _getBaseMeccaDir();

    final jobDir = Directory(join(meccaDir.path, 'jobs', jobId.toString()));

    if (await jobDir.exists()) {
      await jobDir.delete(recursive: true);
    }
  }
}
