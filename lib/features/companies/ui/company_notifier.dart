import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:mecca/features/companies/data/company_repository.dart';
import 'package:mecca/features/companies/domain/company.dart';
import 'package:mecca/features/jobs/data/job_repository.dart';
import 'package:mecca/features/jobs/storage/job_photo_storage_service.dart';

class CompanyNotifier extends ChangeNotifier {
  CompanyNotifier({
    CompanyRepository? repository,
    JobPhotoStorageService? storageService,
    JobRepository? jobRepository,
  }) : _repository = repository ?? CompanyRepository(),
       _jobRepository = jobRepository ?? JobRepository(),
       _storageService = storageService ?? JobPhotoStorageService();

  final CompanyRepository _repository;
  final JobRepository _jobRepository;
  final JobPhotoStorageService _storageService;
  List<Company> _companies = <Company>[];
  bool _isLoading = false;
  String? _error;

  List<Company> get companies => UnmodifiableListView(_companies);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCompanies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _companies = await _repository.getAllCompanies();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadCompanies();
  }

  void applyBalanceUpdate({required int companyId, required int newBalance}) {
    final index = _companies.indexWhere((item) => item.id == companyId);
    if (index == -1) {
      _error = 'Company not found for balance update.';
      notifyListeners();
      return;
    }

    final updated = List<Company>.from(_companies);
    updated[index] = updated[index].copyWith(minutesBalance: newBalance);
    _companies = updated;
    notifyListeners();
  }

  Future<void> createCompany(Company company) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final insertedId = await _repository.insertCompany(company);
      _companies = List<Company>.from(_companies)
        ..add(company.copyWith(id: insertedId));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadCompany(int companyId) async {
    final company = await _repository.getCompanyById(companyId);
    if (company == null) return;

    final index = _companies.indexWhere((c) => c.id == companyId);
    if (index == -1) return;

    final updated = List<Company>.from(_companies);
    updated[index] = company;
    _companies = updated;
    notifyListeners();
  }

  Future<void> updateCompany(Company company) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final index = _companies.indexWhere((item) => item.id == company.id);
      if (index == -1) {
        _error = 'Company not found for update.';
        notifyListeners();
        return;
      }

      await _repository.updateCompany(company);
      final updated = List<Company>.from(_companies);
      updated[index] = company;
      _companies = updated;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCompany(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final index = _companies.indexWhere((item) => item.id == id);
      if (index == -1) {
        _error = 'Company not found for delete.';
        notifyListeners();
        return;
      }

      final jobs = await _jobRepository.getJobsByCompany(id);

      for (final job in jobs) {
        if (job.id != null) {
          await _storageService.deleteJobFolder(job.id!);
        }
      }

      await _repository.deleteCompany(id);
      final updated = List<Company>.from(_companies)..removeAt(index);
      _companies = updated;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
