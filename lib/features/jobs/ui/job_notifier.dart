import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:mecca/features/companies/data/company_repository.dart';
import 'package:mecca/features/jobs/data/job_photos_repository.dart';
import 'package:mecca/features/jobs/data/job_repository.dart';
import 'package:mecca/features/jobs/domain/draft_photo.dart';
import 'package:mecca/features/jobs/domain/job.dart';
import 'package:mecca/features/jobs/domain/job_calculator.dart';
import 'package:mecca/features/jobs/storage/job_photo_storage_service.dart';
import 'package:mecca/features/pdf/service/pdf_service.dart';

class JobNotifier extends ChangeNotifier {
  JobNotifier({
    required this.companyId,
    JobRepository? repository,
    CompanyRepository? companyRepository,
    JobPhotosRepository? jobPhotosRepository,
    JobPhotoStorageService? jobPhotoStorageService,
  }) : _repository = repository ?? JobRepository(),
       _companyRepository = companyRepository ?? CompanyRepository(),
       _photosRepository = jobPhotosRepository ?? JobPhotosRepository(),
       _storageService = jobPhotoStorageService ?? JobPhotoStorageService();

  final int companyId;
  final JobRepository _repository;
  final CompanyRepository _companyRepository;
  final JobPhotosRepository _photosRepository;
  final JobPhotoStorageService _storageService;
  List<Job> _jobs = <Job>[];
  final Set<int> _busyDeleteIds = {};
  final Set<int> _busyFinalizeIds = {};
  bool _isScreenLoading = false;
  bool _isCreating = false;
  bool _isEditing = false;
  String? _error;

  List<Job> get jobs => UnmodifiableListView(_jobs);
  bool isDeleting(int jobId) => _busyDeleteIds.contains(jobId);
  bool isFinalizing(int jobId) => _busyFinalizeIds.contains(jobId);
  bool get isScreenLoading => _isScreenLoading;
  bool get isCreating => _isCreating;
  bool get isEditing => _isEditing;
  String? get error => _error;

  Future<void> loadJobs() async {
    _isScreenLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _repository.getJobsByCompany(companyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isScreenLoading = false;
      notifyListeners();
    }
  }

  Future<(int? id, String? error)> createDraftJob(Job job) async {
    if (job.status != Job.draft) {
      return (null, 'El proyecto debe estar en draft.');
    }

    if (job.companyId != companyId) {
      return (null, 'CompanyId inválido.');
    }

    if (_isCreating) return (null, null);

    _isCreating = true;
    notifyListeners();

    try {
      final int insertedId = await _repository.insertDraftJob(job);
      final jobWithId = job.copyWith(id: insertedId);

      _jobs = [jobWithId, ..._jobs];

      return (insertedId, null);
    } catch (e) {
      return (null, 'Error creando proyecto.');
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<String?> updateDraftJob(Job job) async {
    if (job.id == null) {
      return 'El proyecto debe tener un id.';
    }

    if (_isEditing) return null;

    _isEditing = true;
    notifyListeners();

    try {
      await _repository.updateDraftJob(job);

      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        final updated = List<Job>.from(_jobs);
        updated[index] = job;
        _jobs = updated;
      }
      return null;
    } catch (_) {
      return 'Error editando el proyecto.';
    } finally {
      _isEditing = false;
      notifyListeners();
    }
  }

  Future<String?> deleteDraftJob({required Job job}) async {
    if (job.id == null) {
      return 'El proyecto debe tener un id.';
    }

    if (job.status != Job.draft) {
      return 'Solo se pueden eliminar proyectos en draft.';
    }

    if (_busyDeleteIds.contains(job.id)) return null;

    _busyDeleteIds.add(job.id!);
    notifyListeners();

    final index = _jobs.indexWhere((j) => j.id == job.id);
    if (index == -1) {
      _busyDeleteIds.remove(job.id!);
      notifyListeners();
      return 'Job no encontrado.';
    }

    final removedJob = _jobs[index];

    // Optimistic update
    _jobs.removeAt(index);
    notifyListeners();

    try {
      await _storageService.deleteJobFolder(job.id!);

      await _repository.deleteDraftJob(job.id!);
      return null;
    } catch (e) {
      // rollback
      _jobs.insert(index, removedJob);
      return 'Error eliminando el proyecto.';
    } finally {
      _busyDeleteIds.remove(job.id!);
      notifyListeners();
    }
  }

  Future<bool> finalizeDraftJob({required Job job}) async {
    if (job.id == null) return false;
    if (job.status != Job.draft) return false;
    if (job.companyId != companyId) return false;
    if (_busyFinalizeIds.contains(job.id)) return false;

    final company = await _companyRepository.getCompanyById(companyId);
    if (company == null) return false;

    final saldoActual = company.minutesBalance;

    _busyFinalizeIds.add(job.id!);
    notifyListeners();

    try {
      final result = calculateJobManualHours(
        saldoActual: saldoActual,
        minutosTrabajados: job.minutesWorked,
        horasACobrar: job.hoursCharged,
        valorHora: job.valuePerHour,
        valorAnexos: job.extraValue,
      );

      await _repository.finalizeJob(job, result.newBalance);

      final index = _jobs.indexWhere((item) => item.id == job.id);
      if (index == -1) return false;

      final updated = List<Job>.from(_jobs);
      updated[index] = job.copyWith(status: Job.finalized);
      _jobs = updated;

      return true;
    } catch (_) {
      return false;
    } finally {
      _busyFinalizeIds.remove(job.id!);
      notifyListeners();
    }
  }

  Future<(int? id, String? error)> createDraftJobWithPhotos({
    required Job job,
  }) async {
    if (_isCreating) return (null, null);

    _isCreating = true;
    notifyListeners();

    try {
      final insertedId = await _repository.insertDraftJob(job);
      final jobWithId = job.copyWith(id: insertedId);
      _jobs = [jobWithId, ..._jobs];

      return (insertedId, null);
    } catch (_) {
      return (null, 'Error creando proyecto.');
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<void> loadDraftPhotos(int jobId) async {
    try {
      final photosFromDb = await _photosRepository.getPhotosByJob(jobId);

      final List<DraftPhoto> loaded = [];

      for (final photo in photosFromDb) {
        final file = File(photo.path);

        if (await file.exists()) {
          loaded.add(
            DraftPhoto(
              id: photo.id, // ID REAL de la foto
              path: photo.path,
              isNew: false,
            ),
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Uint8List?> generatePdf(Job job) async {
    if (job.id == null) return null;

    final company = await _companyRepository.getCompanyById(companyId);

    if (company == null) return null;

    final photos = await _photosRepository.getPhotosByJob(job.id!);

    final existingPaths = <String>[];

    for (final photo in photos) {
      if (await File(photo.path).exists()) {
        existingPaths.add(photo.path);
      }
    }

    final pdfService = PdfService();

    return pdfService.buildJobPdf(
      company: company,
      job: job,
      photoPaths: existingPaths,
    );
  }
}
