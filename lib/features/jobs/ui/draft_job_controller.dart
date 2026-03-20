import 'package:flutter/material.dart';
import 'package:mecca/features/jobs/data/job_photos_repository.dart';
import 'package:mecca/features/jobs/domain/draft_photo.dart';
import 'package:mecca/features/jobs/domain/job_photo.dart';
import 'package:mecca/features/jobs/storage/job_photo_storage_service.dart';
import 'package:share_plus/share_plus.dart';

class DraftJobController extends ChangeNotifier {
  DraftJobController({
    required JobPhotosRepository photosRepository,
    required JobPhotoStorageService storageService,
  }) : _photosRepository = photosRepository,
       _storageService = storageService;

  final JobPhotosRepository _photosRepository;
  final JobPhotoStorageService _storageService;

  final List<DraftPhoto> _photos = [];

  List<DraftPhoto> get photos =>
      _photos.where((p) => !p.markedForDeletion).toList();

  /// ---------------------------
  /// Cargar fotos existentes
  /// ---------------------------
  Future<void> loadFromDb(int jobId) async {
    final photosFromDb = await _photosRepository.getPhotosByJob(jobId);

    _photos
      ..clear()
      ..addAll(
        photosFromDb.map(
          (e) => DraftPhoto(id: e.id, path: e.path, isNew: false),
        ),
      );

    notifyListeners();
  }

  /// ---------------------------
  /// Agregar fotos (solo memoria)
  /// ---------------------------
  Future<String?> addPhotos(List<XFile> images) async {
    final activeCount = _photos.where((p) => !p.markedForDeletion).length;

    if (activeCount + images.length > 12) {
      return 'Máximo 12 fotos por trabajo.';
    }

    for (final image in images) {
      _photos.add(DraftPhoto(id: null, path: image.path, isNew: true));
    }

    notifyListeners();
    return null;
  }

  /// ---------------------------
  /// Marcar para borrar
  /// ---------------------------
  void markForDeletion(DraftPhoto photo) {
    if (photo.isNew) {
      _photos.remove(photo);
    } else {
      photo.markedForDeletion = true;
    }

    notifyListeners();
  }

  /// ---------------------------
  /// Sincronizar al guardar
  /// ---------------------------
  Future<String?> sync(int jobId) async {
    try {
      // 1️⃣ Eliminar fotos marcadas
      final toDelete = _photos
          .where((p) => p.markedForDeletion && !p.isNew)
          .toList();

      for (final photo in toDelete) {
        await _storageService.deletePhotoFile(photo.path);
        await _photosRepository.deletePhotoById(photo.id!);
      }

      // 2️⃣ Guardar fotos nuevas
      final newPhotos = _photos
          .where((p) => p.isNew && !p.markedForDeletion)
          .toList();

      for (final photo in newPhotos) {
        final copied = await _storageService.copyImageToJobFolder(
          sourcePath: photo.path,
          jobId: jobId,
        );

        await _photosRepository.insertPhoto(
          JobPhoto(
            jobId: jobId,
            path: copied.path,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      _photos.clear();
      notifyListeners();

      return null;
    } catch (e) {
      return 'Error sincronizando fotos.';
    }
  }

  void clear() {
    _photos.clear();
    notifyListeners();
  }
}
