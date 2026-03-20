import 'package:flutter_test/flutter_test.dart';
import 'package:mecca/features/companies/data/company_repository.dart';
import 'package:mecca/features/companies/domain/company.dart';

import '../helpers/test_database.dart';

void main() {
  TestDatabase? testDb;
  CompanyRepository? repository;

  setUp(() async {
    testDb = await TestDatabase.create();
    repository = CompanyRepository(appDatabase: testDb!.appDatabase);
  });

  tearDown(() async {
    await testDb?.raw.close();
  });

  test('insert and read companies', () async {
    final company = Company(name: 'Acme', minutesBalance: 120, email: 'a@a.com');
    final id = await repository!.insertCompany(company);

    final all = await repository!.getAllCompanies();

    expect(all, hasLength(1));
    expect(all.first.id, id);
    expect(all.first.name, 'Acme');
    expect(all.first.minutesBalance, 120);
    expect(all.first.email, 'a@a.com');
  });

  test('update company', () async {
    final company = Company(name: 'Acme', minutesBalance: 120);
    final id = await repository!.insertCompany(company);

    final updated = company.copyWith(id: id, minutesBalance: 200);
    await repository!.updateCompany(updated);

    final result = await repository!.getCompanyById(id);
    expect(result?.minutesBalance, 200);
  });

  test('delete company', () async {
    final company = Company(name: 'Acme', minutesBalance: 120);
    final id = await repository!.insertCompany(company);

    await repository!.deleteCompany(id);

    final all = await repository!.getAllCompanies();
    expect(all, isEmpty);
  });
}
