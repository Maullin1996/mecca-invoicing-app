import 'package:flutter_test/flutter_test.dart';
import 'package:mecca/features/companies/domain/company.dart';
import 'package:mecca/features/jobs/domain/job.dart';
import 'package:mecca/features/jobs/domain/job_photo.dart';

void main() {
  test('Company toMap and fromMap', () {
    const company = Company(id: 1, name: 'Acme', minutesBalance: 90, email: 'a@a.com');
    final map = company.toMap();
    final parsed = Company.fromMap(map);

    expect(parsed.id, 1);
    expect(parsed.name, 'Acme');
    expect(parsed.minutesBalance, 90);
    expect(parsed.email, 'a@a.com');
  });

  test('JobExtra toMap and fromMap', () {
    const extra = JobExtra(description: 'Extra', value: 10);
    final map = extra.toMap();
    final parsed = JobExtra.fromMap(map);

    expect(parsed.description, 'Extra');
    expect(parsed.value, 10);
  });

  test('Job validates status', () {
    expect(
      () => Job(
        companyId: 1,
        date: '2026-03-19',
        startTime: '08:00',
        endTime: '10:00',
        minutesWorked: 120,
        hoursCharged: 2,
        valuePerHour: 50,
        extras: const [],
        totalDay: 100,
        status: 'invalid',
        service: 'Test',
      ),
      throwsArgumentError,
    );
  });

  test('Job toMap and fromMap preserves extras', () {
    final job = Job(
      id: 1,
      companyId: 7,
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

    final map = job.toMap();
    final parsed = Job.fromMap(map);

    expect(parsed.id, 1);
    expect(parsed.companyId, 7);
    expect(parsed.extras, hasLength(1));
    expect(parsed.extras.first.description, 'Extra');
    expect(parsed.extraValue, 10);
  });

  test('JobPhoto toMap and fromMap', () {
    final photo = JobPhoto(
      id: 2,
      jobId: 1,
      path: '/tmp/pic.jpg',
      createdAt: '2026-03-19T10:00:00Z',
    );

    final map = photo.toMap();
    final parsed = JobPhoto.fromMap(map);

    expect(parsed.id, 2);
    expect(parsed.jobId, 1);
    expect(parsed.path, '/tmp/pic.jpg');
  });
}
