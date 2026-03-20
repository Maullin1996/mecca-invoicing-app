import 'package:flutter_test/flutter_test.dart';
import 'package:mecca/features/companies/data/company_repository.dart';
import 'package:mecca/features/companies/domain/company.dart';
import 'package:mecca/features/jobs/data/job_repository.dart';
import 'package:mecca/features/jobs/domain/job.dart';

import '../helpers/test_database.dart';

void main() {
  TestDatabase? testDb;
  CompanyRepository? companyRepository;
  JobRepository? jobRepository;

  setUp(() async {
    testDb = await TestDatabase.create();
    companyRepository = CompanyRepository(appDatabase: testDb!.appDatabase);
    jobRepository = JobRepository(appDatabase: testDb!.appDatabase);
  });

  tearDown(() async {
    await testDb?.raw.close();
  });

  Future<int> _insertCompany() async {
    return companyRepository!.insertCompany(
      Company(name: 'Acme', minutesBalance: 100),
    );
  }

  Job _draftJob(int companyId) {
    return Job(
      companyId: companyId,
      date: '2026-03-19',
      startTime: '08:00',
      endTime: '10:00',
      minutesWorked: 120,
      hoursCharged: 2,
      valuePerHour: 50,
      extras: const [JobExtra(description: 'Extra', value: 10)],
      totalDay: 110,
      status: Job.draft,
      service: 'Limpieza',
    );
  }

  test('insert and update draft job', () async {
    final companyId = await _insertCompany();
    final jobId = await jobRepository!.insertDraftJob(_draftJob(companyId));

    final updated = _draftJob(companyId).copyWith(
      id: jobId,
      minutesWorked: 180,
    );
    await jobRepository!.updateDraftJob(updated);

    final jobs = await jobRepository!.getJobsByCompany(companyId);
    expect(jobs, hasLength(1));
    expect(jobs.first.minutesWorked, 180);
  });

  test('finalize job updates company balance', () async {
    final companyId = await _insertCompany();
    final jobId = await jobRepository!.insertDraftJob(_draftJob(companyId));
    final job = _draftJob(companyId).copyWith(id: jobId);

    await jobRepository!.finalizeJob(job, 50);

    final jobs = await jobRepository!.getJobsByCompany(companyId);
    expect(jobs.first.status, Job.finalized);

    final company = await companyRepository!.getCompanyById(companyId);
    expect(company?.minutesBalance, 50);
  });

  test('delete draft job removes it', () async {
    final companyId = await _insertCompany();
    final jobId = await jobRepository!.insertDraftJob(_draftJob(companyId));

    await jobRepository!.deleteDraftJob(jobId);

    final jobs = await jobRepository!.getJobsByCompany(companyId);
    expect(jobs, isEmpty);
  });
}
