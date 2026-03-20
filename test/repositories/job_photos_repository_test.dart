import 'package:flutter_test/flutter_test.dart';
import 'package:mecca/features/companies/data/company_repository.dart';
import 'package:mecca/features/companies/domain/company.dart';
import 'package:mecca/features/jobs/data/job_photos_repository.dart';
import 'package:mecca/features/jobs/data/job_repository.dart';
import 'package:mecca/features/jobs/domain/job.dart';
import 'package:mecca/features/jobs/domain/job_photo.dart';

import '../helpers/test_database.dart';

void main() {
  TestDatabase? testDb;
  JobPhotosRepository? repository;
  CompanyRepository? companyRepository;
  JobRepository? jobRepository;

  setUp(() async {
    testDb = await TestDatabase.create();
    repository = JobPhotosRepository(appDatabase: testDb!.appDatabase);
    companyRepository = CompanyRepository(appDatabase: testDb!.appDatabase);
    jobRepository = JobRepository(appDatabase: testDb!.appDatabase);
  });

  tearDown(() async {
    await testDb?.raw.close();
  });

  Future<int> _insertJob() async {
    final companyId = await companyRepository!.insertCompany(
      Company(name: 'Acme', minutesBalance: 100),
    );

    final jobId = await jobRepository!.insertDraftJob(
      Job(
        companyId: companyId,
        date: '2026-03-19',
        startTime: '08:00',
        endTime: '10:00',
        minutesWorked: 120,
        hoursCharged: 2,
        valuePerHour: 50,
        extras: const [],
        totalDay: 100,
        status: Job.draft,
        service: 'Limpieza',
      ),
    );

    return jobId;
  }

  test('insert and read photos by job', () async {
    final jobId = await _insertJob();
    final photo = JobPhoto(
      jobId: jobId,
      path: '/tmp/pic.jpg',
      createdAt: '2026-03-19T10:00:00Z',
    );

    final id = await repository!.insertPhoto(photo);
    final photos = await repository!.getPhotosByJob(jobId);

    expect(photos, hasLength(1));
    expect(photos.first.id, id);
    expect(photos.first.path, '/tmp/pic.jpg');
  });

  test('delete photo', () async {
    final jobId = await _insertJob();
    final photo = JobPhoto(
      jobId: jobId,
      path: '/tmp/pic.jpg',
      createdAt: '2026-03-19T10:00:00Z',
    );

    final id = await repository!.insertPhoto(photo);
    await repository!.deletePhotoById(id);

    final photos = await repository!.getPhotosByJob(jobId);
    expect(photos, isEmpty);
  });
}
